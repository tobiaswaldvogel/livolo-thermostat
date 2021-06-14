#include <xc.inc>
#include "global.inc"   
#include "one_wire.inc"
		
global	one_wire_reset, one_wire_rx, one_wire_tx

psect   code

bit_counter		equ	arg_0
presence_detect		equ	arg_1
tx_data			equ	arg_1		
   
; Waits time in us
WAIT			macro	TIME    
			;   Wait 500 us
			movlw	(TIME / 5) -1	;1us 
			movwf	arg_2	    	;1us
			nop                     ;1us
			nop                     ;1us => 4us before loop
						;1 additional from decfsz if 0

			nop                     ;1us
			nop                     ;1us
			decfsz	arg_2		;1us if not zero or 2us if zero
			goto	$ - 3		;2us => 5 2us in loop
			endm

one_wire_reset:		btfss	FLAG_ONEWIRE_RB6
			goto	one_wire_reset_rb4
			goto	one_wire_reset_rb6

one_wire_rx:		btfss	FLAG_ONEWIRE_RB6
			goto	one_wire_rx_rb4
			goto	one_wire_rx_rb6

one_wire_tx:		btfss	FLAG_ONEWIRE_RB6
			goto	one_wire_tx_rb4
			goto	one_wire_tx_rb6

;--------------------------------------------------------- 
; OneWire routines for RB4
;--------------------------------------------------------- 
one_wire_reset_rb4:	clrf	presence_detect	; Presence detect
			bcf	GIE
			bsf	RP0			   
			bsf	TRISB, 4	; DQ High
			bcf	RP0
			bcf	PORTB, 4	; Clear DQ
			bsf	RP0
			bcf	TRISB, 4 
			bcf	RP0
			WAIT	500		; keep DQ 500us low

			bsf	RP0
			bsf	TRISB, 4	; DQ high
			bcf	RP0
			
			WAIT	70		    ; Release line and wait 70us for PD Pulse

			btfss	PORTB, 4	    ; Read for a PD Pulse
			incf	presence_detect, f  ; Indicate PD
			
			bsf	GIE
			WAIT	430		    ; Wait 430us after PD Pulse
			rrf	presence_detect, f  ; Rotate bit 0 (PD)to Carry
			retlw	0

; FSR points to byte to send, assume bank 0			
one_wire_tx_rb4:	movwf	tx_data		; Send data
			movlw	8		; Bit counter
			movwf	bit_counter
one_wire_tx_loop_rb4:	bcf	GIE
			bcf	PORTB, 4	; DQ low
			bsf	RP0		; Bank 1
			bcf	TRISB, 4	; Swith DQ to output 
			bcf	RP0
			nop			; hold for 3us
			nop
			nop
			rrf	tx_data, f	; Next bit of send data in Carry
			bsf	RP0
			btfsc	CARRY		; Keep low  if bit 0
			bsf	TRISB, 4	; Set High if bit 1
			WAIT	60
			bsf	TRISB, 4	; High
			bcf	RP0		; bank 0
			decf	bit_counter, f	; Bit counter
			btfss	ZERO		; if this is not the last bit we
			bsf	GIE		;   can enable interrupts already
						; 2 us recovery
			btfss	ZERO
			goto	one_wire_tx_loop_rb4

			btfsc	FLAG_ONEWIRE_SELF_POWERED
			goto	one_wire_tx_ret_rb4
    			rrf	arg_1, w	; Restore send data
			sublw	DS18B20_CONVERT
			btfss	ZERO
			goto	one_wire_tx_ret_rb4
			; Set port to output high for parasite power after CONVERT cmd
			bsf	PORTB, 4	; High
			bsf	RP0			   
			bcf	TRISB, 4	; Output
			bcf	RP0

one_wire_tx_ret_rb4:	bsf	GIE
			retlw	0

; FSR points to receive location			
one_wire_rx_rb4:	movlw	8
			movwf	bit_counter	; Bit counter
one_wire_rx_loop_rb4:	bcf	GIE
			bcf	PORTB, 4	; DQ low
			bsf	RP0
			bcf	TRISB, 4 
			nop			; DQ low for 6us
			nop
			nop
			nop
			nop
			nop
			bsf	TRISB, 4	; High
			bcf	RP0
			nop			; DQ high for 4us
			nop
			nop
			nop
			movf	PORTB, w	; Read DQ
			bsf	GIE
			andlw	1 << 4		; Mask off the DQ bit
			addlw	-1		; C = DQ
			rrf	INDF, f
			WAIT	50
			decfsz	bit_counter, f	; Bit counter
			goto	one_wire_rx_loop_rb4
			retlw	0
   
;--------------------------------------------------------- 
; OneWire routines for RB6
;--------------------------------------------------------- 
one_wire_reset_rb6:	clrf	presence_detect	; Presence detect
			bcf	GIE
			bsf	RP0			   
			bsf	TRISB, 6	; DQ High
			bcf	RP0
			bcf	PORTB, 6	; Clear DQ
			bsf	RP0
			bcf	TRISB, 6 
			bcf	RP0
			WAIT	500		; keep DQ 500us low

			bsf	RP0
			bsf	TRISB, 6	; DQ high
			bcf	RP0
			
			WAIT	70              ; Release line and wait 70us for PD Pulse

			btfss	PORTB, 6	    ; Read for a PD Pulse
			incf	presence_detect, f  ; Indicate PD
			
			bsf	GIE
			WAIT	430		    ; Wait 430us after PD Pulse
			rrf	presence_detect, f  ; Rotate bit 0 (PD)to Carry
			retlw	0

; FSR points to byte to send, assume bank 0			
one_wire_tx_rb6:	movwf	tx_data		; Send data
			movlw	8		; Bit counter
			movwf	bit_counter
one_wire_tx_loop_rb6:	bcf	GIE
			bcf	PORTB, 6	; DQ low
			bsf	RP0		; Bank 1
			bcf	TRISB, 6	; Swith DQ to output 
			bcf	RP0
			nop			; hold for 3us
			nop
			nop
			rrf	tx_data, f	; Next bit of send data in Carry
			bsf	RP0
			btfsc	CARRY		; Keep low  if bit 0
			bsf	TRISB, 6	; Set High if bit 1
			WAIT	60
			bsf	TRISB, 6	; High
			bcf	RP0		; bank 0
			decf	bit_counter, f	; Bit counter
			btfss	ZERO		; if this is not the last bit we
			bsf	GIE		;   can enable interrupts already
						; 2 us recovery
			btfss	ZERO
			goto	one_wire_tx_loop_rb6

			btfsc	FLAG_ONEWIRE_SELF_POWERED
			goto	one_wire_tx_ret_rb6
    			rrf	arg_1, w	; Restore send data
			sublw	DS18B20_CONVERT
			btfss	ZERO
			goto	one_wire_tx_ret_rb6
			; Set port to output high for parasite power after CONVERT cmd
			bsf	PORTB, 6	; High
			bsf	RP0			   
			bcf	TRISB, 6	; Output
			bcf	RP0

one_wire_tx_ret_rb6:	bsf	GIE
			retlw	0

; FSR points to receive location			
one_wire_rx_rb6:	movlw	8
			movwf	bit_counter	; Bit counter
one_wire_rx_loop_rb6:	bcf	GIE
			bcf	PORTB, 6	; DQ low
			bsf	RP0
			bcf	TRISB, 6 
			nop			; DQ low for 6us
			nop
			nop
			nop
			nop
			nop
			bsf	TRISB, 6	; High
			bcf	RP0
			nop			; DQ high for 4us
			nop
			nop
			nop
			movf	PORTB, w	; Read DQ
			bsf	GIE
			andlw	1 << 6		; Mask off the DQ bit
			addlw	-1		; C = DQ
			rrf	INDF, f
			WAIT	50
			decfsz	bit_counter, f	; Bit counter
			goto	one_wire_rx_loop_rb6
			retlw	0
