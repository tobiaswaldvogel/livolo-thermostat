#include <xc.inc>
#include "global.inc"    

psect   code

; Publish    
global	timer_target_temp
global	timer_relay_stop, timer_relay_start
global  timer_valve_maint_strt, timer_valve_maint_stop, timer_valve_maint
global  valve_maint_calc   
global	timer_adc
global  timer_set_night_disable, timer_night_disable
; Use
global	display_temperature, display_unit, display_decimal
global  display_day, display_night
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
			call	display_unit
			movf	current_temperature, w
			goto	display_temperature
    
;--------------------------------------------------------- 
; Start valve delay timer
;--------------------------------------------------------- 
timer_relay_stop:	bcf	GIE
			clrf	var_timer_relay		; Stop timer
			clrf	var_timer_relay + 1
			bsf	GIE
			return

;--------------------------------------------------------- 
; Start valve delay timer  unit 1s
;--------------------------------------------------------- 
timer_relay_start:	bcf	GIE
			movf	var_timer_relay, w
			iorwf	var_timer_relay + 1, w
			btfss	ZERO
			goto	timer_relay_start_ret	; Already running

			; Start timer with relay_delay * 10s
			clrf	var_timer_relay + 1	; Clear MSB
			bcf	CARRY
			rlf	relay_delay, w		; Max 99 < 128 => no carry
			movwf	var_timer_relay		; * 2
			rlf	var_timer_relay, f	; * 4
			rlf	var_timer_relay + 1, f
			rlf	var_timer_relay, f	; * 8
			rlf	var_timer_relay + 1, f
			rlf	relay_delay, w		; Max 99 < 128 => no carry
			addwf	var_timer_relay, f	; LSB = * ( 8 + 2) = * 10
			btfsc	CARRY
			incf	var_timer_relay + 1, f	; Carry
			
timer_relay_start_ret:	bsf	GIE
			return

;--------------------------------------------------------- 
; Stop valve maintenance timer
;--------------------------------------------------------- 
timer_valve_maint_stop:	bcf	GIE
			clrf	var_timer_valve_maint	; Stop timer
			clrf	var_timer_valve_maint + 1
			clrf	var_timer_valve_maint + 2
			bsf	GIE
			return

;--------------------------------------------------------- 
; Calculate value for valve maintenance timer
;--------------------------------------------------------- 
UNITS_PER_DAY		equ	60 * 60 * 24
mult_days		equ	arg_7
		
valve_maint_calc:	clrf	var_timer_valve_maint_set
			clrf	var_timer_valve_maint_set + 1
			clrf	var_timer_valve_maint_set + 2
			
			; Multiplicant 1
			movlw	(UNITS_PER_DAY & 0ffh)
			movwf	timer_valve_maint_mult
			movlw	((UNITS_PER_DAY >> 8) & 0ffh)
			movwf	timer_valve_maint_mult + 1
			movlw	((UNITS_PER_DAY >> 16) & 0ffh)
			movwf	timer_valve_maint_mult + 2
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
			
valve_maint_calc_next:	movf	mult_days, w		; Still bits left?
			btfsc	ZERO
			return

			bcf CARRY
			rlf	timer_valve_maint_mult
			rlf	timer_valve_maint_mult + 1
			rlf	timer_valve_maint_mult + 2
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
			bsf	GIE
			call	set_relay_on	; Open valve
			return
    
;--------------------------------------------------------- 
; Timer for light sensor ADC
;--------------------------------------------------------- 
timer_adc:		bcf	SIGNAL_TIMER_ADC
			movlw	98			; Default value if out of range
			movwf	light_sensor_value

			;           ------                        -----
			;  Vcc ----|  5K  |----- RB4 (AN10)  ----| LDR |----- Vss
			;           ------                        -----
			
			movf	ADRESH, w		; 0 .. 255 (0 brightest)
			addlw	98			; C if the darkest 98 values
			btfss	CARRY
			goto	timer_adc_check_mode
			sublw	98			; Translate 0..97 to 98..1
			movwf	light_sensor_value	; For display in setup

timer_adc_check_mode:	movf	light_sensor_value, w	; Might be the default value
			subwf	light_sensor_limit, w 	; C  <=  light_sensor_limit
			btfsc	CARRY			
			goto	timer_adc_night_mode
			
timer_adc_day_mode:	btfss	FLAG_NIGHT_MODE
			goto	timer_adc_clear_cntr	; Already in day mode
			goto	timer_adc_settle

timer_adc_night_mode:	btfsc	FLAG_NIGHT_MODE
			goto	timer_adc_clear_cntr	; Already in night mode

timer_adc_settle:	incf	light_sensor_counter, f
			movf	light_sensor_counter, w
			sublw	ADC_SETTLE		; Wait for at least ADC_SETTLE readings
			btfsc	CARRY
			goto	timer_adc_next

			btfsc	FLAG_STANDBY
			goto	timer_adc_clear_cntr	; Skip in stand-by
			btfss	FLAG_NIGHT_MODE_AUTOMATIC
			goto	timer_adc_clear_cntr	; Skip if not automatic
			
			movf	setup_mode, w
			btfss	ZERO
			goto	timer_adc_clear_cntr	; Skip in setup

			btfsc	FLAG_NIGHT_MODE
			goto	timer_adc_leave_night

			bsf	FLAG_NIGHT_MODE
			call	display_night
			goto	timer_adc_clear_cntr

timer_adc_leave_night:	bcf	FLAG_NIGHT_MODE
			call	display_day

timer_adc_clear_cntr:   clrf	light_sensor_counter
			
timer_adc_next:		bsf	ADCON0, ADCON0_GO_nDONE_POSN
			movlw	ADC_TIMER_RELOAD
			movwf	var_timer_adc
			return

;--------------------------------------------------------- 
; Start timer before the light sensor can switch off the display
;--------------------------------------------------------- 
timer_set_night_disable:
			bcf	FLAG_NIGHT_MODE_AUTOMATIC
			movlw	KEEP_DISPLAY_ON
			movwf	var_timer_night_disable
			return			
;--------------------------------------------------------- 
; Timer for keeping display on after touch event
;--------------------------------------------------------- 
timer_night_disable:	bcf	SIGNAL_TIMER_NIGHT_DISABLE
			bsf	FLAG_NIGHT_MODE_AUTOMATIC
			return