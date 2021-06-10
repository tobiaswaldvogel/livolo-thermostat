#include <xc.inc>
#include "global.inc"    

psect   code

; Publish    
global	timer_inactivity
global	timer_valve_stop, timer_valve_start
global  timer_valve_maint_strt, timer_valve_maint_stop, timer_valve_maint
global	timer_adc, timer_keep_displ_on   
; Use
global	display_temperature, display_decimal, display_on, display_off
global	read_eeprom, write_eeprom  
global	set_valve_on   

;--------------------------------------------------------- 
; Timer inactivity
;--------------------------------------------------------- 
timer_inactivity:	bcf	SIGNAL_TIMER_INACTIVITY
			; Save new target temperature to EEPROM
			movf	target_temperature, w
			movwf	arg_0
			movlw	EE_TARGET_TEMPERATURE
			call	write_eeprom
			
			; Display current temperature again
			movf	current_temperature, w
			goto	display_temperature
    
;--------------------------------------------------------- 
; Start valve delay timer
;--------------------------------------------------------- 
timer_valve_stop:	bcf	GIE
			clrf	var_timer_valve	; Stop timer
			clrf	var_timer_valve + 1
			clrf	var_timer_valve + 2
			bsf	GIE
			return

;--------------------------------------------------------- 
; Start valve delay timer
;
; unit = 20 ms * (valve_delay << 9 )
;      = 1024 0ms * valve_delay
;      ~ 10 sec * valve_delay			
;--------------------------------------------------------- 
timer_valve_start:	bcf	GIE
			movf	var_timer_valve, w
			iorwf	var_timer_valve + 1, w
			iorwf	var_timer_valve + 2, w
			btfss	ZERO
			goto	timer_valve_start_ret	; Already running

			; Start timer
			clrf	var_timer_valve
			clrf	var_timer_valve + 2
			bcf	CARRY
			rlf	valve_delay, w
			movwf	var_timer_valve + 1
			rlf	var_timer_valve + 2
			
timer_valve_start_ret:	bsf	GIE
			return

;--------------------------------------------------------- 
; Stop valve maintenance timer
;--------------------------------------------------------- 
timer_valve_maint_stop:	bcf	GIE
			clrf	var_timer_valve_maint	; Stop timer
			clrf	var_timer_valve_maint + 1
			clrf	var_timer_valve_maint + 2
			clrf	var_timer_valve_maint + 3
			bsf	GIE
			return

;--------------------------------------------------------- 
; Start valve maintenance timer
;--------------------------------------------------------- 
timer_valve_maint_strt:	bcf	GIE
			movlw	(VALVE_MAINTENANCE & 0ffh)
			movwf	var_timer_valve_maint
			movlw	((VALVE_MAINTENANCE >> 8) & 0ffh)
			movwf	var_timer_valve_maint + 1
			movlw	((VALVE_MAINTENANCE >> 16) & 0ffh)
			movwf	var_timer_valve_maint + 2
			movlw	((VALVE_MAINTENANCE >> 24) & 0ffh)
			movwf	var_timer_valve_maint + 3
			bsf	GIE
			return

;--------------------------------------------------------- 
; Valve maintenance timer
;--------------------------------------------------------- 
timer_valve_maint:	btfsc	FLAG_NIGHT_MODE
			return			; Wait for the end of the night mode
			bcf	SIGNAL_TIMER_VALVE_MAINTAIN
			bcf	GIE
			; Restore state with timer valve
			movlw	(VALVE_MAINTENANCE_OPEN & 0ffh)
			movwf	var_timer_valve
			movlw	((VALVE_MAINTENANCE_OPEN >> 8) & 0ffh)
			movwf	var_timer_valve + 1
			movlw	((VALVE_MAINTENANCE_OPEN >> 16) & 0ffh)
			movwf	var_timer_valve + 2
			bsf	GIE
			call	set_valve_on	; Open valve
			return

    
;--------------------------------------------------------- 
; Timer for light sensor ADC
;--------------------------------------------------------- 
timer_adc:		bcf	SIGNAL_TIMER_ADC

			
#if 0
			bcf	FLAG_NIGHT_MODE
			clrf	light_sensor_value

			movf	ADRESH, w
			addlw	- (255 - 98)
			btfss	CARRY
			goto	timer_adc_check_disp	; > 255 - 98 => on
			movwf	light_sensor_value	; For display in setup
			subwf	light_sensor_limit, w
			btfss	CARRY			; C => <= light_sensor_limit
			bsf	FLAG_NIGHT_MODE			
#endif
			
#if 0
			bcf	FLAG_NIGHT_MODE
			movlw	99
			movwf	light_sensor_value

			btfss	ADRESH, 7		; Skip if low value => very bright
			goto	timer_adc_check_disp

			bsf	RP0
			rlf	ADRESL, w
			bcf	RP0
			rlf	ADRESH, w		

			btfsc	ZERO
			goto	timer_adc_check_disp
			
			xorlw	0ffh
			addlw	1
			sublw	99
			btfss	CARRY
			goto	timer_adc_check_disp

			sublw	99
			movwf	light_sensor_value	; For display in setup
			
#endif
			
#if 1
			bcf	FLAG_NIGHT_MODE
			movlw	99
			movwf	light_sensor_value

			movf	ADRESH, w
			addlw	- (255 - 98)
			btfss	CARRY
			goto	timer_adc_check_disp	; > 255 - 98 => on

			sublw	99			; 1 .. 99
			movwf	light_sensor_value	; For display in setup
			subwf	light_sensor_limit, w
			btfsc	CARRY			; cc -> > light_sensor_limit
			bsf	FLAG_NIGHT_MODE
#endif			
timer_adc_check_disp:	btfsc	FLAG_KEEP_DISPLAY_ON
			goto	timer_adc_next
			movf	setup_mode, w
			btfss	ZERO
			goto	timer_adc_next		; Skip in setup
			btfsc	FLAG_STANDBY
			goto	timer_adc_next		; Skip in stand-by
			btfsc	FLAG_DISPLAY_OFF
			goto	timer_adc_next		; Skip if manually switched off
			
			btfss	FLAG_NIGHT_MODE
			goto	timer_adc_disp_on
			
			; Switch display off
			btfsc	FLAG_DISPLAY_ENABLE	; Switch display off if on
			call	display_off
			goto	timer_adc_next
			
			; Switch display on
timer_adc_disp_on:  	btfss	FLAG_DISPLAY_ENABLE
			call	display_on
			
timer_adc_next:		bsf	ADCON0, ADCON0_GO_nDONE_POSN
			movlw	ADC_TIMER_RELOAD
			movwf	var_timer_adc
			return

;--------------------------------------------------------- 
; Timer for keeping display on after touch event
;--------------------------------------------------------- 
timer_keep_displ_on:	bcf	SIGNAL_TIMER_KEEP_DISPLAY_ON
			bcf	FLAG_KEEP_DISPLAY_ON
			return