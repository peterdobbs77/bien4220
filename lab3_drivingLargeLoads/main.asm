;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
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
DEBUG			.equ	10000000b
BTTNMASK		.equ 	01000000b
DRIVELOAD		.equ	00000010b

;-------------------------------------------------------------------------------
ButtnFlag	.equ	R4		; is the button pressed?

RESET:
	mov.w   #0280h,SP			; Initialize stackpointer
	call	#_initialize		; Initialize port, timer interrupt, LED states, GIE
	jmp		loop

;*******************************************************************************
; Initialize
;*******************************************************************************
_initialize:
			mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer
SetupP1:    bis.b   #BIT1,&P1DIR       		; P1.1 as output
SetupP2:	bic.b 	#BIT6,&P2DIR			; P2.6 (button) as input
			bic.b   #BIT6,&P2SEL			;
			bis.b   #BIT6,&P2REN
			clr.w 	ButtnFlag				; clear Button pressed flag
			ret

;-------------------------------------------------------------------------------
; main loop -
;-------------------------------------------------------------------------------
loop:
	bit		#BTTNMASK, &P2IN 		; test for button press
	jnz		do_button				; jump to button handling
	jmp		no_button

do_button:
	mov.b	#0x01, ButtnFlag		; signal a button press
	bis.b	#DRIVELOAD,&P1OUT		; set output high
	jmp		endmain

no_button:
	bic		#DRIVELOAD,&P1OUT		; set ouput low
	bic.b	#0x01, ButtnFlag		; clear button press flag

endmain:
	jmp		loop
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
            .end
