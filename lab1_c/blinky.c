//******************************************************************************
//  MSP430F20xx Demo - Software Toggle P1.0
//
//  Description; Toggle P1.0 by xor'ing P1.0 inside of a software loop.
//  ACLK = n/a, MCLK = SMCLK = default DCO
//
//                MSP430F20xx
//             -----------------
//         /|\|              XIN|-
//          | |                 |
//          --|RST          XOUT|-
//            |                 |
//            |             P1.0|-->LED
//
//  M.Buccini / L. Westlund
//  Texas Instruments, Inc
//  October 2005
//  Built with CCE Version: 3.2.0 and IAR Embedded Workbench Version: 3.40A
//
// Modified:
// 2015.01.12: R. Scheidt PhD; Added more comments
// 2014.01.16: R. Scheidt PhD; Added comments
//
//******************************************************************************

#include  <msp430f2013.h>

void main(void)
{
  volatile unsigned int i;					// i is the loop counter. We declare
											// it is volatile to trick the compiler 
											// into not optimizing the empty loop
											// away. A volatile variable is one that
											// can change due to hardware action, so 
											// compiler optimizations should leave
											// it alone.

  WDTCTL = WDTPW + WDTHOLD;                 // Stop hardware watchdog timer
  P1DIR |= 0x01;                            // Set GPIO P1.0 to "output" direction

// Enter an infinite loop.  Generally speaking, all microcontroller projects 
// should have a "main" method that takes the form of an infinite loop
	
  for (;;)
  {

    P1OUT ^= 0x01;                          // Toggle P1.0 using exclusive-OR
    										// To "toggle" means to change the
    										// state from "on" to "off or from 
    										// "off" to "on".

    i = 20000;                              // Load the Loop Counter
    do (i--);								// Decrement the loop counter...
    while (i != 0);							// ...until it equals zero...
  }											// whereupon you go back and toggle P1.0
}
