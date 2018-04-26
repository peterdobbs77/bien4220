;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;   Description: Output ADC10 internal Vref on P1.4, toggling between two
;   available options, 2.5V and 1.5V. ADC10OSC also output on P1.3.
;
;                MSP430F20xx
;             ----------------
;         /|\|				  |-
;          | |                |
;          --|RST         	  |-
;            |                |
;
;   P.Dobbs
;   Marquette University
;   March 2017
;   Built with Code Composer Essentials Version: 2.0
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430f2012.h"  ; Include device header file

			.global _initialize				; export initialize as a global symbol
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            ;.retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            ;.retainrefs                     ; And retain any sections that have
                                            ; references to current section.
;*******************************************************************************
; Equates
;*******************************************************************************
finalState		.equ	00000011b
maxValidStates	.equ	00000100b

DEBUG			.equ	10000000b
BTTNMASK		.equ 	01000000b
maxTAcount      .equ    50000
;-------------------------------------------------------------------------------
State		.equ	R4		; H bridge state variable
Tick		.equ	R5		; tick event
StateTmr	.equ	R6		; time in a given state
OutputA		.equ	R7		; placeholder for output states
ButtnFlag	.equ	R8		; is the button pressed?
BtnWasOn	.equ	R9		; was the button already pressed?

RESET:
	mov.w   #0280h,SP			; Initialize stackpointer
	call	#_initialize		; Initialize port, timer interrupt, LED states, GIE
	jmp		loop

;*******************************************************************************
; Initialize
;*******************************************************************************
_initialize:
			mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer
SetupP1:    bis.b   #00111111b,&P1DIR       ; P1.0 - P1.5 as output
SetupP2:	bic.b	#DEBUG,&P2SEL
			bis.b 	#DEBUG,&P2OUT
SetupC0:    mov.w   #CCIE,&CCTL0            ; CCR0 interrupt enabled
            mov.w   #maxTAcount,&CCR0       ;
SetupTA:    mov.w   #TASSEL_2+MC_2,&TACTL   ; SMCLK, continuous
SetupOut:	clr.w	OutputA					;
			mov.w	OutputA,&P1OUT			;
SetupCount:	clr.w 	State					;
			clr.w	Tick					;
			clr.w	StateTmr				;
			clr.w 	ButtnFlag				; clear Button pressed flag
			clr.w	BtnWasOn				;
SetupState:	mov.b	#Timer_Table,StateTmr	;
			mov.b	#State_Table,OutputA	;

SetupGIE:	bis.w   #GIE, SR                ; interrupts enabled
			ret

;-------------------------------------------------------------------------------
; main loop -
;-------------------------------------------------------------------------------
loop:
	mov.b	OutputA, &P1OUT			; write states to port
	cmp.b	#0, Tick				;
	jne		do_fsm					; if Tick not eq. 0, then process tick in state_machine
    nop								; if not, goto loop
	bit		#BTTNMASK, &P2IN 		; test for button press
	jnz		do_button				; jump to button handling

	jmp		endmain					; end

do_fsm:
	bis		#DEBUG, &P2OUT			; Set DEBUG pin high to see how much time we are
									; spending in Tick handler
	dec		Tick					; remove the event from the flag byte
	cmp.b	#001h, ButtnFlag		; has the button been pressed recently?
	jeq		do_button
	jmp		normal_operation		; if not, branch to normal _operation handler

do_button:
	mov.b	#0x01, ButtnFlag		; signal a button press
	xor.b   #0x01, BtnWasOn			; signal that the button has been on
	jmp		endtick					; exit the Tick handler

normal_operation:
	dec		StateTmr				;
	cmp.b	#001h, ButtnFlag		; has the button been pressed recently?
	jz		next_state				; if StateTmr expired, goto next state
	jmp		endtick					;    or else exit the Tick handler

prev_state:
	dec		State					;
	cmp		State,#0				;
	jl		skip_state_reset		;
	mov.b	#finalState, State		;

next_state:
	inc		State					; Go on to next state but limit it to the max number of valid stated					; Has the max number of states been reached?
	cmp		#maxValidStates, State	;   if not, skip ahead,
	jl		skip_state_reset		;   otherwise,
	clr.w	State					;   go back to the initial state (state 0).

skip_state_reset:
	mov.b	Timer_Table(State),StateTmr	; load new timer value into StateTmr
	mov.b	State_Table(State),OutputA	; load new Led value into LedStates

endtick:
	bic		#DEBUG, &P2OUT			; Set DEBUG pin low

endmain:
	jmp		loop

;*******************************************************************************
TA0_ISR: ;    increment tick value (R5)
;*******************************************************************************
	inc	Tick						;
	reti

Timer_Table:
sAtime	.byte	0x3F
;sABtime	.byte	0x3F
sBtime	.byte	0x3F
;sBCtime	.byte	0x3F
sCtime	.byte	0x3F
;sCDtime	.byte	0x3F
sDtime	.byte	0x3F
;sDAtime	.byte	0x3F

State_Table:
; 00(3,4EN)(1,2EN)(1in)(4in)(3in)(2in)
sA		.byte	00110011b
;sAB		.byte	00100010b
sB		.byte	00111010b
;sBC		.byte	00011000b
sC		.byte	00111100b
;sCD		.byte	00100100b
sD		.byte	00110101b
;sDA		.byte	00010001b
;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            .sect   ".int09"				; MSP430 TimerA0 Vector
			.short  TA0_ISR
            .end
