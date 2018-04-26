/**
 * Dual cycle servo motor operation
 *
 */

#include <msp430.h> 

void delay(){
    P1OUT ^= BIT0;

    volatile unsigned long i;
    i = 49999;
    do (i--);
    while (i != 0);
}


/*
 * main.c
 */
int main(void) {
    WDTCTL = WDTPW | WDTHOLD;   // Stop watchdog timer

    //SetupClk
    DCOCTL = DCO2+DCO1+DCO0;    //choose max speed for DCO
    BCSCTL1 = XT2OFF+RSEL3+RSEL2+RSEL1+RSEL0;
    BCSCTL2 = DIVS_3; //source SMCLK from DCO, div by 8

    //SetupP1
    P1DIR |= BIT0;
    P1DIR |= BIT1;  /* P1.1/TA0 used for PWN -> servo1 */
    P1SEL |= BIT1;  /* TA0 selected */
    P1DIR |= BIT2;  /* P1.2/TA1 used for PWN -> servo2 */
    P1SEL |= BIT2;  /* TA1 selected */
    P1OUT = 0;

    //SetupTA2
    CCTL0 = OUTMOD_0;   //OUTPUT mode, interrupt NOT enabled
    CCTL1 = OUTMOD_0;   //OUTPUT mode, interrupt NOT enabled
    TACCTL0 = 4;        //Manually set the TA0 output pin
    TACCTL1 = 4;        //Manually set the TA1 output pin
    CCTL0 = OUTMOD_5;   //RESET mode
    CCTL1 = OUTMOD_5;   //RESET mode
    TACTL   = TASSEL_2 + MC_2 + TAIE;   // SMCLK, continuous mode, TAOF interrupt

    //SetupPWM
    TACCR0 = 20000-1;   // TA0 duty cycle
    TACCR1 = 1500;      // TA1 duty cycle



    // loop just blinks build in LEDs to show activity
    for (;;)
    {
        delay();
        TA0CCR1 = 1000;
        TA1CCR1 = 2000;

        delay();
        TA0CCR1 = 1500;
        TA1CCR1 = 1500;

        delay();
        TA0CCR1 = 2000;
        TA1CCR1 = 1000;

        delay();
        TA0CCR1 = 1500;
        TA1CCR1 = 1500;
    }
    return 0;
}

#pragma device_c::isr(void){

}
