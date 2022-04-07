#include <xc.inc>
#include "global.inc"    

psect   code

; Publish    
global	touch_power_short, touch_power_long
global	touch_plus_short,  touch_plus_long
global  touch_minus_short, touch_minus_long
global  touch_repeat, touch_repeat_stop   
global  chk_target_temp_range
; Use
global	setup_next, setup_plus, setup_minus, setup_end
global	display_temperature, display_decimal   
global  convert_fahrenheit   
global  display_day, display_night, disp_set_brightness   
global  timer_set_night_disable
global  read_eeprom, write_eeprom    
    
;--------------------------------------------------------- 
; Power short
;--------------------------------------------------------- 
touch_power_short:	bcf	SIGNAL_TOUCH_POWER_SHORT
			movf    setup_mode, w
			btfss   ZERO
			goto	setup_next		; In setup advance to next setting
			
			; Invert on / off state
			bsf	FLAG_TEMPERATURE_CHANGED
			bsf	FLAG_RELAY_IMMEDIATE

			btfsc	FLAG_NIGHT_MODE
			goto	night_mode_leave
			
			btfsc	FLAG_STANDBY
			goto	stand_by_leave
			
			; Stand-by
			; Set freeze safe temperature
			clrf	var_timer_target_temp	; Make sure temperature is not written by this timer

			movf	operation_mode, w
			btfsc	ZERO
			goto	stand_by_heating

stand_by_cooling:	movlw	255
			goto	stand_by_set_temp
			
stand_by_heating:	movlw	STANDBY_TARGET_TEMPERATURE_CELSIUS
			btfsc	FLAG_FAHRENHEIT
			call	convert_fahrenheit	; Convert to fahrenheit if required

stand_by_set_temp:	movwf	target_temperature
			bsf	FLAG_STANDBY
			bcf	FLAG_NIGHT_MODE_AUTOMATIC

			clrf	disp_brightness		; Display off
			return

stand_by_leave:		bcf	FLAG_STANDBY
			bsf	FLAG_NIGHT_MODE_AUTOMATIC

			; Restore target temperature from EEPROM
			movlw	EE_TARGET_TEMPERATURE
			call	read_eeprom
			movwf	target_temperature
			
night_mode_leave:	call	timer_set_night_disable
			bcf	FLAG_NIGHT_MODE
			call	display_day
			return
			
;--------------------------------------------------------- 
; Power long
;--------------------------------------------------------- 
touch_power_long:	bcf	SIGNAL_TOUCH_POWER_LONG
			movf    setup_mode, w
			btfss   ZERO
			goto	setup_end

			clrf	var_timer_night_disable	    ; Stop timer as it would re-enable automatic night mode
			bcf	FLAG_NIGHT_MODE_AUTOMATIC
			bsf	FLAG_NIGHT_MODE
			goto	display_night

;--------------------------------------------------------- 
; Plus short
;--------------------------------------------------------- 
touch_plus_short:	bcf	SIGNAL_TOUCH_PLUS_SHORT
			btfsc	FLAG_STANDBY
			return			; Ignore in stand-by

			call	timer_set_night_disable
			bcf	FLAG_NIGHT_MODE
			call	display_day

			movf    setup_mode, w
			btfss   ZERO
			goto	setup_plus

			movf	var_timer_target_temp, w
			btfsc	ZERO
			goto	touch_disp_target_temp	; On first touch just display

			; Increase target temperature
			incf	target_temperature, f
			btfss	FLAG_FAHRENHEIT
			incf	target_temperature, f

			movf	target_temperature, w
			call	chk_target_temp_range
			btfsc	CARRY			
			goto	touch_disp_target_temp

			movlw	CELSIUS_MAX
			btfsc	FLAG_FAHRENHEIT
			movlw	FAHRENHEIT_MAX
			movwf	target_temperature
			goto	touch_disp_target_temp

;--------------------------------------------------------- 
; Plus long
;--------------------------------------------------------- 
touch_plus_long:	movf    setup_mode, w
			btfsc   ZERO
			goto	touch_enter_setup

			movlw	TOUCH_REPEAT
			movwf   var_timer_touch_repeat
			goto	setup_plus

;--------------------------------------------------------- 
; Minus short
;--------------------------------------------------------- 
touch_minus_short:	bcf	SIGNAL_TOUCH_MINUS_SHORT
			btfsc	FLAG_STANDBY
			return			; Ignore in stand-by

			call	timer_set_night_disable
			bcf	FLAG_NIGHT_MODE
			call	display_day

			movf    setup_mode, w
			btfss   ZERO
			goto	setup_minus
    
			movf	var_timer_target_temp, w
			btfsc	ZERO
			goto	touch_disp_target_temp	; On first touch just display

			; Decrease target temperature
			decf	target_temperature, f
			btfss	FLAG_FAHRENHEIT
			decf	target_temperature, f

			movf	target_temperature, w
			call	chk_target_temp_range
			btfsc	CARRY			
			goto	touch_disp_target_temp

			movlw	CELSIUS_MIN
			btfsc	FLAG_FAHRENHEIT
			movlw	FAHRENHEIT_MIN
			movwf	target_temperature
			goto	touch_disp_target_temp
			
;--------------------------------------------------------- 
; Minus long
;--------------------------------------------------------- 
touch_minus_long:	movf    setup_mode, w
			btfsc   ZERO
			goto	touch_enter_setup

			movlw	TOUCH_REPEAT
			movwf   var_timer_touch_repeat
			goto	setup_minus
			
;--------------------------------------------------------- 
; Repeat timer on hold
;--------------------------------------------------------- 
touch_repeat:		bcf	SIGNAL_TIMER_TOUCH_REPEAT
			movlw	TOUCH_REPEAT
			movwf   var_timer_touch_repeat	; Restart timer

			movf    setup_mode, w
			btfsc	SIGNAL_TOUCH_PLUS_LONG
			goto	setup_plus
			btfsc	SIGNAL_TOUCH_MINUS_LONG
			goto	setup_minus
			return
			
;--------------------------------------------------------- 
; Stop repeat on release
;--------------------------------------------------------- 
touch_repeat_stop:	clrf	var_timer_touch_repeat
			bcf	SIGNAL_TIMER_TOUCH_REPEAT
			bcf	SIGNAL_RELEASE_MINUS
			bcf	SIGNAL_RELEASE_PLUS
			bcf	SIGNAL_RELEASE_POWER

			movf    setup_mode, w
			btfsc	ZERO
			return	    ; If not in setup keep long press flags
				    ;   to make it easier to enter setup
			
			bcf	SIGNAL_TOUCH_PLUS_LONG
			bcf	SIGNAL_TOUCH_MINUS_LONG
			bcf	SIGNAL_TOUCH_POWER_LONG
			return

;--------------------------------------------------------- 
; Enter setup if + and - touched
;--------------------------------------------------------- 
touch_enter_setup:	btfss	SIGNAL_TOUCH_PLUS_LONG
			return
			btfss	SIGNAL_TOUCH_MINUS_LONG
			return
			
			; Both touched
			bcf	SIGNAL_TOUCH_PLUS_LONG
			bcf	SIGNAL_TOUCH_MINUS_LONG

			call	display_day
;			btfss	FLAG_DISPLAY_ENABLE
;			call	display_on	; Switch on the display if off
			goto	setup_next

;--------------------------------------------------------- 
; Set target temperature
;--------------------------------------------------------- 
touch_disp_target_temp:	movf	target_temperature, w
			call	display_temperature

			bsf	FLAG_TEMPERATURE_CHANGED
			bsf	FLAG_RELAY_IMMEDIATE

			bcf	SIGNAL_TIMER_TARGET_TEMPERATURE
			movlw	TARGET_TEMPERATURE_TIMER
			movwf	var_timer_target_temp
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
