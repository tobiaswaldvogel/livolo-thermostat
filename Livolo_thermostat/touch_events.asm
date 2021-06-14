#include <xc.inc>
#include "global.inc"    

psect   code

; Publish    
global	touch_power_short, touch_power_long
global	touch_plus_short, touch_minus_short
global	touch_plus_minus_long   
global  chk_target_temp_range
; Use
global	enter_setup, touch_plus_setup, touch_minus_setup    
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
			bsf	FLAG_RELAY_IMMEDIATE

			btfss	FLAG_DISPLAY_ENABLE
			goto	touch_power_short_on

			; Stand-by
			; Set freeze safe temperature
			clrf	var_timer_inactivity	; Make sure temperature is not written by this timer

			movf	operation_mode, w
			btfsc	ZERO
			goto	stand_by_heating

stand_by_colling:	movlw	255
			goto	enter_stand_by
			
stand_by_heating:	movlw	STANDBY_TARGET_TEMPERATURE_CELSIUS
			btfsc	FLAG_FAHRENHEIT
			call	convert_fahrenheit	; Convert to fahrenheit if required

enter_stand_by:		movwf	target_temperature
			bsf	FLAG_STANDBY
			goto	display_off

touch_power_short_on:	; Restore target temperature from EEPROM
			movlw	EE_TARGET_TEMPERATURE
			call	read_eeprom
			movwf	target_temperature
    
			bcf	FLAG_STANDBY
			bcf	FLAG_DISPLAY_OFF
			call	set_display_off_delay
			bcf	FLAG_NIGHT_MODE
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
			bcf	FLAG_NIGHT_MODE
			call	display_on	; Switch on the display if off

touch_plus_short_2:	call	set_display_off_delay
			movf    setup_mode, w
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

;--------------------------------------------------------- 
; Minus short
;--------------------------------------------------------- 
touch_minus_short:	bcf	SIGNAL_TOUCH_MINUS_SHORT
			btfsc	FLAG_STANDBY
			return			; Ignore in stand-by
			btfsc	FLAG_DISPLAY_ENABLE
			goto	touch_minus_short_2
			bcf	FLAG_DISPLAY_OFF
			bcf	FLAG_NIGHT_MODE
			call	display_on	; Switch on the display if off
			
touch_minus_short_2:	call	set_display_off_delay
			movf    setup_mode, w
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
			bsf	FLAG_RELAY_IMMEDIATE

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