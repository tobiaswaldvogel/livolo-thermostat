#include <xc.inc>
#include "global.inc"    
#include "one_wire.inc"
    
; Publish
global	main, convert_fahrenheit, set_relay_on, failure, day_night_mode
; Use    
global	touch_power_short, touch_power_long
global	touch_plus_short,  touch_plus_long
global  touch_minus_short, touch_minus_long
global  touch_repeat, touch_repeat_stop   
global	timer_target_temp, timer_adc
global	timer_relay_stop, timer_relay_start
global  timer_valve_maint_strt, timer_valve_maint_stop
global  timer_valve_maint, timer_night_disable
global	setup_display, display_temperature, display_decimal
global  display_day, display_night, disp_set_brightness, display_unit   
global	one_wire_reset, one_wire_rx, one_wire_tx

psect   code
   
;--------------------------------------------------------- 
; Error codes
;--------------------------------------------------------- 
failure_thermometer:	movlw	ERROR_THERMOMETER_NOT_PRESENT
    
failure:		call	display_decimal
			movlw	BRIGHTNESS_MAX
			call	disp_set_brightness

failure_1:		movf	var_timer_125hz, w
			addlw	-62
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

			bcf	FLAG_NIGHT_MODE
			bsf	FLAG_NIGHT_MODE_AUTOMATIC
			call	display_unit
			call	display_day
			call	set_relay_off
			bsf	FLAG_RELAY_IMMEDIATE

main_detect_power_mode:	bsf	FLAG_ONEWIRE_SELF_POWERED
			; Determine thermometer power mode

			call	one_wire_reset
			btfss	CARRY
			goto	failure_thermometer

			movlw	ONE_WIRE_SKIP_ROM
			bcf	CARRY
			call	one_wire_tx
			movlw	DS18B20_POWER_SUPPLY
			bcf	CARRY
			call	one_wire_tx

			call	one_wire_rx
			andlw	0b00000001
			btfsc	ZERO
			bcf	FLAG_ONEWIRE_SELF_POWERED   ; Parasite power

			; Set thermometer to 11 bit resolution
			call	one_wire_reset
			btfss	CARRY
			goto	failure_thermometer

			movlw	ONE_WIRE_SKIP_ROM
			bcf	CARRY
			call	one_wire_tx
			movlw	DS18B20_WRITE
			bcf	CARRY
			call	one_wire_tx
			movlw	0
			bcf	CARRY
			call	one_wire_tx
			movlw	0
			bcf	CARRY
			call	one_wire_tx
			movlw	DS18B20_RES_11
			bcf	CARRY
			call	one_wire_tx
		
			call	measure_temperature
			movlw	1   ; Set the timer to 1s for the initial read
			movwf	var_timer_thermometer
			
main_check_signals:	clrwdt				    ;Reset watchdog
			btfsc	SIGNAL_TOUCH_POWER_SHORT
			call	touch_power_short
			btfsc	SIGNAL_TOUCH_POWER_LONG
			call	touch_power_long
			btfsc	SIGNAL_TOUCH_PLUS_SHORT
			call	touch_plus_short
			btfsc	SIGNAL_TOUCH_MINUS_SHORT
			call	touch_minus_short
			
			; Long touch release
			movf	signal_release, w
			btfss   ZERO
			call	touch_repeat_stop

			btfsc	SIGNAL_TIMER_TOUCH_REPEAT
			call	touch_repeat
			
			; Repeat timer running for long events ?
			movf    var_timer_touch_repeat, w
			btfss   ZERO
			goto    main_timer_signals
			
			btfsc	SIGNAL_TOUCH_PLUS_LONG
			call	touch_plus_long
			btfsc	SIGNAL_TOUCH_MINUS_LONG
			call	touch_minus_long

main_timer_signals:	btfsc	SIGNAL_TIMER_TARGET_TEMPERATURE
			call	timer_target_temp
			btfsc	SIGNAL_TIMER_THERMOMETER
			call	read_temperature
			btfsc	SIGNAL_TIMER_ADC
			call	timer_adc
			btfsc	SIGNAL_TIMER_VALVE
			call	set_relay
			btfsc	SIGNAL_TIMER_VALVE_MAINTAIN
			call	timer_valve_maint
			btfsc	SIGNAL_TIMER_NIGHT_DISABLE
			call	timer_night_disable
			
			movf    setup_mode, w
			btfss   ZERO
			call	setup_display

			movf	var_timer_target_temp, w	; Flash unit if displaying target temperature
			btfss	ZERO
			call	flash_unit
			
			btfss	FLAG_HAS_LIGHT_SENSOR
			call	day_night_mode			; Set day/night if no sensor
			
			btfsc	FLAG_TEMPERATURE_CHANGED
			call	temp_change
			goto	main_check_signals

;--------------------------------------------------------- 
; Flash unit symbol
;--------------------------------------------------------- 
flash_unit:		movf	var_timer_125hz, w
			addlw	-25
			btfss	CARRY
			goto	flash_unit_blank

			btfss	FLAG_FAHRENHEIT
			bsf	LED_CELSIUS
			btfsc	FLAG_FAHRENHEIT
			bsf	LED_FAHRENHEIT
			return
			
flash_unit_blank:	bcf	LED_CELSIUS
			bcf	LED_FAHRENHEIT
			return

;--------------------------------------------------------- 
; Set day / night mode
;--------------------------------------------------------- 
day_night_mode:		btfss	FLAG_NIGHT_MODE_AUTOMATIC
			return	; No automatic night mode
			btfsc	FLAG_STANDBY
			return	; Skip in stand-by

			movf	setup_mode, w
			btfss	ZERO
			return	; Skip in setup

			movf	light_sensor_value, w
			subwf	light_sensor_limit, w
			btfsc	CARRY
			goto	day_night_mode_night

			btfss	FLAG_NIGHT_MODE
			return	; Already day mode
			bcf	FLAG_NIGHT_MODE
			goto	display_day
			
day_night_mode_night:	btfsc	FLAG_NIGHT_MODE
			return	;Already in night mode
			bsf	FLAG_NIGHT_MODE
			goto	display_night
			
;--------------------------------------------------------- 
; Evaluate temperature or target change
;--------------------------------------------------------- 
temp_change:		bcf	FLAG_TEMPERATURE_CHANGED
			movf	var_timer_target_temp, w
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

schedule_relay_off:	btfss	PIN_RELAY
			goto	timer_relay_stop	; Already off
			goto	timer_relay_start

schedule_relay_on:	btfsc	PIN_RELAY
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

set_relay_off:		bcf	PIN_RELAY
			call	timer_valve_maint_strt
			bcf	LED_POWER_RED			
			bsf	LED_POWER_ON			
			return

set_relay_on:		bsf	PIN_RELAY
			call	timer_valve_maint_stop
			bcf	SIGNAL_TIMER_VALVE_MAINTAIN
			bsf	LED_POWER_RED			
			bsf	LED_POWER_ON			
			return
			
;--------------------------------------------------------- 
; Read temperature and process
;--------------------------------------------------------- 
read_temperature:	bcf	SIGNAL_TIMER_THERMOMETER
			call	one_wire_reset
			btfss	CARRY
			goto	failure_thermometer

			movlw	ONE_WIRE_SKIP_ROM
			bcf	CARRY
			call	one_wire_tx
			movlw	DS18B20_READ
			bcf	CARRY
			call	one_wire_tx

			call	one_wire_rx
			movwf	arg_4		; LSB
			call	one_wire_rx
			movwf	arg_5		; MSB
			
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
			bcf	CARRY
			call	one_wire_tx

			movlw	DS18B20_CONVERT
			bcf	CARRY
			btfss	FLAG_ONEWIRE_SELF_POWERED
			bsf	CARRY		    ; Parasite power
			call	one_wire_tx
			
			movlw	MEASURE_FREQUENCY
			bcf	SIGNAL_TIMER_THERMOMETER
			movwf	var_timer_thermometer   ; Start conversion timer
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
