#include <xc.inc>
#include "global.inc"    
#include "one_wire.inc"
    
; Publish
global	main, convert_fahrenheit, set_relay_on, failure
; Use    
global	touch_power_short, touch_power_long
global	touch_plus_short, touch_minus_short
global	touch_plus_minus_long
global	timer_inactivity, timer_adc
global	timer_relay_stop, timer_relay_start
global  timer_valve_maint_strt, timer_valve_maint_stop
global  timer_valve_maint, timer_keep_displ_on
global	display_setup, display_temperature, display_decimal
global  display_on, display_off  
global	enter_setup    
global	one_wire_reset, one_wire_rx, one_wire_tx

psect   code
   
;--------------------------------------------------------- 
; Error codes
;--------------------------------------------------------- 
failure_thermometer:	movlw	ERROR_THERMOMETER_NOT_PRESENT
    
failure:		call	display_decimal
failure_1:		movf	timer50hz, w
			addlw	-25
			btfss	CARRY
			bcf	LED_CELSIUS
			btfss	CARRY
			bsf	LED_FAHRENHEIT
			btfsc	CARRY	
			bsf	LED_CELSIUS
			btfsc	CARRY	
			bcf	LED_FAHRENHEIT
			goto	failure_1

;--------------------------------------------------------- 
; Main function
;--------------------------------------------------------- 
main:			clrf	STATUS
			movlw	0xff
			movwf	current_temperature

			call	set_relay_off
			call	display_on

			bsf	FLAG_ONEWIRE_SELF_POWERED
			; Determine thermometer power mode
			call	one_wire_reset
			btfss	CARRY
			goto	failure_thermometer
			movlw	ONE_WIRE_SKIP_ROM
			call	one_wire_tx
			movlw	DS18B20_POWER_SUPPLY
			call	one_wire_tx
			movlw	arg_7		; LSB
			movwf	FSR
			call	one_wire_rx
			btfss	INDF, 0
			bcf	FLAG_ONEWIRE_SELF_POWERED   ; Parasite power

			; Set thermometer to 11 bit resolution
			call	one_wire_reset
			btfss	CARRY
			goto	failure_thermometer
			movlw	ONE_WIRE_SKIP_ROM
			call	one_wire_tx
			movlw	DS18B20_WRITE
			call	one_wire_tx
			movlw	0
			call	one_wire_tx
			movlw	0
			call	one_wire_tx
			movlw	DS18B20_RES_11
			call	one_wire_tx
		
			call	measure_temperature
			
			bsf	RP0
			movlw	0b01101			    ; Watchdog on, 1: 2048 ~ 66ms
			movwf	WDTCON
			bcf	RP0

main_check_signals:	clrwdt				    ;Reset watchdog
			btfsc	SIGNAL_TOUCH_POWER_SHORT
			call	touch_power_short
			btfsc	SIGNAL_TOUCH_POWER_LONG
			call	touch_power_long
			btfsc	SIGNAL_TOUCH_PLUS_SHORT
			call	touch_plus_short
			btfsc	SIGNAL_TOUCH_PLUS_LONG
			call	touch_plus_minus_long
			btfsc	SIGNAL_TOUCH_MINUS_SHORT
			call	touch_minus_short
			btfsc	SIGNAL_TOUCH_MINUS_LONG
			call	touch_plus_minus_long
			btfsc	SIGNAL_TIMER_INACTIVITY
			call	timer_inactivity
			btfsc	SIGNAL_TIMER_THERMOMETER
			call	read_temperature
			btfsc	SIGNAL_TIMER_ADC
			call	timer_adc
			btfsc	SIGNAL_TIMER_VALVE
			call	set_relay
			btfsc	SIGNAL_TIMER_VALVE_MAINTAIN
			call	timer_valve_maint
			btfsc	SIGNAL_TIMER_KEEP_DISPLAY_ON
			call	timer_keep_displ_on
			
			movf    setup_mode, w
			btfss   ZERO
			call	display_setup			
			
			btfsc	FLAG_TEMPERATURE_CHANGED
			call	temp_change
			goto	main_check_signals

;--------------------------------------------------------- 
; Evaluate temperature or target change
;--------------------------------------------------------- 
temp_change:		bcf	FLAG_TEMPERATURE_CHANGED
			movf	var_timer_inactivity, w
			btfss	ZERO
			goto	temp_change_1		; Don't display if inactivity timer active
			movf	current_temperature, w
			call	display_temperature
			
temp_change_1:		btfss	FLAG_RELAY_IMMEDIATE
			goto	temp_relay_delay
			bcf	FLAG_RELAY_IMMEDIATE
			goto	set_relay

temp_relay_delay:	movf	operation_mode, w
			btfsc	ZERO
			goto	temp_delay_heat

			; Cooling mode
			movf	current_temperature, w
		    	subwf	target_temperature,  w	; current <= target -> CARRY
			btfss	CARRY
			goto	schedule_relay_on
			goto	schedule_relay_off
			
			; Heating mode
temp_delay_heat:	movf	target_temperature,  w
			subwf	current_temperature, w	;  current >= target -> CARRY
			btfss	CARRY
			goto	schedule_relay_on	; Target not reached

schedule_relay_off:	btfss	RELAY
			goto	timer_relay_stop	; Already off
			goto	timer_relay_start

schedule_relay_on:	btfsc	RELAY
			goto	timer_relay_stop	; Already on
			goto	timer_relay_start


;--------------------------------------------------------- 
; Set relay and indicator
;--------------------------------------------------------- 
set_relay:		bcf	SIGNAL_TIMER_VALVE

			movf	operation_mode, w
			btfsc	ZERO
			goto	set_relay_heating

			; Cooling mode
			movf	current_temperature, w
		    	subwf	target_temperature,  w	; current <= target -> CARRY
			btfss	CARRY
			goto	set_relay_on
			goto	set_relay_off
			
			; Heating mode
set_relay_heating:	movf	target_temperature,  w
			subwf	current_temperature, w	;  current >= target -> CARRY
			btfss	CARRY
			goto	set_relay_on

set_relay_off:		bcf	RELAY
			call	timer_valve_maint_strt
			btfss	FLAG_DISPLAY_ENABLE
			return			; Display off 
			
			bsf	RP0
			bsf	LED_POWER	; TRIS -> input
			bcf	RP0		; => lit + blue led
			return

set_relay_on:		bsf	RELAY
			call	timer_valve_maint_stop
			bcf	SIGNAL_TIMER_VALVE_MAINTAIN
			btfss	FLAG_DISPLAY_ENABLE
			return			; Display off 
			
			bsf	RP0
			bcf	LED_POWER	; TRIS -> output
			bcf	RP0
			bsf	LED_POWER	; => lit + red led
			return
			
;--------------------------------------------------------- 
; Read temperature and process
;--------------------------------------------------------- 
read_temperature:	bcf	SIGNAL_TIMER_THERMOMETER

			call	one_wire_reset
			btfss	CARRY
			goto	failure_thermometer
			movlw	ONE_WIRE_SKIP_ROM
			call	one_wire_tx
			movlw	DS18B20_READ
			call	one_wire_tx

			movlw	arg_4		; LSB
			movwf	FSR
			call	one_wire_rx

			movlw	arg_5		; MSB
			movwf	FSR
			call	one_wire_rx

			bcf	CARRY
			rrf	arg_5, f    ; Discard bit 0
			rrf	arg_4, f
			rrf	arg_5, f    ; Discard bit 1
			rrf	arg_4, f    
			incf	arg_4, f    ; Add 1 for rounding
			btfsc	ZERO
			incf	arg_5, f
			rrf	arg_5, f    ; Discard bit 2
			rrf	arg_4, w
			
			; Measured temperature now in w in .5 degree Celsius
			btfsc	FLAG_FAHRENHEIT
			call	convert_fahrenheit
			addwf	temperature_offset, w

			
			subwf	current_temperature, w
			btfsc	ZERO
			goto	read_temperature_1
			
			; Indicate temperature change
			subwf	current_temperature, f
			bsf	FLAG_TEMPERATURE_CHANGED
read_temperature_1:	goto	measure_temperature ; Start next measurement

;--------------------------------------------------------- 
; Start temperature measurement
;--------------------------------------------------------- 
measure_temperature:	call	one_wire_reset
			btfss	CARRY
			goto	failure_thermometer
			movlw	ONE_WIRE_SKIP_ROM
			call	one_wire_tx
			movlw	DS18B20_CONVERT
			call	one_wire_tx
			
			movlw	50		    ; Wait 50 * 20ms = 1s  for conversion
			bcf	SIGNAL_TIMER_THERMOMETER
			movwf	var_timer_thermometer   ; Start conversion timer
			return

			
flip_led_f:		btfsc	LED_FAHRENHEIT
			goto	flip_led_f_clear
			
			bsf	LED_FAHRENHEIT
			return
			
flip_led_f_clear:	bcf	LED_FAHRENHEIT
			return

			
			
;--------------------------------------------------------- 
; Input is 0.5 centigrades
; Fahrenheit = input * 9 / 10 + 32
; Approximate with  * 230 / 256 + 32 to avoid division
; 230 = 0b11100110    
;--------------------------------------------------------- 
convert_f_mult_1	equ	arg_0
convert_f_mult_2_0	equ	arg_1
convert_f_mult_2_1	equ	arg_2
convert_f_result_0	equ	arg_3
convert_f_result_1	equ	arg_4


convert_fahrenheit:	movwf	convert_f_mult_2_0
			clrf	convert_f_mult_2_1
			movlw	230
			movwf	convert_f_mult_1
			clrf	convert_f_result_0
			clrf	convert_f_result_1

convert_f_loop:		bcf	CARRY
			rrf	convert_f_mult_1
			btfss	CARRY
			goto	convert_f_next

			movf	convert_f_mult_2_0, w
			addwf	convert_f_result_0, f
			movf	convert_f_mult_2_1, w
			btfsc	CARRY
			incfsz	convert_f_mult_2_1, w
			addwf	convert_f_result_1, f

convert_f_next:		movf	convert_f_mult_1, w	; Still bits left ?
			btfsc   ZERO
			goto	convert_f_offset

			bcf	CARRY
			rlf	convert_f_mult_2_0
			rlf	convert_f_mult_2_1
			goto	convert_f_loop
			
convert_f_offset:	movf	convert_f_result_1, w	; MSB = / 256
			addlw	32
			sublw	99	    ; Limit to 99
			btfss	CARRY
			movlw	99
			btfsc	CARRY
			sublw	99
			return
