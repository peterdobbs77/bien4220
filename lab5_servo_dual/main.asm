;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

SetupClk	mov.w	#DCO2+DCO1+DCO0,&DCOCTL
			mov.w	#XT2OFF+RSEL3+RSEL2+RSEL1+RSEL0,&BCSCTL1
			mov.w	#DIV_3,&BCSCTL2			;causes inability to compile

SetupP1		bis.b	#006h,&P1SEL			;P1.1 and P1.2 option select
			bis.b	#001h,&P1OUT
			bis.b	#007h,&P1DIR

SetupTA2	mov.w	#OUTMOD_0,&CCTL0		;OUTPUT mode, interrupts NOT enabled
			mov.w	#OUTMOD_0,&CCTL1		;OUTPUT mode, interrupts NOT enabled
			bis.w	#004h,&TACCTL0			;
			bis.w	#004h,&TACCTL1			;
			mov.w	#OUTMOD_5,&CCTL0		;RESET mode
			mov.w	#OUTMOD_5,&CCTL1		;RESET mode
			mov.w	#TASSEL_2+MC_2+TAIE,&TACTL

SetupPWM	mov.w	#00FFFh,&TACCR0			;TA0 duty cycle
			mov.w	#00100h,&TACCR1			;TA1 duty cycle

;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
Mainloop	bis.w	#LPM1+GIE,SR			;enter LPM1, interrupts enabled!
            nop								;required for debugging

;----------------------------------------------------------------
TAX_ISR;	Common ISR for CCR1-4 and overflow
;------------------------------------------------------------
			add.w	&TAIV,PC				;add Timer_A offset vector
			reti						;CCR0 - no source
			reti						;CCR1
			reti						;CCR2
			reti						;CCR3
			reti						;CCR4

TAoverISR	xor.b	#001h,&P1OUT		;toggle LED
			mov.w	#OUTMOD_0,&CCTL0
			mov.w	#OUTMOD_0,&CCTL0
			bis.w	#004h,&TACCTL0
			bis.w	#004h,&TACCTL1
			mov.w	#OUTMOD_5,&CCTL0
			mov.w	#OUTMOD_5,&CCTL1
			reti			;Return ISR
;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET					;
            .sect	".int08"				; Timer_AX Vector
            .short	TAX_ISR					;
            .end
