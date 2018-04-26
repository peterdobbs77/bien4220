/**
 * Single cycle servo motor operation
 *
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

int main(void) {
    WDTCTL = WDTPW | WDTHOLD;	// Stop watchdog timer
	
    P1DIR |= BIT0;
    P1DIR |= BIT2;  /* P1.2/TA1 used for PWN -> servo */
    P1SEL |= BIT2;  /* TA1 selected */
    P1OUT = 0;

    TACCR0 = 20000-1;                           // PWM Period TA1.1

    // setting 1500 is 1.5ms is 0deg. servo pos
    TACCR1 = 1500;                            // CCR1 PWM duty cycle

    TACCTL1 = OUTMOD_7;                       // CCR1 reset/set
    TACTL   = TASSEL_2 + MC_1;                // SMCLK, up mode

    // loop just blinks build in LEDs to show activity
    for (;;) {
        delay();
        TACCR1 = 2000;

        delay();
        TACCR1 = 1500;

        delay();
        TACCR1 = 1000;

        delay();
        TACCR1 = 1500;

        delay();
        TACCR1 = 2000;

        delay();
        TACCR1 = 2500;
    }
    return 0;
}
