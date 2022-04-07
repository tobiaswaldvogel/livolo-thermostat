; PIC 16F690
;                                --------
;                          Vdd -| 1    20|- Vss
;                  BCD_A / RA5 -| 2    19|- RA0 / Digit left  / ICSPDAT
;                  BCD_B / RA4 -| 3    18|- RA1 / Digit right / ICSPCLK
;                    Vpp / RA3 -| 4    17|- RA2 / T0CKI (connected to C2OUT)
;                  BCD_C / RC5 -| 5    16|- RC0 / Power LED
;                  C2OUT / RC4 -| 6    15|- RC1 / C12IN1-    + sensor
; Power sensor   C12IN3- / RC3 -| 7    14|- RC2 / C12IN2-    - sensor
;                  BCD_D / RC6 -| 8    13|- RB4 / External thermometer / Light sensor (mod)
;                Celsius / RC7 -| 9    12|- RB5 / Valve relais
;             Fahrenheit / RB7 -|10    11|- RB6 / Internal thermometer / External thermometer (mod)
;                                --------    
;                 
;	    Comparator setup as relaxation oscillator for cap sensor
;                 
;			
;                     CVref   |\ C1      --------
;             ----   C1Vref --|+\       |        |
;  C12IN1- --|    |           |  |------| S    Q |
;  C12IN2- --|C1CH|-----------|-/ (inv) |        |
;  C12IN3- --|    |           |/        |        |
;             ----                      |        |
;                     0.6V    |\ C2     |        |
;             ----   C2Vref --|+\       |      _ |  C2OUT  T0CKI  ---------
;  C12IN1- --|    |           |  |------| R    Q |---------------| Timer 0 |
;  C12IN2- --|C2CH|-----------|-/       |        |        |       ---------
;  C12IN3- --|    |           |/         --------         |
;             ----                                        |
;                                                         |
;                                                         |
;       Vss -----||------- C12IN1- ---/\/\----------------|		       
;                                                         |
;       Vss -----||------- C12I21- ---/\/\----------------|		       
;                                                         |
;       Vss -----||------- C12I31- ---/\/\----------------		       
;
    
#define PIN_DISP_A          PORTA, 5
#define PIN_DISP_B          PORTA, 4
#define PIN_DISP_C          PORTC, 5
#define PIN_DISP_D          PORTC, 6
#define PIN_DISP_LEFT       PORTA, 0
#define PIN_DISP_RIGHT      PORTA, 1
#define PIN_RELAY           PORTB, 5
#define PIN_LED_CELSIUS     PORTC, 7
#define PIN_LED_FAHRENHEIT  PORTB, 7
#define PIN_LED_POWER	    PORTC, 0

#define _XTAL_FREQ	    8000000

TIMER0_RELOAD		    equ	128	; Counter for cap sensor oscillator
ADC_TIMER_RELOAD	    equ	18	; ADC measure frequency for light sensor ( in 16ms units)
ADC_SETTLE		    equ 5

MEASURE_FREQUENCY	    equ 4	; Temperature measuring intervall (in s)
TARGET_TEMPERATURE_TIMER    equ 4	; Display time for target temperature (in s)
KEEP_DISPLAY_ON		    equ 10	; Delay after a touch event before the display can be switched off again
VALVE_MAINTENANCE_OPEN	    equ	60 * 5	; 5 minutes (unit seconds)
TOUCH_REPEAT		    equ 6	; Repeat time for touch events 96ms (in 16ms units)
	    
CELSIUS_MIN		    equ (5 << 1)
CELSIUS_DEFAULT		    equ (23 << 1)
CELSIUS_MAX		    equ (40 << 1)
FAHRENHEIT_MIN		    equ 41
FAHRENHEIT_DEFAULT	    equ 73
FAHRENHEIT_MAX		    equ	99

RELAY_DELAY_MAX		    equ	99	; Unit 10sec = 16m:30
VALVE_MAINTAIN_MAX	    equ	99	; Unit days
LIGHT_SENSOR_MAX	    equ	99
	    
OPERATION_MODE_COOLING	    equ 55h	; EEPROM value 
OPERATION_MODE_MAX	    equ	1

BRIGHTNESS_MIN		    equ 2
BRIGHTNESS_MAX		    equ 50
BRIGHTNESS_NIGHT_MIN	    equ 0
BRIGHTNESS_NIGHT_MAX	    equ 50
		    
; Temperture in stand-by mode
STANDBY_TARGET_TEMPERATURE_CELSIUS  equ	(5 << 1)    ; 5 Grad C
	  
RELAY_DELAY_DEFAULT	    equ	3	; Default delay for open / close valve in 10s units
MIN_TOUCH		    equ	5	; Minimum touch time 80ms (in 16ms units)
LONG_TOUCH		    equ	62	; Long touch time 960ms (in 16ms units)

; Timer 0 pre-scaler    
TMR0_PS_1_2		    equ	0
TMR0_PS_1_4		    equ	1
TMR0_PS_1_8		    equ	2
TMR0_PS_1_16		    equ	3
TMR0_PS_1_32		    equ	4
TMR0_PS_1_64		    equ	5    
TMR0_PS_1_128		    equ	6    
TMR0_PS_1_256		    equ	7    

TIMER2_PERIOD		    equ 200	; Timer 2 is running at 40us => 8ms
		    
; Error codes		    
ERROR_THERMOMETER_NOT_PRESENT	    equ 1
ERROR_RB6_LOW			    equ 2
ERROR_THERMOMETER_NOT_PRESENT_RB6   equ 3
    
global  isr_w, isr_status, isr_fsr
global	arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7 
global	signal_touch, signal_release, signal_timer		
global	flags1, flags2, setup_mode
		
global	display_bcd, disp_leds, disp_brightness
global  var_timer_125hz
global	var_timer_thermometer, var_timer_adc, var_timer_target_temp
global  var_timer_relay, var_timer_valve_maint, var_timer_night_disable
global	timer_valve_maint_mult, var_timer_valve_maint_set
global  var_timer_touch_repeat
   
global  brightness, brightness_night
global	target_temperature, relay_delay, temperature_offset
global	current_temperature, light_sensor_limit, light_sensor_value, light_sensor_counter
global	valve_maintain_days, operation_mode

; EEPROM locations   
global  EE_TARGET_TEMPERATURE, EE_TEMPERATURE_OFFSET
global  EE_RELAY_DELAY, EE_FAHRENHEIT, EE_LIGHT_SENSOR
global  EE_VALVE_MAINTAIN, EE_OPERATION_MODE
global  EE_BRIGHTNESS, EE_BRIGHTNESS_NIGHT

; Signals and flags
; Sensor signals
#define SIGNAL_TOUCH_MINUS_SHORT	signal_touch, 0
#define SIGNAL_TOUCH_POWER_SHORT	signal_touch, 1
#define	SIGNAL_TOUCH_PLUS_SHORT		signal_touch, 2
#define SIGNAL_TOUCH_MINUS_LONG		signal_touch, 4
#define SIGNAL_TOUCH_POWER_LONG		signal_touch, 5
#define SIGNAL_TOUCH_PLUS_LONG		signal_touch, 6

#define SIGNAL_RELEASE_MINUS		signal_release, 0
#define SIGNAL_RELEASE_POWER		signal_release, 1
#define	SIGNAL_RELEASE_PLUS		signal_release, 2
   
; Timer signals   
#define SIGNAL_TIMER_1HZ		signal_timer, 0
#define SIGNAL_TIMER_TARGET_TEMPERATURE	signal_timer, 1
#define SIGNAL_TIMER_THERMOMETER	signal_timer, 2
#define SIGNAL_TIMER_VALVE		signal_timer, 3
#define SIGNAL_TIMER_ADC		signal_timer, 4
#define	SIGNAL_TIMER_VALVE_MAINTAIN	signal_timer, 5
#define SIGNAL_TIMER_NIGHT_DISABLE      signal_timer, 6   
#define SIGNAL_TIMER_TOUCH_REPEAT       signal_timer, 7
   
#define FLAG_TMR2_INT_EVEN		flags1, 0
#define FLAG_TMR2_DIM			flags1, 1
#define FLAG_FAHRENHEIT			flags1, 2
#define FLAG_TEMPERATURE_CHANGED	flags1, 3
#define FLAG_RELAY_IMMEDIATE		flags1, 4
#define FLAG_ONEWIRE_SELF_POWERED	flags1, 6
#define	FLAG_HAS_LIGHT_SENSOR		flags1, 7

; Display / Stand-by flags   
#define FLAG_STANDBY			flags2, 0
#define	FLAG_NIGHT_MODE			flags2, 1   
#define	FLAG_NIGHT_MODE_AUTOMATIC	flags2, 2
#define	FLAG_KEEP_DISPLAY_ON		flags2, 3
#define	FLAG_DISPLAY_DIM		flags2, 7
   
#define LED_CELSIUS			disp_leds, 0
#define LED_FAHRENHEIT			disp_leds, 1
#define LED_POWER_ON			disp_leds, 2
#define LED_POWER_RED			disp_leds, 3