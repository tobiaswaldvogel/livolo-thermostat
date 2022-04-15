#include <xc.inc>
#include "global.inc"

global write_eeprom, read_eeprom

psect code

;--------------------------------------------------------- 
; Write EEPROM	w = address INDF value
;--------------------------------------------------------- 
write_eeprom:		bcf	RP0
			bsf	RP1	; bank 2
			movwf	EEADR
			movf	arg_0, w
			movwf	EEDAT
			bcf	GIE	; Disable int
			bsf	RP0	; bank 3
			bsf	WREN	; Enable write
			movlw	55h	; Magic 55 aa
			movwf	EECON2
			movlw	0aah
			movwf	EECON2
			bsf	WR
			bcf	WREN	; Disable write
			bsf	GIE	; Re-enable int
			bcf	RP0
			bcf	RP1
			return

;--------------------------------------------------------- 
; Read EEPROM  w = address			
;--------------------------------------------------------- 
read_eeprom:		bcf	RP0
			bsf	RP1	; bank 2
			movwf	EEADR
			bsf	RP0	; bank 3
			bsf	RD
			bcf	RP0	; bank 2
			movf	EEDAT, w
			bcf	RP1	; bank 0
			return

			
#ifdef DEBUG

global display_decimal
global toggle_f_led, debug_output    
			
;--------------------------------------------------------- 
; Toggle Fahrenheit indicator for debugging
;--------------------------------------------------------- 
toggle_f_led:		btfss	LED_FAHRENHEIT
			goto	set_f_led
			bcf	LED_FAHRENHEIT
			return
set_f_led:		bsf	LED_FAHRENHEIT    
			return

;--------------------------------------------------------- 
; Output of 4 digit hex for debug purpose
;
; Sample usage:
; #ifdef DEBUG			
; movf var_debug_out_ctrl, w   ; Check if still output of value before
; btfss ZERO
; goto deb_end		    
;		    
; movlw	    12h
; movwf     var_debug	       ; Low byte
; movlw     34h
; movwf     var_debug + 1      ; High byte
;
; movlw	    5		       ; Activate output
; movwf	    var_debug_out_ctrl		    
; deb_end:		    
; #endif			
;			
;--------------------------------------------------------- 
debug_output:		movf	var_debug_out_ctrl, w
			btfsc	ZERO
			return				; Zero => done

			subwf	var_timer_125hz, w
			btfss	ZERO
			return
			
			movf	var_debug_out_ctrl, w
			decf	var_debug_out_ctrl, f
			
debug_output_done:	addlw	-1
			btfss	ZERO
			goto	debug_output_1
			clrf	var_debug_out_ctrl	; Indicate done
			return
			
debug_output_1:		addlw	-1
			btfss	ZERO
			goto	debug_output_2
			; Digit 1
			movf	var_debug, w
			andlw	0fh
			bcf	LED_FAHRENHEIT
			bcf	LED_CELSIUS
			goto	display_decimal
			
debug_output_2:		addlw	-1
			btfss	ZERO
			goto	debug_output_3
			; Digit 2
			swapf	var_debug, w
			andlw	0fh
			bcf	LED_FAHRENHEIT
			bsf	LED_CELSIUS
			goto	display_decimal
			
debug_output_3:		addlw	-1
			btfss	ZERO
			goto	debug_output_4
			; Digit 3
			movf	var_debug + 1, w
			andlw	0fh
			bsf	LED_FAHRENHEIT
			bcf	LED_CELSIUS
			goto	display_decimal
			
			; digit 4
debug_output_4:		swapf	var_debug + 1, w
			andlw	0fh
			bsf	LED_FAHRENHEIT
			bsf	LED_CELSIUS
			goto	display_decimal
#endif		