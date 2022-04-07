#include <xc.inc>
#include "global.inc"    

; Publish    
global	setup_next, setup_plus, setup_minus, setup_end, setup_display
global	chk_offset_range, chk_brightness_range, chk_brightness_night_range
; Use    
global	display_decimal, display_unit
global  display_day, display_night   
global	read_eeprom, write_eeprom   
global	valve_maint_calc
psect   code

;--------------------------------------------------------- 
; Sequence: (likely to change ... unlikely)
;   Operation mode (heating / cooling)
;   Temperature offset
;   Delay for the actor (heating / cooling)
;   Valve maintenance days
;   Brightness for normal operation   
;   Light sensor value
;   Light sensor theshold
;   Temperature Unit (Celsius / Fahrenheit)
;--------------------------------------------------------- 
   
setup_jp:		movlw	(setup_jp_table - 4) >> 8
			movwf	PCLATH
			movlw	(setup_jp_table - 4) & 0ffh
			addwf	setup_mode, w
			btfsc	CARRY
			incf	PCLATH, f
			movwf	PCL
   
setup_jp_table:		goto	setup_save_op_mode
		    	goto	setup_display_op_mode
			goto	setup_toggle_op_mode
			goto	setup_toggle_op_mode

			goto	setup_save_offset
			goto	setup_display_offset
			goto	setup_plus_offset
			goto	setup_minus_offset

			goto	setup_save_delay
			goto	setup_display_delay
			goto	setup_plus_delay
			goto	setup_minus_delay

			goto	setup_save_maintain
			goto	setup_display_maintain
			goto	setup_plus_maintain
			goto	setup_minus_maintain

			goto	setup_save_brightness
			goto	setup_display_bright
			goto	setup_plus_brightness
			goto	setup_minus_brightness

			goto	setup_save_brightness_night
			goto	setup_display_brightness_night
			goto	setup_plus_brightness_night
			goto	setup_minus_brightness_night

			return
			goto	setup_display_ls
			return	; ls display only
			return	; ls display only

			goto	setup_save_ls_th
			goto	setup_display_ls_th
			goto	setup_plus_lght_sensor
			goto	setup_minus_lght_sensr

			goto	setup_save_unit
			goto	setup_display_unit
			goto	setup_toggle_unit
			goto	setup_toggle_unit
setup_jp_table_end:
   
;--------------------------------------------------------- 
; Advances to the next setup setting.
;--------------------------------------------------------- 
setup_next:		call	setup_display_blank

			movlw	0b11111100
			andwf	setup_mode, f
			btfss	ZERO			    ; First call, nothing to do
			call	setup_jp		    ; Save setting
			
			movlw	4			    ; Advance to next item
			addwf	setup_mode, f
			movf	setup_mode, w
			sublw	setup_jp_table_end - setup_jp_table ; C   <=
			btfsc	CARRY
			return				    ; Not the laste item
			
leave_setup:		clrf	setup_mode, f
			call	valve_maint_calc    ; Update initialization value
			bsf	FLAG_TEMPERATURE_CHANGED    ; Refresh temperature
			bsf	FLAG_RELAY_IMMEDIATE	    ; and timers
			goto	display_unit
			
			; Save operation mode
setup_save_op_mode:	bcf	LED_POWER_RED
			bsf	LED_POWER_ON
    
		        movf	operation_mode, w
			andlw	0b1
			movwf	arg_0
			movlw	OPERATION_MODE_COOLING
			movlw	EE_OPERATION_MODE
			goto	write_eeprom
    
			; Save offset
setup_save_offset:	movf	temperature_offset, w
			addlw	16
			movwf	arg_0
			movlw	EE_TEMPERATURE_OFFSET
			goto	write_eeprom
			
			; Save delay
setup_save_delay:	movf	relay_delay, w
			movwf	arg_0
			movlw	EE_RELAY_DELAY
			goto	write_eeprom

			; Save valve maintanance days
setup_save_maintain:	movf	valve_maintain_days, w
			movwf	arg_0
			movlw	EE_VALVE_MAINTAIN
			goto	write_eeprom
						
			; Save brightness
setup_save_brightness:	movf	brightness, w
			movwf	arg_0
			movlw	EE_BRIGHTNESS
			goto	write_eeprom
			
			; Save brightness night
setup_save_brightness_night:
			call	display_day
    
			movf	brightness_night, w
			movwf	arg_0
			movlw	EE_BRIGHTNESS_NIGHT
			goto	write_eeprom

			; Save light sensor threshold
setup_save_ls_th:	movf	light_sensor_limit, w
			movwf	arg_0
			movlw	EE_LIGHT_SENSOR
			goto	write_eeprom
			
			; Save unit
setup_save_unit:	movlw	0
			btfsc	FLAG_FAHRENHEIT
			movlw	1
			movwf	arg_0
			movlw	EE_FAHRENHEIT
			goto	write_eeprom

;--------------------------------------------------------- 
; Touch 'O' in setup
;--------------------------------------------------------- 
setup_end:		bcf	setup_mode, 0
			bcf	setup_mode, 1
			call	setup_jp		    ; Save setting
			goto	leave_setup
			
;--------------------------------------------------------- 
; Display setup values
;--------------------------------------------------------- 
setup_display:		movf	var_timer_125hz, w
			addlw	-25
			btfss	CARRY
			goto	setup_display_blank

			bsf	setup_mode, 0	; Display entry
			bcf	setup_mode, 1
			goto	setup_jp

setup_display_op_mode:	movf	operation_mode, w
			iorlw	0f0h			    ; blank left digit
			movwf	display_bcd

			movf	operation_mode, w
			btfss	ZERO
			bcf	LED_POWER_RED
			btfsc	ZERO
			bsf	LED_POWER_RED
			bsf	LED_POWER_ON
			return
			
			; Display offset
setup_display_offset:	btfsc   temperature_offset, 7
			goto    setup_display_off_neg
			
			movf    temperature_offset, w
			iorlw	0f0h		; blank left digit
			movwf	display_bcd
			return

setup_display_off_neg:	swapf	temperature_offset, w
			xorlw	0xf0		; 2 complement
			addlw	0x10
			movwf	display_bcd
			return

			; Display relay delay
setup_display_delay:	movf	relay_delay, w
			goto	display_decimal
			
			; Display valve maintenance days + LED Celsius
setup_display_maintain:	bsf	LED_CELSIUS
			movf	valve_maintain_days, w
			goto	display_decimal

			; Display brightness / 16
setup_display_bright:	movf	brightness, w
			call	display_decimal
			bsf	LED_POWER_RED
			goto	display_day
    
			; Display brightness / 16
setup_display_brightness_night:
			movf	brightness_night, w
			call	display_decimal
			bcf	LED_POWER_RED
			goto	display_night

			; Display light sensor value
setup_display_ls:	bsf	LED_FAHRENHEIT
			bsf	LED_CELSIUS
			movf	light_sensor_value, w
			goto	display_decimal

			; Display light sensor threshold
setup_display_ls_th:	movf	light_sensor_limit, w
			goto	display_decimal

			; Display unit
setup_display_unit:	btfsc   FLAG_FAHRENHEIT
			goto	setup_display_unit_f
			
			bsf	LED_CELSIUS
			bcf	LED_FAHRENHEIT
			return

setup_display_unit_f:	bsf	LED_FAHRENHEIT
			bcf	LED_CELSIUS
			return
			
setup_display_blank:	movlw	0ffh
			movwf	display_bcd
			bcf	LED_CELSIUS
			bcf	LED_FAHRENHEIT
			return

;--------------------------------------------------------- 
; Touch '+' in setup
;--------------------------------------------------------- 
setup_plus:		bcf	setup_mode, 0	; '+' entry
			bsf	setup_mode, 1
			goto	setup_jp

			; Offset
setup_plus_offset:	incf	temperature_offset, f
			movf	temperature_offset, w
			call	chk_offset_range			
			movlw	9		; Max value
			btfss	CARRY
			movwf	temperature_offset  ; Set to max if out of range
			return

			; Relay delay
setup_plus_delay:	incf	relay_delay, f
			movf	relay_delay, w
			sublw	RELAY_DELAY_MAX
			movlw	RELAY_DELAY_MAX	; Max value
			btfss	CARRY
			movwf	relay_delay	; Set to max if out of range
			return

			; Valve maintance days
setup_plus_maintain:	incf	valve_maintain_days, f
			movf	valve_maintain_days, w
			sublw	VALVE_MAINTAIN_MAX
			movlw	VALVE_MAINTAIN_MAX  ; Max value
			btfss	CARRY
			movwf	valve_maintain_days ; Set to max if out of range
			return

			; Brightness
setup_plus_brightness:	incf	brightness, f
			movf	brightness, w
			sublw	BRIGHTNESS_MAX
			movlw	BRIGHTNESS_MAX
			btfss	CARRY
			movwf	brightness
			return
   
			; Brightness night
setup_plus_brightness_night:
			incf	brightness_night, f
			movf	brightness_night, w
			sublw	BRIGHTNESS_NIGHT_MAX
			movlw	BRIGHTNESS_NIGHT_MAX
			btfss	CARRY
			movwf	brightness_night
			return

			; Light sensor 
setup_plus_lght_sensor: incf	light_sensor_limit, f
			movf	light_sensor_limit, w
			sublw	LIGHT_SENSOR_MAX
			movlw	LIGHT_SENSOR_MAX    ; Max value
			btfss	CARRY		    ;Set to max if out of range
			movwf	light_sensor_limit
			return
			
;--------------------------------------------------------- 
; Touch '-' in setup
;--------------------------------------------------------- 
setup_minus:		bsf	setup_mode, 0	; '-' entry
			bsf	setup_mode, 1
			goto	setup_jp

			; Offset
setup_minus_offset:	decf	temperature_offset, f
			movf	temperature_offset, w
			call	chk_offset_range			
			movlw	-9
			btfss	CARRY
			movwf	temperature_offset  ; Set to min if out of range
			return

			; Relay delay
setup_minus_delay:	decf	relay_delay, f
			movf	relay_delay, w
			sublw	RELAY_DELAY_MAX	; Check range 0 .. 99
			btfss	CARRY
			clrf	relay_delay	; Default 0
			return

			; Valve maintance days
setup_minus_maintain:	decf	valve_maintain_days, f
			movf	valve_maintain_days, w
			sublw	VALVE_MAINTAIN_MAX
			btfss	CARRY
			clrf	valve_maintain_days
			return

			; Brightness
setup_minus_brightness:	decf	brightness, f
			movf	brightness, w
			sublw	BRIGHTNESS_MIN
			movlw	BRIGHTNESS_MIN
			btfsc	CARRY
			movwf	brightness
			return
			
			; Brightness night
setup_minus_brightness_night:
			decf	brightness_night, f
			movf	brightness_night, w
			sublw	BRIGHTNESS_NIGHT_MAX
			btfss	CARRY
			clrf	brightness_night
			return

			; Light sensor
setup_minus_lght_sensr:	decf	light_sensor_limit, f
			movf	light_sensor_limit, w
			sublw	LIGHT_SENSOR_MAX	; Check range
			btfss	CARRY
			clrf	light_sensor_limit	; Default 0
			return
    
;--------------------------------------------------------- 
; Common for + / -
;--------------------------------------------------------- 
setup_toggle_op_mode:	movlw	1
			xorwf	operation_mode, f
			andwf	operation_mode, f
			return

setup_toggle_unit:	btfss	FLAG_FAHRENHEIT
			goto	setup_toggle_unit_f
			
			bcf	FLAG_FAHRENHEIT
			movlw	0feh		; Clear LSB (0.5 degree for Celsius)
			andwf	target_temperature, f
			return

setup_toggle_unit_f:	bsf	FLAG_FAHRENHEIT
			return

;--------------------------------------------------------- 
; Check offset range
; In: Value Out: Carry
;--------------------------------------------------------- 
chk_offset_range:	addlw	9		    ; -9 .. +9 -> 0 .. 18
			; Check max
			sublw	18		    ;  > 18 -> Carry clear
			btfss	CARRY
			return			    ; Carry clear -> Not ok

			sublw	18		    ;  Restore W
			addlw	-9
			bsf	CARRY
			return

;--------------------------------------------------------- 
; Check offset range
; In: Value Out: Carry
;--------------------------------------------------------- 
chk_brightness_range:	sublw	BRIGHTNESS_MAX	    ; C   <= BIRGHTNESS_MAX
			btfss	CARRY
			return			    ; Carry clear -> Not ok
			
			sublw	BRIGHTNESS_MAX	    ; Restore W
			addlw	-BRIGHTNESS_MIN	    ; C => >= CELSIUS_MIN
			btfss	CARRY
			return			    ; Carry clear -> Not ok
			; Restore w
			addlw	BRIGHTNESS_MIN
			bsf	CARRY		    ; Ok
			return

;--------------------------------------------------------- 
; Check offset range
; In: Value Out: Carry
;--------------------------------------------------------- 
chk_brightness_night_range:
			sublw	BRIGHTNESS_NIGHT_MAX	; C   <= BIRGHTNESS_NIGHT_MAX
			btfss	CARRY
			return				; Carry clear -> Not ok
			
			sublw	BRIGHTNESS_NIGHT_MAX	; Restore W
			bsf	CARRY			; Ok
			return
			