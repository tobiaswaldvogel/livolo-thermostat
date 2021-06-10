#ifndef GLOBAL_H
#define	GLOBAL_H


// 1 : 64
// 1 step = 1 / 4mhz * 4 * 64 = 64usec
// cap sensor mesaure 1ms
// => 16 timer for cap

#define TIMER_PRESCALER_VAL     5
#define TIMER_PRESCALER         (1 << (TIMER_PRESCALER_VAL + 1))
#define TIMER_PERIOD            _XTAL_FREQ / 4 / TIMER_PRESCALER / 100
#define TIMER_VALUE             256 - (TIMER_PERIOD)

#define INACTIVITY              100u    // 2s
#define VALVE_MAINTAIN_INTERVAL 30240000u   // 50 * 60 * 60 * 24 * 7

// PIC 16F690
//
//                    --------
//              Vdd -| 1    20|- Vss
//      BCD_A / RA5 -| 2    19|- RA0 / Digit left  / ICSPDAT
//      BCD_B / RA4 -| 3    18|- RA1 / Digit right / ICSPCLK
//        Vpp / RA3 -| 4    17|- RA2 / C1OUT
//      BCD_C / RC5 -| 5    16|- RC0 / C2IN+
//      C2OUT / RC4 -| 6    15|- RC1 / C12IN1-
//    C12IN3- / RC3 -| 7    14|- RC2 / C12IN2-
//      BCD_D / RC6 -| 8    13|- RB4 / 
//    Celcius / RC7 -| 9    12|- RB5 / Valve relais
// Fahrenheit / RB7 -|10    11|- RB6 / OneWire thermometer
//                    --------



#define VALVE_PORT          PORTB
#define VALVE_TRIS          TRISB
#define VALVE_PIN           5
#define VALVE               VALVE_PORT, VALVE_PIN
#define VALVE_C             PORTBbits.RB5
#define VALVE_OUTPUT        TRISBbits.TRISB5 = 0

#define LED_A_PORT          PORTD
#define LED_A_TRIS          TRISD
#define LED_A_PIN           3
#define LED_A_INIT          TRISDbits.TRISD3 = 0;
#define LED_B_PORT          PORTD
#define LED_B_TRIS          TRISD
#define LED_B_PIN           4
#define LED_B_INIT          TRISDbits.TRISD4 = 0;
#define LED_C_PORT          PORTD
#define LED_C_TRIS          TRISD
#define LED_C_PIN           5
#define LED_C_INIT          TRISDbits.TRISD5 = 0;

#define KEY_MINUS           PORTCbits.RC0
#define KEY_PLUS            PORTCbits.RC1
#define KEY_POWER           PORTCbits.RC2


#endif

