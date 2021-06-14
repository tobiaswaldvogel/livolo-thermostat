#include <xc.inc>
#include "global.inc"    

psect   code

; Publish    
global	display_temperature, display_decimal, display_on, display_off

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
			bsf	arg_0, 3
			btfss	CARRY
			addlw	80
			
			addlw	-40	; >= 40 -> Carry
			btfsc	CARRY
			bsf	arg_0, 2
			btfss	CARRY
			addlw	40
			
			addlw	-20	; >= 20 -> Carry
			btfsc	CARRY
			bsf	arg_0, 1
			btfss	CARRY
			addlw	20
			
			addlw	-10	; >= 10 -> Carry
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
    
			btfsc	RELAY		; Relay active ?
			goto	display_on_relay
			bsf	RP0
			bsf	LED_POWER	; TRIS -> input
			bcf	RP0		; => lit + blue led
			return
			
display_on_relay:	bsf	RP0
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
