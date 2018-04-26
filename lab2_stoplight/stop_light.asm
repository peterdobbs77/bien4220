;*******************************************************************************
; stop_light.asm
; 
; A stoplight state machine coordinating two stoplights at an intersection.
;   There is also a pushbutton input that signals an error event to force the
;   state machine into an alternate (blinking red) condition. The state machine
;   receives TimerTicks from the on-chip Timer A which is serviced by an interrupt 
;	service routine. The state machine also receives "button press" events 
;	initiating an exception condition that times out after a set amount of time.
;
;   10/04/2001 RA Scheidt - Initial logic for 68HC912B32 EVB, E = 8 MHz
;	02/07/2011 EA Bock - port code to MSP430
;   02/09/2011 DJ Herzfeld - Interrupt modifications
;   01/12/2012 RA Scheidt - Comment clarifications; Code streamlining
;	02/16/2017 PN Dobbs - Added state machine for handling button pressed & hold operation

	.cdecls C,LIST,  "msp430f2013.h"
	
    .global _initialize            ; export initialize as a global symbol
	.global _TimerA0_isr           ;
				.def	RESET
                .text
;*******************************************************************************
; Equates
;*******************************************************************************
stateRG			.equ	00000000b	; entry state
stateRY			.equ	00000001b
stateRR1		.equ	00000010b
stateGR			.equ	00000011b
stateYR			.equ	00000100b
stateRR2		.equ	00000101b	; goto stateRG from here
maxValidStates	.equ	00000110b	;

stateErrRR		.equ	00000000b	;
stateErrOO		.equ	00000001b	; goto stateErrRR from here
maxErrStates	.equ	00000010b	;
ErrorDuration	.equ	0xE6		; fifteen seconds of blinky upon error
			;
ALL_LEDS		.equ	01111111b		; all leds on
NO_LEDS			.equ	00000000b		; all leds off

DEBUG			.equ	01000000b
BUZZER			.equ	01000000b
BTTNMASK		.equ 	10000000b

maxTAcount      .equ    50000

;*******************************************************************************
; assign variables to hardware multipurpose REGISTERs
;******************************************************************************* 
State		.equ	R4		; stop light state variable
Tick		.equ	R5		; tick event
StateTmr	.equ	R6		; time in a given state
LedStates	.equ	R7		; placeholder for LED states
ButtnFlag	.equ	R8		; is the button pressed?
ErrTimer	.equ	R9		; are we in an error condition?
BtnWasOn	.equ	R10		; was the button already pressed?

RESET:
	mov.w   #0280h,SP               ; Initialize stackpointer
	call	#_initialize			; Initialize port, timer interrupt, LED states, GIE
	jmp		loop

;*******************************************************************************
; Initialize
;*******************************************************************************
_initialize:
	    	mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
SetupP1:    bis.b   #01111111b,&P1DIR       ; P1.0-P1.6 as outputs; P1.7 (Button) as input
SetupP2:	bic.b	#DEBUG,&P2SEL
			bis.b 	#DEBUG,&P2OUT
SetupC0:    mov.w   #CCIE,&CCTL0            ; CCR0 interrupt enabled
            mov.w   #maxTAcount,&CCR0       ;
SetupTA:    mov.w   #TASSEL_2+MC_1,&TACTL   ; SMCLK, upmode
SetupLEDS:	clr.b	LedStates				; default LedStates all off
			mov.b	LedStates,&P1OUT		;
SetupCount:	clr.w	State					; clear State counter; set default state to stateRG
			clr.w 	Tick					; clear Tick counter
			clr.w	StateTmr				; clear State timer
			clr.w 	ButtnFlag				; clear Button pressed flag
			clr.w 	ErrTimer				; start off in a non-error condition
			clr.w	BtnWasOn				; clear Button Was On flag
SetupState:	mov.b	#Timer_Table, StateTmr	; load default state timer value
			mov.b	#Led_Table, LedStates	; load default LED values

SetupGIE:	bis.w   #GIE, SR                ; interrupts enabled
			ret

;*******************************************************************************
; main loop - the main loop performs the background task. The background task 
;             manages the statemachine and polls the push button.
;*******************************************************************************
loop:
	mov.b	LedStates, &P1OUT		; write LED states to port
    cmp.b	#0,Tick					;
    jne		do_fsm					; if Tick not eq. 0, then process tick in state_machine
    nop								; if not, goto loop
    bit		#BTTNMASK, &P1IN 		; test for button press
    jnz		do_button				; jump to button handling
	bic		#BUZZER, &P1OUT			; no beep
    jmp		endmain					; goto the end of the background task loop if no tick.
    
do_fsm:								; a tick has occurred 
	bis		#DEBUG, &P2OUT			; Set DEBUG pin high to see how much time we are 
									;    spending in Tick handler
	dec		Tick					; remove the event from the flag byte
	cmp.b	#001h, ButtnFlag		; has the button been pressed recently?
	jeq		error_operation			; if so, branch to error condition handler
	jmp		normal_operation		; if not, branch to normal _operation handler

do_button:
	mov.b	#0x01, ButtnFlag		; signal a button press
	cmp.b 	#001h, BtnWasOn			; check if the button has been on
	jeq		peterlabel
	bis		#BUZZER, &P1OUT			; beep
	mov.b	#ErrorDuration, ErrTimer ; reset error timer
	mov.b	#001h, StateTmr			; truncate current state on button press
peterlabel:
	mov.b	#0x01, BtnWasOn			; signal that the button has been on
	jmp		endtick					; exit the Tick handler

error_operation:
	dec		ErrTimer				; has the error condition timered out?
	jz		exit_err_state			;	if so, restore default conditions to state machine
	dec		StateTmr				;   if not, stay in error state
	jz		next_err_state			; if current StateTmr expired, goto next state
	jmp		endtick					;   or else exit Tick handler
next_err_state:
	inc		State					; go on to next state but limit it to the max number of valid stated
	cmp.b	#maxErrStates, State	;  has the max number of states been reached?				;
	jl		skip_err_state_reset	; 
	clr.w	State				
skip_err_state_reset:
	mov.b	Err_Timer_Table(State), StateTmr	; load new timer value into StateTmr
	mov.b	Err_Led_Table(State), LedStates	; load new Led value into LedStates
end_next_err_state:
	jmp		endtick					; or else exit Tick handler
exit_err_state:
	bic.b	#0x01, ButtnFlag		; clear button press signal
	bic.b	#0x01, BtnWasOn			; clear button was on signal
	mov.b	Timer_Table, StateTmr	; load default state timer value into StateTmr
	mov.b	Led_Table, LedStates	; load default LED values
	clr.w	State					; clear State counter; set default state to stateRG
	jmp		endtick					; exit the Tick handler
	
normal_operation:
	dec		StateTmr				;
	jz		next_state				; if StateTmr expired, goto next state
	jmp		endtick					;    or else exit the Tick handler
next_state:
	inc		State					; Go on to next state but limit it to the max number of valid stated					; Has the max number of states been reached?
	cmp		#maxValidStates, State	;   if not, skip ahead,
	jl		skip_state_reset		;   otherwise,
	clr.w	State					;   go back to the initial state (state 0).
skip_state_reset:
	mov.b	Timer_Table(State), StateTmr	; load new timer value into StateTmr
	mov.b	Led_Table(State), LedStates	; load new Led value into LedStates
end_next_state:
	jmp		endtick					; exit the Tick handler

endtick:
	bic		#DEBUG, &P2OUT			; Set DEBUG pin low
endmain:
	jmp		loop					; go back to the top of the background task


;*******************************************************************************
TA0_ISR: ;    increment tick value (R5)
;*******************************************************************************
	inc	Tick						; 
	reti

;*******************************************************************************
; Constants - Tables of values used by state machine. 
;*******************************************************************************
Timer_Table:
sRGtime		.byte	0x99			; 153 ticks, about 10 seconds
sRYtime		.byte	0x1F			; 31 ticks, about 2 seconds
sRR1time	.byte	0x0F			; 15 ticks, about 1 second
sGRtime		.byte	0x99			; 10 seconds
sYRtime		.byte	0x1F			; 2 seconds
sRR2time	.byte	0x0F			; 1 second

Err_Timer_Table:
sERR		.byte	0x07			; about 1/2 second
sEOO		.byte	0x07			; about 1/2 second

Led_Table:
sRGleds		.byte	00100001b	; Left R & Right G
sRYleds		.byte	00100010b	; Left R & Right Y
sRR1leds	.byte	00100100b	; Left R & Right R
sGRleds		.byte	00001100b	; Left G & Right R
sYRleds		.byte	00010100b	; Left Y & Right R
sRR2leds	.byte	00100100b	; Left R & Right R

Err_Led_Table:
sERRleds	.byte	00100100b	; Left R & Right R
sEOOleds	.byte	00000000b	; Left Off & Right Off

;*******************************************************************************
; Interrupt Vectors
;*******************************************************************************
			.sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET                   ;
			.sect   ".int09"				; MSP430 TimerA0 Vector
			.short  TA0_ISR
			.end
			

