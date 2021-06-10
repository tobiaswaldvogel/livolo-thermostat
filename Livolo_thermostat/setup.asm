#include <xc.inc>
#include "global.inc"    

; Publish    
global	enter_setup  
; Use    
global	display_on    
global read_eeprom, write_eeprom   
global display_setup_blank    

psect   code
    
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
			movf	valve_delay, w
			movwf	arg_0
			movlw	EE_VALVE_DELAY
			call	write_eeprom
			; Switch to setup unit
			incf	setup_mode, f
			return
				
enter_setup_unit:	addlw	-1
			btfss	ZERO
			goto	enter_setup_ls_val
			
			; Save unit
			movlw	0
			btfsc	FLAG_FAHRENHEIT
			movlw	1
			movwf	arg_0
			movlw	EE_FAHRENHEIT
			call	write_eeprom

			; End setup
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
			movlw	0ffh
			movwf	current_temperature ; Refresh temperature
			goto	display_on