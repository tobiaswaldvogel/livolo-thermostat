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
    
#define DISP_A              PORTA, 5
#define DISP_B              PORTA, 4
#define DISP_C              PORTC, 5
#define DISP_D              PORTC, 6
#define DISP_LEFT           PORTA, 0
#define DISP_RIGHT          PORTA, 1
#define VALVE               PORTB, 5
#define LED_CELSIUS         PORTC, 7
#define LED_FAHRENHEIT      PORTB, 7
#define LED_POWER	    PORTC, 0

#define _XTAL_FREQ 4000000

TIMER0_RELOAD		    equ	128	; Counter for cap sensor oscillator
ADC_TIMER_RELOAD	    equ	55	; ADC measure frequency for light sensor ( in 20ms units)

FLASH_PER_SEC		    equ 1	; Flashes per second in setup mode
INACTITIVY_TIMER	    equ 50 * 2	; Display time for target temperature (in 20ms units) = 2s
KEEP_DISPLAY_ON_TIMER	    equ 50 * 10	; Delay after a touch event before the display can be switched off again
VALVE_MAINTENANCE	    equ 50 * 60 * 60 * 24 * 7	    ; 20ms units = 7 days
VALVE_MAINTENANCE_OPEN	    equ	50 * 60 * 5		    ; 20ms units = 5 minutes
	    
CELSIUS_MIN		    equ (5 << 1)
CELSIUS_DEFAULT		    equ (23 << 1)
CELSIUS_MAX		    equ (40 << 1)
FAHRENHEIT_MIN		    equ 41
FAHRENHEIT_DEFAULT	    equ 73
FAHRENHEIT_MAX		    equ	99

; Temperture in stand-by mode
STANDBY_TARGET_TEMPERATURE_CELSIUS  equ	(5 << 1)
	  
VALVE_DELAY_DEFAULT	    equ	3	; Default delay for open / close valve in 10s units
MIN_TOUCH		    equ	4	; Minimum touch time
LONG_TOUCH		    equ	50	; Long touch time (in 20ms units) 1 sec

; Timer 0 pre-scaler    
TMR0_PS_1_2		    equ	0
TMR0_PS_1_4		    equ	1
TMR0_PS_1_8		    equ	2
TMR0_PS_1_16		    equ	3
TMR0_PS_1_32		    equ	4
TMR0_PS_1_64		    equ	5    
TMR0_PS_1_128		    equ	6    
TMR0_PS_1_256		    equ	7    

; Error codes		    
ERROR_THERMOMETER_NOT_PRESENT	    equ 1
ERROR_RB6_LOW			    equ 2
ERROR_THERMOMETER_NOT_PRESENT_RB6   equ 3
    
global  isr_w, isr_status, isr_fsr
global	arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7 
global	signal_touch, signal_timer		
global	flags1, flags2, setup_mode
		
global	disp_l, disp_r
global  timer50hz
global	var_timer_thermometer, var_timer_adc, var_timer_inactivity
global  var_timer_valve, var_timer_valve_maint, var_timer_keep_displ_on
		
global	target_temperature, valve_delay, temperature_offset
global	current_temperature, light_sensor_limit, light_sensor_value

; EEPROM locations   
global  EE_TARGET_TEMPERATURE, EE_TEMPERATURE_OFFSET
global  EE_VALVE_DELAY, EE_FAHRENHEIT, EE_LIGHT_SENSOR
			

; Signals and flags
#define SIGNAL_TOUCH_MINUS_SHORT	signal_touch, 0
#define SIGNAL_TOUCH_POWER_SHORT	signal_touch, 1
#define	SIGNAL_TOUCH_PLUS_SHORT		signal_touch, 2
#define SIGNAL_TOUCH_MINUS_LONG		signal_touch, 4
#define SIGNAL_TOUCH_POWER_LONG		signal_touch, 5
#define SIGNAL_TOUCH_PLUS_LONG		signal_touch, 6
	      
#define SIGNAL_TIMER_INACTIVITY		signal_timer, 0
#define SIGNAL_TIMER_THERMOMETER	signal_timer, 1
#define SIGNAL_TIMER_VALVE		signal_timer, 2
#define SIGNAL_TIMER_ADC		signal_timer, 3
#define	SIGNAL_TIMER_VALVE_MAINTAIN	signal_timer, 4
#define SIGNAL_TIMER_KEEP_DISPLAY_ON    signal_timer, 5   
  
#define FLAG_TMR2_INT_EVEN	    flags1, 0
#define FLAG_FAHRENHEIT		    flags1, 1
#define FLAG_VALVE_STATUS	    flags1, 2
#define FLAG_TEMPERATURE_CHANGED    flags1, 3
#define FLAG_VALVE_IMMEDIATE	    flags1, 4
#define FLAG_ONEWIRE_RB6	    flags1, 5
#define FLAG_ONEWIRE_SELF_POWERED   flags1, 6

#define FLAG_DISPLAY_ENABLE	    flags2, 0
#define FLAG_STANDBY		    flags2, 1
#define FLAG_DISPLAY_OFF	    flags2, 2
#define	FLAG_NIGHT_MODE		    flags2, 3   
#define	FLAG_KEEP_DISPLAY_ON	    flags2, 4
