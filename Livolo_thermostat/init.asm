#include <xc.inc>
#include "global.inc"    

; Uses
global	read_eeprom, write_eeprom
global  one_wire_set_port, one_wire_set_pin, one_wire_reset
global	main, failure
global  chk_target_temp_range, chk_offset_range
global  chk_brightness_range, chk_brightness_night_range
global	valve_maint_calc			

config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
config BOREN = OFF      // Brown-out Reset Enable bit (BOR disabled)
config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
config FOSC = INTRCIO   // Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA4/OSC2/CLKOUT pin, I/O function on RA5/OSC1/CLKIN)
config MCLRE = OFF      // MCLR Pin is ditial input
config IESO = OFF       // Internal External Switchover mode disabled
config FCMEN = OFF      // Fail-Safe Clock disabled

psect	reset_vector,abs,class=CODE,space=SPACE_CODE,delta=2		
			org	0
			goto    init
    
psect code

init:			clrf	STATUS		; select bank 0
			; bank 0 variables
			movlw	20h
			movwf	FSR
init_clear_bank0:	clrf	INDF
			incf	FSR, f
			btfss	FSR, 7		; Loop until bit 7 = 1 => 80h
			goto	init_clear_bank0

			; bank 1 variables
			movlw	0A0h
			movwf	FSR
init_clear_bank1:	clrf	INDF
			incf	FSR, f
			btfss	FSR, 6		; Loop until bit 6 = 1 => C0h
			goto	init_clear_bank1
			
			; Start display blank
			movlw	0ffh
			movwf	display_bcd

			movlw	50			; Set light sensor initial
			movwf	light_sensor_value	;  value to 50
			
			; Setup PINs
			bsf	RP0		; bank 1

;                                --------
;                          Vdd -| 1    20|- Vss
;                  BCD_A / RA5 -| 2    19|- RA0 / Digit left  / ICSPDAT
;                  BCD_B / RA4 -| 3    18|- RA1 / Digit right / ICSPCLK
;                    Vpp / RA3 -| 4    17|- RA2 / T0CKI (connected to C2OUT)
;                  BCD_C / RC5 -| 5    16|- RC0 / Power LED
;                  C2OUT / RC4 -| 6    15|- RC1 / C12IN1-    + sensor
; Power sensor   C12IN3- / RC3 -| 7    14|- RC2 / C12IN2-    - sensor
;                  BCD_D / RC6 -| 8    13|- RB4 / External thermometer
;                Celsius / RC7 -| 9    12|- RB5 / Valve relais
;             Fahrenheit / RB7 -|10    11|- RB6 / Internal thermometer
;                                --------    
			
			clrf	WPUA	    ; Disable pull-ups port A

			movlw	0b11001100
		    ; RA0 (19)    -------0 --> Left digit common
		    ; RA1 (18)    ------0- --> Right digit common
		    ; RA2 (17)    -----1-- <-- T0CKI connected to C2OUT (6) for oscillator
		    ; RA3 ( 4)    ----1--- --- Vpp / MLCR
		    ; RA4 ( 3)    ---0---- --> Display BCD B
		    ; RA5 ( 2)    --0----- --> Display BCD A
			movwf	TRISA
			
			movlw	0b01011111
		    ; RB4 (13)    ---1---- <-> External thermometer DS18B20
		    ; RB5 (12)    --0----- --> Valve relay
		    ; RB6 (11)    -1------ <-> Internal thermometer DS18B20
		    ; RB7 (10)    0------- --> LED Fahrenheit
			movwf	TRISB

			movlw	0b00001111
		    ; RC0 (16)    -------1 <-> LED: High-Z blue, +/- lit; High, red +/- lit; Low blue, +/- off
		    ; RC1 (15)    ------1- <-- C12IN1- CAP ???
		    ; RC2 (14)    -----1-- <-- C12IN2- CAP ???
		    ; RC3 ( 7)    ----1--- <-- C12IN3- CAP ???
		    ; RC4 ( 6)    ---0---- --> C2OUT
		    ; RC5 ( 5)    --0----- --> Display BCD C
		    ; RC6 ( 8)    -0------ --> Display BCD D
		    ; RC7 ( 9)    0------- --> LED Celsius
			movwf	TRISC

			bcf	RP0
			bsf	RP1		    ; Bank 2
			clrf	WPUB		    ; Disable pull-ups port B
			clrf	ANSEL
			clrf	ANSELH

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

			; CVref = Vdd * ( 8 + val) / 32
			;       = 3.3 * ( 8 + 12)  / 2 = 2V
			movlw	(1 << VRCON_VP6EN_POSN) |  (1 << VRCON_C1VREN_POSN) | 12
			movwf	VRCON
			movlw	(1 << CM1CON0_C1ON_POSN) | (1 << CM1CON0_C1R_POSN) | (1 << CM1CON0_C1POL_POSN) | 1
			movwf	CM1CON0
			movlw	(1 << CM2CON0_C2ON_POSN) | (1 << CM2CON0_C2R_POSN) | (1 << CM2CON0_C2OE_POSN) | 1
			movwf	CM2CON0

			bsf	RP0	; Bank 3
			;             ~Q -> C2OUT          C1 out  -> S          C2 out -> R
			movlw	(1 << SRCON_SR1_POSN) | (1 << SRCON_C1SEN_POSN) | (1 << SRCON_C2REN_POSN)
			movwf	SRCON

			; Set up timer and interrupts
			bsf	RP0			; Bank 1
			bcf	RP1

			movf	OPTION_REG, w
			;	T0CKI -> Prescaler 1:8 -> Timer 0, clear nRAPBU
			andlw	~(OPTION_REG_PS_MASK | OPTION_REG_PSA_MASK | OPTION_REG_nRABPU_MASK)
			iorlw	(1 << OPTION_REG_T0CS_POSN) | TMR0_PS_1_256
			movwf	OPTION_REG

			clrf	PIE1		; Peripheral int enable TMR2
			clrf	PIE2
			bsf	TMR2IE
			movlw	TIMER2_PERIOD
			movwf	PR2
			
			clrf	STATUS			; bank 0
			clrf	T1CON			; Timer 1 at Fosc / 4
			clrf	TMR2

			; Setup timer 2
			;   Prescaler 16 = 8us (@ 8Mzh  Fosc/4)
			;   Postscaler 5 = 40us per timer unit (8us * 5)
			;   TIMER2_PERIOD 200 = 8ms (40us * 200)
			;	Post-scaler 5                         Enable          Pre-scaler 16
			movlw	((5 - 1) << T2CON_TOUTPS_POSN) | (1 << T2CON_TMR2ON_POSN) | 0b10
			movwf	T2CON
			
			; Enable timer 2 interupt
			bcf	TMR2IF
			bsf	PEIE		; Enable peripheral int => Timer 2
			
			clrf	STATUS		; Select bank 0

;--------------------------------------------------------- 
; Read EEPROM settings
;--------------------------------------------------------- 
			; Restore brightness
			movlw	EE_BRIGHTNESS
			call	read_eeprom
			call	chk_brightness_range
			btfss	CARRY			; Carry set => valid
			movlw	BRIGHTNESS_MAX		; Otherwise default value
			movwf	brightness
			
			; Restore brightness for night mode
			movlw	EE_BRIGHTNESS_NIGHT
			call	read_eeprom
			call	chk_brightness_night_range
			btfss	CARRY			; Carry set => valid
			movlw	BRIGHTNESS_NIGHT_MIN	; Otherwise default value
			movwf	brightness_night

			;Restore unit
			movlw	EE_FAHRENHEIT
			call	read_eeprom
			bcf	FLAG_FAHRENHEIT
			addlw	-1
			btfsc	ZERO
			bsf	FLAG_FAHRENHEIT

			; Restore target temperature from EEPROM
			movlw	EE_TARGET_TEMPERATURE
			call	read_eeprom
			movwf	target_temperature
			call	chk_target_temp_range
			btfsc	CARRY
			goto	target_temp_align	; Carry set => valid
			
			movlw	CELSIUS_DEFAULT
			btfsc	FLAG_FAHRENHEIT
			movlw	FAHRENHEIT_DEFAULT

			; Store default value for recall after leaving stand-by
			movwf	target_temperature
			movwf	arg_0
			movlw	EE_TARGET_TEMPERATURE
			call	write_eeprom

			; In case of Celcius clean bit 0
			;  as we are working with 0.5 degree units
target_temp_align:	movlw	0feh
			btfss	FLAG_FAHRENHEIT
			andwf	target_temperature, f
			
			; Restore temperature offset
target_temp_offset:	movlw	EE_TEMPERATURE_OFFSET
			call	read_eeprom
			addlw	-16
			movwf	temperature_offset
			call	chk_offset_range	; Check range -9 .. 9
			btfss	CARRY
			clrf	temperature_offset	; Default to 0
    
			; Restore valve delay
			movlw	EE_RELAY_DELAY
			call	read_eeprom
			movwf	relay_delay
			sublw	RELAY_DELAY_MAX
			movlw	3			; Default valve delay 30 seconds
			btfss	CARRY
			movwf	relay_delay		; Set default value

			; Restore valve maintain time
			movlw	EE_VALVE_MAINTAIN
			call	read_eeprom
			movwf	valve_maintain_days
			sublw	VALVE_MAINTAIN_MAX	; ; C   <= VALVE_MAINTAIN_MAX
			btfss	CARRY			; Skip if <=
			clrf	valve_maintain_days	; Default off
			call	valve_maint_calc	; Update initialization value
			
			; Restore operation mode
			clrf	operation_mode		; Default heating
			movlw	EE_OPERATION_MODE
			call	read_eeprom
			sublw	OPERATION_MODE_COOLING
			btfsc	ZERO
			incf	operation_mode

			; Restore light sensor limit
			movlw	EE_LIGHT_SENSOR
			call	read_eeprom
			movwf	light_sensor_limit
			sublw	LIGHT_SENSOR_MAX
			movlw	10			; => Default 10
			btfss	CARRY
			movwf	light_sensor_limit	; Set default value
			
		    	bsf	RP0
			; Set clock to 8Mhz
			bsf	IRCF0
			bsf	IRCF1
			bsf	IRCF2

wait_osc_stable:	btfss	HTS
			goto	wait_osc_stable

			; Activate a watchdog with prescaler 2^16 
			; as the clock source is 31khz this is ~ 2s
			; Min prescaler is 2^5
			movlw	((16 - 5) << WDTCON_WDTPS_POSITION) | (1 << WDTCON_SWDTEN_POSN)
			movwf	WDTCON
			
			bcf	RP0
			bsf	GIE			; Global int enable

			clrwdt
			
			; Start cap sensor measuring
			clrf    TMR1H
			clrf    TMR1L
			bsf	TMR1ON
			movlw   TIMER0_RELOAD
			movwf   TMR0
			bcf	T0IF
			bsf	T0IE

			; Detect the DS18B20 Thermometer
			movlw	PORTB
			call	one_wire_set_port

			; Try on RB4
			btfss	PORTB, 4
			goto	try_thermometer_rb6	; Low => can't be OneWire
			movlw	4
			call	one_wire_set_pin
			call	one_wire_reset		; Port B, pin 4
			btfss	CARRY
			goto	try_thermometer_rb6	; No PD detect on RB4
			goto	main
			
try_thermometer_rb6:	btfss	PORTB, 6
			goto	error_rb6_low

			movlw	6
			call	one_wire_set_pin
			call	one_wire_reset		; Port B, pin 6
			btfss	CARRY
			goto	error_no_therm_rb6	; No PD detect on RB6
			
			; The thermometer is connected to RB6
			; Configure RB4 as analog input AN10
			;  for light sensor
			; AN10 with Vdd and left justified
			bsf	FLAG_HAS_LIGHT_SENSOR
			movlw	(10 << ADCON0_CHS_POSN) | (1 << ADCON0_ADON_POSN)
			movwf	ADCON0
			
			bsf	RP0
			movlw	0b01010000  ; Clock rate Fosc / 16 
			movwf	ADCON1
			bcf	RP0
			bsf	RP1
			bsf	ANSELH, ANSELH_ANS10_POSN   ; Configure AN10 as analog input
			bcf	RP1
			
			bsf	ADCON0, ADCON0_GO_nDONE_POSN
			movlw	ADC_TIMER_RELOAD
			movwf	var_timer_adc
			goto	main

error_rb6_low:		movlw	ERROR_RB6_LOW
			goto	failure
			
error_no_therm_rb6:	movlw   ERROR_THERMOMETER_NOT_PRESENT_RB6
			goto	failure
			    