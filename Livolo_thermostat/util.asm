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
			