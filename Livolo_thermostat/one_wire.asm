#include <xc.inc>
#include "global.inc"   
#include "one_wire.inc"
		
global  one_wire_set_port, one_wire_set_pin
global	one_wire_reset, one_wire_rx, one_wire_tx

psect	one_wire_local_var, global, class=BANK1, space=SPACE_DATA, delta=1, noexec
var_one_wire_port:		ds  1
var_one_wire_pin_mask:		ds  1
var_one_wire_fsr_backup:	ds  1
var_one_wire_bit_counter:	ds  1
var_one_wire_wait_counter:	ds  1
var_one_wire_data:		ds  1
var_one_wire_last_tx:		ds  1
var_one_wire_pullup_tx:		ds  1
    
psect   code

one_wire_port		equ	BANKMASK(var_one_wire_port)
one_wire_pin_mask	equ	BANKMASK(var_one_wire_pin_mask)
one_wire_fsr_backup	equ	BANKMASK(var_one_wire_fsr_backup)
one_wire_bit_counter	equ	BANKMASK(var_one_wire_bit_counter)
one_wire_wait_counter	equ	BANKMASK(var_one_wire_wait_counter)
one_wire_data		equ	BANKMASK(var_one_wire_data)
one_wire_pullup_tx	equ	BANKMASK(var_one_wire_pullup_tx)
   
;--------------------------------------------------------- 
; Set one wire port (PORT A, PORT B, PORT C)
;--------------------------------------------------------- 
one_wire_set_port:	bsf	RP0
			bcf	RP1
			movwf	one_wire_port
			bcf	RP0
			bcf	RP1
			return
    
;--------------------------------------------------------- 
; Set one wire pin 0 .. 7
;--------------------------------------------------------- 
one_wire_set_pin:	bsf	RP0
			bcf	RP1
			clrf	one_wire_pin_mask
			movwf	arg_0
			incf	arg_0, f
			bsf	CARRY
one_wire_set_pin_shift:	rlf	one_wire_pin_mask, f
			decfsz	arg_0
			goto	one_wire_set_pin_shift
			bcf	RP0
			bcf	RP1
			return

#if _XTAL_FREQ  == 8000000
;--------------------------------------------------------- 
; Wait (W * 4us)    Min W = 2
;--------------------------------------------------------- 
one_wire_wait:		; - call   1.5us
			; - init   2.0us
			; - return 0.5us (0.5us saved in decfsz vs goto)
			; Total = (W -1) * 2 * 2 + 4 = W * 4
			movwf	one_wire_wait_counter	    ;0.5us
			decf	one_wire_wait_counter, f    ;0.5us
			bcf	CARRY			    ;0.5us
			rlf	one_wire_wait_counter, f    ;0.5us
			
one_wire_wait_2us:	nop				    ;0.5us
			decfsz	one_wire_wait_counter	    ;0.5us if not zero or 1us if zero
			goto	one_wire_wait_2us	    ;1.0us = > 2us per loop
			retlw	0			    ;1.0us

#elif _XTAL_FREQ  == 4000000
;--------------------------------------------------------- 
; Wait (W * 4us)   Min W = 2
; Fehler +1 us			
;--------------------------------------------------------- 
one_wire_wait:		; Case W = 2
			; - call         3.0us
			; - init + ret   6.0us
			; Total 9us
			
			; Case W > 2
			; - call         3.0us
			; - init         5.0us
			; - return       1.0us (1us saved in decfsz vs goto)
			; Total = (W - 2) * 4 + 9 = W * 4 + 1
			movwf	one_wire_wait_counter	    ;1.0us
			decf	one_wire_wait_counter, f    ;1.0us
			decf	one_wire_wait_counter, f    ;1.0us
			btfsc ZERO			    ;1.0us if zero or 2us if not zero
			retlw	0			    ;2.0us

one_wire_wait_4us:	nop				    ;1.0us
			decfsz	one_wire_wait_counter	    ;1.0us if not zero or 2us if zero
			goto	one_wire_wait_4us	    ;2.0us = > 4us per loop
			retlw	0			    ;2.0us

#else
			ERROR
#endif			
		
			
one_wire_reset:		bsf	RP0
			bcf	RP1
			movf	FSR, w		    ; Save FSR
			movwf	one_wire_fsr_backup
			movf	one_wire_port, w
			movwf	FSR
			
			movf	one_wire_pin_mask, w
			xorlw	0ffh
			andwf	INDF, f		    ; DQ low
			bsf	FSR, 7		    ; Switch to TRIS
			andwf	INDF, f		    ; DQ output
			bcf	FSR, 7
			
			movlw	480 / 4
			call	one_wire_wait       ; Keep DQ for at least 480us low

			bcf	GIE		    ; Disable interrupts

			movf	one_wire_pin_mask, w
			bsf	FSR, 7		    ; Switch to TRIS
			iorwf	INDF, f		    ; DQ input
			bcf	FSR, 7
			
			movlw	80 / 4
			call	one_wire_wait       ; Release line and wait 70us for PD Pulse
			
			movf	one_wire_pin_mask, w
			andwf	INDF, w
			movwf	one_wire_data	    ; Store presence detect
			
			bsf	GIE		    ; Enable interrupts

			movlw	400 / 4
			call	one_wire_wait       ; Wait 430us after PD Pulse

			bcf	CARRY
			movf	one_wire_data, w
			btfsc	ZERO
			bsf	CARRY

			movf	one_wire_fsr_backup, w
			movwf	FSR		    ; Restore FSR
			bcf	RP0
			bcf	RP1
			retlw	0

;--------------------------------------------------------- 
; Send byte in W
; Carry => Set DQ to high outout after last bit
;   (used for parasite powering DS18B20)			
;--------------------------------------------------------- 
one_wire_tx:		bsf	RP0		    ; Bank 1
			bcf	RP1
			movwf	one_wire_data	    ; Send data

			clrf	one_wire_pullup_tx  ; Carry => Pullup after TX
			btfsc	CARRY
			incf	one_wire_pullup_tx
			
			movf	FSR, w		    ; Save FSR
			movwf	one_wire_fsr_backup
			movf	one_wire_port, w
			movwf	FSR
			
			movlw	8		    ; Bit counter
			movwf	one_wire_bit_counter

one_wire_tx_loop:	bcf	GIE

			movf	one_wire_pin_mask, w
			xorlw	0ffh
			andwf	INDF, f		    ; DQ low
			bsf	FSR, 7		    ; Switch to TRIS
			andwf	INDF, f		    ; DQ output
    			
			rrf	one_wire_data, w    ; Next bit of send data in Carry
			btfss	CARRY
			movlw	64 / 4		    ; For 0 keep DQ 64 us low
			btfsc	CARRY
			movlw	12 / 4		    ; For 1 keep DQ 12 us low
    			call	one_wire_wait
    
			movf	one_wire_pin_mask, w
			iorwf	INDF, f		    ; DQ input
			bcf	FSR, 7

			decf	one_wire_bit_counter, w
			btfss	ZERO		    ; Last bit sent?
			goto	one_wire_no_pullup  ; No
			
			movf	one_wire_pullup_tx, w ; Pull up after TX?
			btfsc	ZERO
			goto	one_wire_no_pullup  ; No, nothing to do
			
			; Switch DQ to high output
			movf	one_wire_pin_mask, w
			iorwf	INDF, f		    ; DQ high
			bsf	FSR, 7		    ; Switch to TRIS
			xorlw	0ffh
			andwf	INDF, f		    ; DQ output
			bcf	FSR, 7
			
one_wire_no_pullup:	bsf	GIE		    ; Interrupts can be enabled already

			rrf	one_wire_data, f    ; Next bit of send data in Carry and advance
			btfss	CARRY
			movlw	12 / 4		    ; For 0 release DQ for 12us
			btfsc	CARRY
			movlw	64 / 4		    ; For 1 release DQ for 64us
    			call	one_wire_wait
			
			decfsz	one_wire_bit_counter, f	; Bit counter
			goto	one_wire_tx_loop

one_wire_tx_ret:	movf	one_wire_fsr_backup, w
			movwf	FSR		    ; Restore FSR
			bcf	RP0
			bcf	RP1
			retlw	0
			
;--------------------------------------------------------- 
; Receive byte and return in W
;--------------------------------------------------------- 
one_wire_rx:		bsf	RP0
			bcf	RP1
			movf	FSR, w		    ; Save FSR
			movwf	one_wire_fsr_backup
			movf	one_wire_port, w
			movwf	FSR

			movlw	8
			movwf	one_wire_bit_counter	; Bit counter

one_wire_rx_loop:	bcf	GIE		    ; Disable interrupts

			movf	one_wire_pin_mask, w
			xorlw	0ffh
			andwf	INDF, f		    ; DQ low
			bsf	FSR, 7		    ; Switch to TRIS
			andwf	INDF, f		    ; DQ output
 
			movlw	12 / 4		    ; For 1 keep DQ 12 us low
    			call	one_wire_wait

			movf	one_wire_pin_mask, w
			iorwf	INDF, f		    ; DQ input
			bcf	FSR, 7

			movlw	8 / 4		    ; Wait 12us
    			call	one_wire_wait
			
			movf	one_wire_pin_mask, w
			bcf	CARRY
			andwf	INDF, w
			bsf	GIE		    ; Re-enable interrupts
			btfss	ZERO
			bsf	CARRY		    ; Set carry if DQ high
			rrf	one_wire_data, f

			movlw	52 / 4
			call	one_wire_wait
			
			decfsz	one_wire_bit_counter, f	; Bit counter
			goto	one_wire_rx_loop
			
			movf	one_wire_fsr_backup, w
			movwf	FSR		    ; Restore FSR
			movf	one_wire_data, w
			bcf	RP0
			bcf	RP1
			return
  