#include <xc.inc>
#include "global.inc"    

psect   code

; Publish    
global	timer_target_temp
global	timer_relay_stop, timer_relay_start
global  timer_valve_maint_strt, timer_valve_maint_stop, timer_valve_maint
global  valve_maint_calc   
global	timer_adc, timer_keep_displ_on   
; Use
global	display_temperature, display_decimal, display_on, display_off
global	read_eeprom, write_eeprom  
global	set_relay_on   

;--------------------------------------------------------- 
; Timer inactivity
;--------------------------------------------------------- 
timer_target_temp:	bcf	SIGNAL_TIMER_TARGET_TEMPERATURE
			; Save new target temperature to EEPROM
			movf	target_temperature, w
			movwf	arg_0
			movlw	EE_TARGET_TEMPERATURE
			call	write_eeprom
			
			; Display current temperature again
			movf	current_temperature, w
			call	display_temperature
			goto	display_on		; Restore Unit
    
;--------------------------------------------------------- 
; Start valve delay timer
;--------------------------------------------------------- 
timer_relay_stop:	bcf	GIE
			clrf	var_timer_relay		; Stop timer
			clrf	var_timer_relay + 1
			clrf	var_timer_relay + 2
			bsf	GIE
			return

;--------------------------------------------------------- 
; Start valve delay timer
;
; unit = 20 ms * (valve_delay << 9 )
;      = 1024 0ms * valve_delay
;      ~ 10 sec * valve_delay			
;--------------------------------------------------------- 
timer_relay_start:	bcf	GIE
			movf	var_timer_relay, w
			iorwf	var_timer_relay + 1, w
			iorwf	var_timer_relay + 2, w
			btfss	ZERO
			goto	timer_relay_start_ret	; Already running

			; Start timer
			clrf	var_timer_relay
			clrf	var_timer_relay + 2
			bcf	CARRY
			rlf	relay_delay, w
			movwf	var_timer_relay + 1
			rlf	var_timer_relay + 2
			
timer_relay_start_ret:	bsf	GIE
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
; Calculate value for valve maintenance timer
;--------------------------------------------------------- 
UNITS_PER_DAY		equ	50 * 60 * 60 * 24
mult_days		equ	arg_7
		
valve_maint_calc:	clrf	var_timer_valve_maint_set
			clrf	var_timer_valve_maint_set + 1
			clrf	var_timer_valve_maint_set + 2
			clrf	var_timer_valve_maint_set + 3
			
			; Multiplicant 1
			movlw	(UNITS_PER_DAY & 0ffh)
			movwf	timer_valve_maint_mult
			movlw	((UNITS_PER_DAY >> 8) & 0ffh)
			movwf	timer_valve_maint_mult + 1
			movlw	((UNITS_PER_DAY >> 16) & 0ffh)
			movwf	timer_valve_maint_mult + 2
			movlw	((UNITS_PER_DAY >> 24) & 0ffh)
			movwf	timer_valve_maint_mult + 3
			; Multiplicant 2
			movf	valve_maintain_days, w
			movwf	mult_days
			
valve_maint_calc_loop:	bcf	CARRY
			rrf	mult_days, f		; LSB -> Carry
			btfss	CARRY
			goto	valve_maint_calc_next	; Bit not set => don't add

			; Byte 0
			movf	timer_valve_maint_mult, w
			addwf	var_timer_valve_maint_set, f
			; Byte 1
			movf	timer_valve_maint_mult + 1, w
			btfsc	CARRY
			incfsz	timer_valve_maint_mult + 1, w	; Add Carry, if zero carry next byte
			addwf	var_timer_valve_maint_set + 1, f
			; Byte 2
			movf	timer_valve_maint_mult + 2, w
			btfsc	CARRY
			incfsz	timer_valve_maint_mult + 2, w	; Add Carry, if zero carry next byte
			addwf	var_timer_valve_maint_set + 2, f
			; Byte 3
			movf	timer_valve_maint_mult + 3, w
			btfsc	CARRY
			incfsz	timer_valve_maint_mult + 3, w	; Add Carry, if zero carry next byte
			addwf	var_timer_valve_maint_set + 3, f
			
valve_maint_calc_next:	movf	mult_days, w		; Still bits left?
			btfsc	ZERO
			return

			bcf CARRY
			rlf	timer_valve_maint_mult
			rlf	timer_valve_maint_mult + 1
			rlf	timer_valve_maint_mult + 2
			rlf	timer_valve_maint_mult + 3
			goto	valve_maint_calc_loop

;--------------------------------------------------------- 
; Start valve maintenance timer
;--------------------------------------------------------- 
timer_valve_maint_strt:	bcf	GIE
			movf	var_timer_valve_maint_set, w
			movwf	var_timer_valve_maint
			movf	var_timer_valve_maint_set + 1, w
			movwf	var_timer_valve_maint + 1
			movf	var_timer_valve_maint_set + 2, w
			movwf	var_timer_valve_maint + 2
			movf	var_timer_valve_maint_set + 3, w
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
			movwf	var_timer_relay
			movlw	((VALVE_MAINTENANCE_OPEN >> 8) & 0ffh)
			movwf	var_timer_relay + 1
			movlw	((VALVE_MAINTENANCE_OPEN >> 16) & 0ffh)
			movwf	var_timer_relay + 2
			bsf	GIE
			call	set_relay_on	; Open valve
			return

    
;--------------------------------------------------------- 
; Timer for light sensor ADC
;--------------------------------------------------------- 
timer_adc:		bcf	SIGNAL_TIMER_ADC
			movlw	99
			movwf	light_sensor_value	; For display in setup

			movf	ADRESH, w
			addlw	- (255 - 98)
			btfss	CARRY
			goto	day_mode		; > 255 - 98 => on

			sublw	99			; 1 .. 99
			movwf	light_sensor_value	; For display in setup
			subwf	light_sensor_limit, w
			btfsc	CARRY			; cc -> > light_sensor_limit
			goto	night_mode

day_mode:		btfss	FLAG_NIGHT_MODE
			goto	timer_adc_clear_cntr	; Already in day mode
			incf	light_sensor_counter, f
			movf	light_sensor_counter, w
			sublw	5			; Wait for at least 5 readings
			btfsc	CARRY
			goto	timer_adc_next

			clrf	light_sensor_counter
			btfsc	FLAG_STANDBY
			goto	timer_adc_next		; Skip in stand-by
			btfsc	FLAG_DISPLAY_OFF
			goto	timer_adc_next		; Skip if manually switched off

			bcf	FLAG_NIGHT_MODE
			btfss	FLAG_DISPLAY_ENABLE
			call	display_on
			goto	timer_adc_next
			
night_mode:		btfsc	FLAG_KEEP_DISPLAY_ON
			goto	timer_adc_next
			btfsc	FLAG_NIGHT_MODE
			goto	timer_adc_clear_cntr	; Already in night mode
			incf	light_sensor_counter, f
			movf	light_sensor_counter, w
			sublw	5			; Wait for at least 5 readings
			btfsc	CARRY
			goto	timer_adc_next
			
			clrf	light_sensor_counter
			movf	setup_mode, w
			btfss	ZERO
			goto	timer_adc_next		; Skip in setup
			
			bsf	FLAG_NIGHT_MODE
			btfsc	FLAG_DISPLAY_ENABLE	; Switch display off if on
			call	display_off
			goto	timer_adc_next

timer_adc_clear_cntr:   clrf	light_sensor_counter
			
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