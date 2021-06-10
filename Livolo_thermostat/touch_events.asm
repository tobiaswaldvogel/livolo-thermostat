#include <xc.inc>
#include "global.inc"    

psect   code

; Publish    
global	touch_power_short, touch_power_long
global	touch_plus_short, touch_minus_short
global	touch_plus_minus_long   
global  chk_target_temp_range, chk_offset_range, chk_0_99_range
; Use
global	enter_setup 
global	display_temperature   
global display_on, display_off, convert_fahrenheit   
global read_eeprom, write_eeprom    
    
;--------------------------------------------------------- 
; Power short
;--------------------------------------------------------- 
touch_power_short:	bcf	SIGNAL_TOUCH_POWER_SHORT
			movf    setup_mode, w
			btfss   ZERO
			goto	enter_setup	; In setup advance to next setting
			
			; Invert on / off state
			bsf	FLAG_TEMPERATURE_CHANGED
			bsf	FLAG_VALVE_IMMEDIATE

			btfss	FLAG_DISPLAY_ENABLE
			goto	touch_power_short_on

			; Set freeze safe temperature
			clrf	var_timer_inactivity	; Make sure temperature is not written by this timer
			movlw	STANDBY_TARGET_TEMPERATURE_CELSIUS
			btfsc	FLAG_FAHRENHEIT
			call	convert_fahrenheit	; Convert to fahrenheit if required
			movwf	target_temperature
			
			bsf	FLAG_STANDBY
			goto	display_off

touch_power_short_on:	; Restore target temperature
			movlw	EE_TARGET_TEMPERATURE
			call	read_eeprom
			movwf	target_temperature
    
			bcf	FLAG_STANDBY
			bcf	FLAG_DISPLAY_OFF
			call	set_display_off_delay
			goto	display_on
			
;--------------------------------------------------------- 
; Power long
;--------------------------------------------------------- 
touch_power_long:	bcf	SIGNAL_TOUCH_POWER_LONG
			movf    setup_mode, w
			btfss   ZERO
			return				; Ignore in setup mode

			btfss	FLAG_DISPLAY_ENABLE	; Switch display off if on
			return
			bsf	FLAG_DISPLAY_OFF
			goto	display_off

;--------------------------------------------------------- 
; Plus short
;--------------------------------------------------------- 
touch_plus_short:	bcf	SIGNAL_TOUCH_PLUS_SHORT
			btfsc	FLAG_STANDBY
			return			; Ignore in stand-by
			btfsc	FLAG_DISPLAY_ENABLE
			goto	touch_plus_short_2
			bcf	FLAG_DISPLAY_OFF
			call	set_display_off_delay
			call	display_on	; Switch on the display if off

touch_plus_short_2:	movf    setup_mode, w
			btfss   ZERO
			goto	touch_plus_setup

			incf	target_temperature, f
			btfss	FLAG_FAHRENHEIT
			incf	target_temperature, f

			movf	target_temperature, w
			call	chk_target_temp_range
			btfsc	CARRY			
			goto	touch_set_target_temp

			movlw	CELSIUS_MAX
			btfsc	FLAG_FAHRENHEIT
			movlw	FAHRENHEIT_MAX
			movwf	target_temperature
			goto	touch_set_target_temp
			
touch_plus_setup:	addlw	-1		
			btfss	ZERO
			goto	touch_plus_setup_delay
			; Offset
			incf	temperature_offset, f
			movf	temperature_offset, w
			call	chk_offset_range			
			btfsc	CARRY
			return
			movlw	9		; Max value
			movwf	temperature_offset
			return
			
touch_plus_setup_delay:	addlw	-1
			btfss	ZERO
			goto	touch_plus_setup_unit
			; Valve delay
			incf	valve_delay, f
			movf	valve_delay, w
			call	chk_0_99_range			
			btfsc	CARRY
			return
			movlw	99		; Max value
			movwf	valve_delay
			return
			
touch_plus_setup_unit:	addlw	-1		; Check for SETUP_DELAY
			btfss	ZERO
			goto	touch_plus_setup_ls

			btfss	FLAG_FAHRENHEIT
			goto	touch_plus_setup_f
			
			bcf	FLAG_FAHRENHEIT
			return
touch_plus_setup_f:	bsf	FLAG_FAHRENHEIT
			return
			
touch_plus_setup_ls:	addlw	-1		; Check for SETUP_DELAY
			btfsc	ZERO
			return			; Display value only

			; Light sensr 
			incf	light_sensor_limit, f
			movf	light_sensor_limit, w
			call	chk_0_99_range			
			btfsc	CARRY
			return
			movlw	99		; Max value
			movwf	light_sensor_limit
			return

;--------------------------------------------------------- 
; Minus short
;--------------------------------------------------------- 
touch_minus_short:	bcf	SIGNAL_TOUCH_MINUS_SHORT
			btfsc	FLAG_STANDBY
			return			; Ignore in stand-by
			btfsc	FLAG_DISPLAY_ENABLE
			goto	touch_minus_short_2
			bcf	FLAG_DISPLAY_OFF
			call	set_display_off_delay
			call	display_on	; Switch on the display if off
			
touch_minus_short_2:	movf    setup_mode, w
			btfss   ZERO
			goto	touch_minus_setup
    
			decf	target_temperature, f
			btfss	FLAG_FAHRENHEIT
			decf	target_temperature, f

			movf	target_temperature, w
			call	chk_target_temp_range
			btfsc	CARRY			
			goto	touch_set_target_temp

			movlw	CELSIUS_MIN
			btfsc	FLAG_FAHRENHEIT
			movlw	FAHRENHEIT_MIN
			movwf	target_temperature
			goto	touch_set_target_temp
			
touch_minus_setup:	addlw	-1
			btfss	ZERO
			goto	touch_minus_setupdelay
			; Offset
			decf	temperature_offset, f
			movf	temperature_offset, w
			call	chk_offset_range			
			btfsc	CARRY
			return
			movlw	-9
			movwf	temperature_offset
			return

touch_minus_setupdelay:	addlw	-1		; Check for SETUP_DELAY
			btfss	ZERO
			goto	touch_minus_setup_unit
			; Valve delay
			decf	valve_delay, f
			movf	valve_delay, w
			call	chk_0_99_range			
			btfss	CARRY
			clrf	valve_delay	; Default 0
			return

touch_minus_setup_unit:	addlw	-1		; Check for SETUP_LS
			btfss	ZERO
			goto	touch_setup_minus_ls

			btfss	FLAG_FAHRENHEIT
			goto	touch_minus_setup_f
			
			bcf	FLAG_FAHRENHEIT
			return
touch_minus_setup_f:	bsf	FLAG_FAHRENHEIT
			return
			
touch_setup_minus_ls:	addlw	-1
			btfsc	ZERO
			return			; Display value only

			; Light sensor
			decf	light_sensor_limit, f
			movf	light_sensor_limit, w
			call	chk_0_99_range			
			btfss	CARRY
			clrf	light_sensor_limit	; Default 0
			return
			
;--------------------------------------------------------- 
; Plus / Minus long
;
; Enter setup if both touched
;--------------------------------------------------------- 
touch_plus_minus_long:	btfss	SIGNAL_TOUCH_PLUS_LONG
			return
			btfss	SIGNAL_TOUCH_MINUS_LONG
			return
			
			; Both touched
			bcf	SIGNAL_TOUCH_PLUS_LONG
			bcf	SIGNAL_TOUCH_MINUS_LONG
			btfss	FLAG_DISPLAY_ENABLE
			call	display_on	; Switch on the display if off
			goto	enter_setup

;--------------------------------------------------------- 
; Set target temperature
;--------------------------------------------------------- 
touch_set_target_temp:	movf	target_temperature, w
			call	display_temperature

			bsf	FLAG_TEMPERATURE_CHANGED
			bsf	FLAG_VALVE_IMMEDIATE

			bcf	SIGNAL_TIMER_INACTIVITY
			movlw	INACTITIVY_TIMER
			movwf	var_timer_inactivity
			return

;--------------------------------------------------------- 
; Check target temperature range
; In: Value Out: Carry
;--------------------------------------------------------- 
chk_target_temp_range:	btfsc	FLAG_FAHRENHEIT
			goto	chk_target_temp_rangef

			; Check Celsius MAX
			sublw	CELSIUS_MAX	    ; C => <= CELSIUS_MAX
			btfss	CARRY
			return			    ; Carry clear -> Not ok
			; Check Celsius MIN
			sublw	CELSIUS_MAX	    ; Restore W
			addlw	-CELSIUS_MIN	    ; C => >= CELSIUS_MIN
			btfss	CARRY
			return			    ; Carry clear -> Not ok
			; Restore w
			addlw	CELSIUS_MIN
			bsf	CARRY		    ; Ok
			return

			; Check Celsius MAX
chk_target_temp_rangef:	sublw	FAHRENHEIT_MAX	    ; C => <= FAHRENHEIT_MAX
			btfss	CARRY
			return			    ; Carry clear -> Not ok
			; Check Fahrenheit MIN
			sublw	FAHRENHEIT_MAX	    ; Restore W
			addlw	-FAHRENHEIT_MIN	    ; C => >= FAHRENHEIT_MIN
			btfss	CARRY
			return			    ; Carry clear -> Not ok
			; Restore w
			addlw	FAHRENHEIT_MIN	    ; Restore W
			bsf	CARRY		    ; Ok
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
; Check 0 .. 99 range
; In: Value Out: Carry
;--------------------------------------------------------- 
chk_0_99_range:		sublw	99		    ; > 99 -> Carry clear
			btfss	CARRY
			return
			sublw	99		    ; Restore W
			bsf	CARRY
			return
			
;--------------------------------------------------------- 
; Start timer before the light sensor can switch off the display
;--------------------------------------------------------- 
set_display_off_delay:	bsf	FLAG_KEEP_DISPLAY_ON
			bcf	GIE
			movlw	KEEP_DISPLAY_ON_TIMER & 0ffh
			movwf	var_timer_keep_displ_on
			movlw	KEEP_DISPLAY_ON_TIMER >> 8
			movwf	var_timer_keep_displ_on + 1
			bsf	GIE
			return