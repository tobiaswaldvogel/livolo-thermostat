#include <xc.inc>
#include "global.inc"    

psect   code

; Publish    
global	display_temperature, display_decimal, display_unit
global  display_day, display_night, disp_set_brightness   

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
			btfss	CARRY	; <= FAHRENHEIT_MAX -> Carry
			movlw	0	; Limit to FAHRENHEIT_MAX - 0
			sublw	FAHRENHEIT_MAX	; Restore value before
			goto	display_decimal
			
;--------------------------------------------------------- 
; Display decimal number in w
;--------------------------------------------------------- 
display_decimal:	clrf	arg_0
			
			addlw	-80	; >= 80 -> Carry
			btfsc	CARRY
			bsf	arg_0, 7
			btfss	CARRY
			addlw	80
			
			addlw	-40	; >= 40 -> Carry
			btfsc	CARRY
			bsf	arg_0, 6
			btfss	CARRY
			addlw	40
			
			addlw	-20	; >= 20 -> Carry
			btfsc	CARRY
			bsf	arg_0, 5
			btfss	CARRY
			addlw	20
			
			addlw	-10	; >= 10 -> Carry
			btfsc	CARRY
			bsf	arg_0, 4
			btfss	CARRY
			addlw	10
			
			iorwf	arg_0, w
			movwf	display_bcd
			return

;--------------------------------------------------------- 
; Set bightness to day
;--------------------------------------------------------- 
display_day:		movf	brightness, w
			goto	disp_set_brightness

;--------------------------------------------------------- 
; Set brightness to night
;--------------------------------------------------------- 
display_night:		movf	brightness_night, w			

			; Set brightness to W * 4
disp_set_brightness:	movwf	arg_0
			bcf	CARRY
			rlf	arg_0	    ; * 2
			rlf	arg_0	    ; * 4
			movf	arg_0, w
			movwf	disp_brightness
			return

;--------------------------------------------------------- 
; Set unit LEDs
;--------------------------------------------------------- 
display_unit:		btfsc	FLAG_FAHRENHEIT
			goto	display_unit_f
			bsf	LED_CELSIUS
			bcf	LED_FAHRENHEIT
			return

display_unit_f:		bcf	LED_CELSIUS
			bsf	LED_FAHRENHEIT
			return
		