#include <xc.inc>
#include "global.inc"    

psect   code

; Publish    
global	display_temperature, display_setup, display_setup_blank
global	display_decimal, display_on, display_off

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

			; Display valve delay
			movf	valve_delay, w
			call	display_decimal
			return

display_setup_unit:	addlw	-1
			btfss	ZERO
			goto	display_setup_ls_val

			; Display unit
			btfss   FLAG_FAHRENHEIT
			bsf	LED_CELSIUS
			btfsc   FLAG_FAHRENHEIT
			bsf	LED_FAHRENHEIT
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
; Display temperature in w
;--------------------------------------------------------- 
display_temperature:	btfsc	FLAG_FAHRENHEIT
			goto	display_temperature_f
			movwf	arg_0
			bcf	CARRY
			rrf	arg_0, w    ; Divide by 2 if Celsius
			goto	display_decimal

display_temperature_f:  sublw	FAHRENHEIT_MAX
			btfss	CARRY	; C => <= FAHRENHEIT_MAX
			movlw	0	; Limit to FAHRENHEIT_MAX - 0
			sublw	FAHRENHEIT_MAX	; Restore value before
			goto	display_decimal
			
;--------------------------------------------------------- 
; Display decimal number in w
;--------------------------------------------------------- 
display_decimal:	clrf	arg_0
			
			addlw	-80	; => Carry set if if >= 80
			btfsc	CARRY
			bsf	arg_0, 3
			btfss	CARRY
			addlw	80
			
			addlw	-40	; => Carry set if if >= 40
			btfsc	CARRY
			bsf	arg_0, 2
			btfss	CARRY
			addlw	40
			
			addlw	-20	; => Carry set if if >= 20
			btfsc	CARRY
			bsf	arg_0, 1
			btfss	CARRY
			addlw	20
			
			addlw	-10	; => Carry set if if >= 10
			btfsc	CARRY
			bsf	arg_0, 0
			btfss	CARRY
			addlw	10
			
			movwf	disp_r
			movf	arg_0, w
			movwf	disp_l
			return
			
;--------------------------------------------------------- 
; Display on
;--------------------------------------------------------- 
display_on:		bsf	FLAG_DISPLAY_ENABLE
			btfsc	FLAG_FAHRENHEIT
			bcf	LED_CELSIUS
			btfss	FLAG_FAHRENHEIT
			bsf	LED_CELSIUS
			btfsc	FLAG_FAHRENHEIT
			bsf	LED_FAHRENHEIT
			btfss	FLAG_FAHRENHEIT
			bcf	LED_FAHRENHEIT
    
			btfsc	VALVE		; Ventil offen ?
			goto	display_on_valve
			bsf	RP0
			bsf	LED_POWER	; TRIS -> input
			bcf	RP0		; => lit + blue led
			return
			
display_on_valve:	bsf	RP0
			bcf	LED_POWER	; TRIS -> output
			bcf	RP0
			bsf	LED_POWER	; => lit + red led
			return

;--------------------------------------------------------- 
; Display off
;--------------------------------------------------------- 
display_off:		bcf	FLAG_DISPLAY_ENABLE
			bcf	DISP_LEFT
			bcf	DISP_RIGHT
			bcf	LED_CELSIUS
			bcf	LED_FAHRENHEIT
			bsf	RP0
			bcf	LED_POWER	; TRIS -> output
			bcf	RP0
			bcf	LED_POWER	; => only blue led
			return
			