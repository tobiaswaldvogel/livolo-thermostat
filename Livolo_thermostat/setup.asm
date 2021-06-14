#include <xc.inc>
#include "global.inc"    

; Publish    
global	enter_setup, display_setup
global	touch_plus_setup, touch_minus_setup
global	chk_offset_range    
; Use    
global	display_on, display_decimal    
global	read_eeprom, write_eeprom   
global	valve_maint_calc
psect   code
    
;--------------------------------------------------------- 
; Advances to the next setup setting. Sequence:
;   Temperature offset
;   Delay for the actor (heating / cooling)
;   Temperature Unit (Celsius / Fahrenheit)
;   Valve maintenance days
;   Operation mode (heating / cooling)
;   Light sensor value (if present)
;   Light sensor theshold (if present)   
;--------------------------------------------------------- 
enter_setup:		call	display_setup_blank
			movf	setup_mode, w
			btfss	ZERO
			goto	enter_setup_offset
			; Switch to setup offset
			incf	setup_mode, f
			return

enter_setup_offset:	addlw	-1
			btfss	ZERO
			goto	enter_setup_delay
			; Save offset
			movf	temperature_offset, w
			addlw	16
			movwf	arg_0
			movlw	EE_TEMPERATURE_OFFSET
			call	write_eeprom
			; Switch to setup delay
			incf	setup_mode, f
			return
								
enter_setup_delay:	addlw	-1
			btfss	ZERO
			goto	enter_setup_unit
			; Save delay
			movf	relay_delay, w
			movwf	arg_0
			movlw	EE_RELAY_DELAY
			call	write_eeprom
			; Switch to setup unit
			incf	setup_mode, f
			return
				
enter_setup_unit:	addlw	-1
			btfss	ZERO
			goto	enter_setup_maintain
			
			; Save unit
			movlw	0
			btfsc	FLAG_FAHRENHEIT
			movlw	1
			movwf	arg_0
			movlw	EE_FAHRENHEIT
			call	write_eeprom
			; Switch to setup valve maintanance days
			incf	setup_mode, f
			return
			
enter_setup_maintain:	addlw	-1
			btfss	ZERO
			goto	enter_setup_op_mode
			; Save valve maintanance days
			movf	valve_maintain_days, w
			movwf	arg_0
			movlw	EE_VALVE_MAINTAIN
			call	write_eeprom
			call	valve_maint_calc    ; Update initialization value
			; Switch to setup operation mode
			incf	setup_mode, f
			return

enter_setup_op_mode:	addlw	-1
			btfss	ZERO
			goto	enter_setup_ls_val
			; Save operation mode
			movf	operation_mode, w
			addlw	-1		    ; mode < 1 => CARRY
			movlw	0
			btfss	CARRY
			movlw	OPERATION_MODE_COOLING
			movwf	arg_0
			movlw	EE_OPERATION_MODE
			call	write_eeprom
			; Switch to light sensor / End setup
			btfss	FLAG_ONEWIRE_RB6
			goto	leave_setup	    ; No light sensor
			incf	setup_mode, f
			return
			
enter_setup_ls_val:	addlw	-1
			btfss	ZERO
			goto	enter_setup_ls

			; Display the light sensor value
			incf	setup_mode, f
			return

enter_setup_ls:		; Save light sensor limit
			movf	light_sensor_limit, w
			movwf	arg_0
			movlw	EE_LIGHT_SENSOR
			call	write_eeprom
			goto	leave_setup
    
leave_setup:		clrf	setup_mode, f
			bsf	FLAG_TEMPERATURE_CHANGED    ; Refresh temperature
			bsf	FLAG_RELAY_IMMEDIATE	    ; and timers
			goto	display_on

;--------------------------------------------------------- 
; Display setup values
;--------------------------------------------------------- 
display_setup:		movf	timer50hz, w
			addlw	-10
			btfss	CARRY
			goto	display_setup_blank

			decf	setup_mode, w
			btfss	ZERO
			goto	display_setup_delay

			; Display offset
			movlw   0fh	; Invalid BCD for blanking digit
			btfsc   temperature_offset, 7
			goto    display__setup_off_neg

			movwf   disp_l;	; Positive value => left invalid
			movf    temperature_offset, w
			movwf	disp_r
			return

display__setup_off_neg:	movwf   disp_r;	; Negative value >= right invalid
			movf    temperature_offset, w
			xorlw	0xff		; 2 complement
			addlw	0x01
			movwf	disp_l
			return

display_setup_delay:	addlw	-1
			btfss	ZERO
			goto	display_setup_unit

			; Display relay delay
			movf	relay_delay, w
			call	display_decimal
			return

display_setup_unit:	addlw	-1
			btfss	ZERO
			goto	display_setup_maintain

			; Display unit
			btfss   FLAG_FAHRENHEIT
			bsf	LED_CELSIUS
			btfsc   FLAG_FAHRENHEIT
			bsf	LED_FAHRENHEIT
			return

display_setup_maintain:	addlw	-1
			btfss	ZERO
			goto	display_setup_op_mode

			; Display valve maintenance days + LED Celsius
			bsf	LED_CELSIUS
			movf	valve_maintain_days, w
			call	display_decimal
			return

display_setup_op_mode:	addlw	-1
			btfss	ZERO
			goto	display_setup_ls_val

			; Display operation mode + LED Fahrenheit
			bsf	LED_FAHRENHEIT
			movlw	0fh
			movwf	disp_l			; blank left digit
			movf	operation_mode, w
			movwf	disp_r
			return
			
display_setup_ls_val:	addlw	-1
			btfss	ZERO
			goto	display_setup_ls

			; Display light sensor value
			bsf	LED_FAHRENHEIT
			bsf	LED_CELSIUS
			movf	light_sensor_value, w
			call	display_decimal
			return

display_setup_ls:	; Display light sensor limit
			movf	light_sensor_limit, w
			call	display_decimal
			return

display_setup_blank:	movlw	0fh
			movwf	disp_l
			movwf	disp_r
			bcf	LED_CELSIUS
			bcf	LED_FAHRENHEIT
			return

;--------------------------------------------------------- 
; Touch '+' in setup
;--------------------------------------------------------- 
touch_plus_setup:	addlw	-1		
			btfss	ZERO
			goto	touch_plus_setup_delay
			; Offset
			incf	temperature_offset, f
			movf	temperature_offset, w
			call	chk_offset_range			
			movlw	9		; Max value
			btfss	CARRY
			movwf	temperature_offset  ; Set to max if out of range
			return
			
touch_plus_setup_delay:	addlw	-1
			btfss	ZERO
			goto	touch_plus_setup_unit
			; Relay delay
			incf	relay_delay, f
			movf	relay_delay, w
			sublw	RELAY_DELAY_MAX
			movlw	RELAY_DELAY_MAX	; Max value
			btfss	CARRY
			movwf	relay_delay	; Set to max if out of range
			return
			
touch_plus_setup_unit:	addlw	-1		; Check for SETUP_DELAY
			btfss	ZERO
			goto	touch_plus_maintain

			btfss	FLAG_FAHRENHEIT
			goto	touch_plus_setup_f
			
			bcf	FLAG_FAHRENHEIT
			return
touch_plus_setup_f:	bsf	FLAG_FAHRENHEIT
			return

touch_plus_maintain:	addlw	-1
			btfss	ZERO
			goto	touch_plus_op_mode
			; Valve maintance days
			incf	valve_maintain_days, f
			movf	valve_maintain_days, w
			sublw	VALVE_MAINTAIN_MAX
			movlw	VALVE_MAINTAIN_MAX  ; Max value
			btfss	CARRY
			movwf	valve_maintain_days ; Set to max if out of range
			return

touch_plus_op_mode:	addlw	-1
			btfss	ZERO
			goto	touch_plus_setup_ls
			; Operation mode
			incf	operation_mode, f
			movf	operation_mode, w
			sublw	OPERATION_MODE_MAX
			movlw	OPERATION_MODE_MAX
			btfss	CARRY
			movwf	operation_mode	    ; Set to max if out of range
			return
			
touch_plus_setup_ls:	addlw	-1		; Check for SETUP_DELAY
			btfsc	ZERO
			return			; Display value only
			
			; Light sensor 
			incf	light_sensor_limit, f
			movf	light_sensor_limit, w
			sublw	LIGHT_SENSOR_MAX
			movlw	LIGHT_SENSOR_MAX    ; Max value
			btfss	CARRY		    ;Set to max if out of range
			movwf	light_sensor_limit
			return

;--------------------------------------------------------- 
; Touch '-' in setup
;--------------------------------------------------------- 
touch_minus_setup:	addlw	-1
			btfss	ZERO
			goto	touch_minus_setupdelay
			; Offset
			decf	temperature_offset, f
			movf	temperature_offset, w
			call	chk_offset_range			
			movlw	-9
			btfss	CARRY
			movwf	temperature_offset  ; Set to min if out of range
			return

touch_minus_setupdelay:	addlw	-1
			btfss	ZERO
			goto	touch_minus_setup_unit
			; Relay delay
			decf	relay_delay, f
			movf	relay_delay, w
			sublw	RELAY_DELAY_MAX	; Check range 0 .. 99
			btfss	CARRY
			clrf	relay_delay	; Default 0
			return

touch_minus_setup_unit:	addlw	-1		; Check for SETUP_LS
			btfss	ZERO
			goto	touch_minus_maintain

			btfss	FLAG_FAHRENHEIT
			goto	touch_minus_setup_f
			
			bcf	FLAG_FAHRENHEIT
			return
touch_minus_setup_f:	bsf	FLAG_FAHRENHEIT
			return
			
touch_minus_maintain:	addlw	-1
			btfss	ZERO
			goto	touch_minus_op_mode
			; Valve maintance days
			decf	valve_maintain_days, f
			movf	valve_maintain_days, w
			sublw	VALVE_MAINTAIN_MAX
			btfss	CARRY
			clrf	valve_maintain_days
			return

touch_minus_op_mode:	addlw	-1
			btfss	ZERO
			goto	touch_minus_setup_ls
			; Operation mode
			decf	operation_mode, f
			movf	operation_mode, w
			sublw	OPERATION_MODE_MAX
			btfss	CARRY
			clrf	operation_mode
			return

touch_minus_setup_ls:	addlw	-1
			btfsc	ZERO
			return			; Display value only

			; Light sensor
			decf	light_sensor_limit, f
			movf	light_sensor_limit, w
			sublw	LIGHT_SENSOR_MAX	; Check range
			btfss	CARRY
			clrf	light_sensor_limit	; Default 0
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
		