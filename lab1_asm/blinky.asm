;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.

MaxCount    .set    500000                  ; Define a Maximum Loop Count Value

;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

Main          mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
              bis.b   #001h,&P1OUT            ; P1.0 = 1 / LED ON
              bis.b   #BIT0,&P1DIR            ; P1.0 as output
ToggleLED     xor.b   #BIT0, P1OUT            ; Toggle LED
DelayLoop     mov.w   #MaxCount, R4           ; load a value into temporary storage
Decrement     dec     R4                      ; decrement the value in temp storage
              jnz     Decrement               ; is the resulting value zero?
              jmp     ToggleLED               ; if it was toggle the LED

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
            
