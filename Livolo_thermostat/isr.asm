#include <xc.inc>
#include "global.inc"

psect	isr_local_var, global, class=BANK0, space=SPACE_DATA, delta=1, noexec
cap_sensor_touched: ds	    1    
cap_sensor:	    ds	    1		    ; Current sensr 0 - 2
cap_sensor_avg:	    ds	    3 * 2	    ; Avg. raw data
cap_sensor_trip:    ds	    2
cap_new_avg:	    ds	    3

sensor_state_mask:  ds	    1
sensor_hold_time:   ds	    3

;Interrupt vector		    
psect	isr_vector, abs,class=CODE, space=SPACE_CODE, delta=2		
		    org	4

;--------------------------------------------------------- 
; Interrupt service routine
;--------------------------------------------------------- 
isr:		    movwf   isr_w	    ; Save w register
		    swapf   STATUS, w	    ; Save STATUS to w (movf would affect Z)
		    clrf    STATUS	    ; IRP bank 0, RP bank 0
		    movwf   isr_status	    ; Save status

		    btfsc   T0IF
		    goto    cap_sensor_isr
		    btfsc   TMR2IF
		    goto    isr_timer2

isr_ret:	    swapf   isr_status, w   ; Undo sawp from save
		    movwf   STATUS	    ; Restore STATUS
		    swapf   isr_w, f	    ; Sawp isr_w
		    swapf   isr_w, w	    ; Restore w
		    retfie

;--------------------------------------------------------- 
; Timer 0 interrupt
; Cap sensor measuring
;--------------------------------------------------------- 
cap_sensor_isr:	    bcf	    T0IE		; Acknoledge interrupt
		    bcf	    T0IF
		    bcf	    TMR1ON		; Stop timer 1
		    movf    TMR0, w
		    btfss   ZERO
		    goto    cap_sensor_measure	; Interrupt delayed -> repeat sensor

		    ; Do the bsf first in the CMxCON0 registers
		    ; to avoid select C12IN0- (which would be RA1, display right)
		    movf    FSR, w
		    movwf   isr_fsr	    ; Save FSR register
		    
		    movf    cap_sensor, w   ; Which sensor ?
		    bsf	    RP1		    ; Bank 2 for CMxCON0
		    btfss   ZERO	    ; Sensor plus
		    goto    cap_sensor_minus
		    bsf	    CM1CON0, 1	    ; Next input C12IN2- (minus)
		    bcf	    CM1CON0, 0
		    bsf	    CM2CON0, 1
		    bcf	    CM2CON0, 0
		    goto    cap_sensor_calc
		    
cap_sensor_minus:   addlw   -1
		    btfss   ZERO	    ; Sensor minus
		    goto    cap_sensor_power
		    bsf	    CM1CON0, 1	    ; Next input C12IN3- (power)
		    bsf	    CM1CON0, 0
		    bsf	    CM2CON0, 1
		    bsf	    CM2CON0, 0
		    goto    cap_sensor_calc
		    
cap_sensor_power:   bsf	    CM1CON0, 0	    ; Select inuput C12IN1-
		    bcf	    CM1CON0, 1
		    bsf	    CM2CON0, 0
		    bcf	    CM2CON0, 1

cap_sensor_calc:    bcf	    RP1		    ; Select bank 0
		    movlw   cap_sensor_avg
		    addwf   cap_sensor, w
		    addwf   cap_sensor, w
		    movwf   FSR		    ; FSR points to avg of sensor
		    
		    ; Check if avg initial
		    incf    FSR, f
		    movf    INDF, w	    ; avg high
		    decf    FSR, f
		    iorwf   INDF, w	    ; avg low
		    btfss   ZERO
		    goto    cap_sens_calc_trip ; Not initial
		    
		    ; Avg. empty => first measure => just store
		    movf    TMR1L, w
		    movwf   INDF	    ; avg low
		    incf    FSR, f
		    movf    TMR1H, w
		    movwf   INDF	    ; avg high
		    goto    cap_sensor_next

		    ; Calculate trip
		    ; Touching the sensor:
		    ;   decreases the frequency
		    ;   increase interval in timer 1
		    ;   generates a positive trip (timer 1 - avg)
cap_sens_calc_trip: movf    INDF, w	    ; avg low
		    subwf   TMR1L, w
		    movwf   cap_sensor_trip
		    incf    FSR, f
		    movf    INDF, w	    ; avg high
		    decf    FSR, f
		    btfss   CARRY
		    addlw   1		    ; Add carry
		    subwf   TMR1H, w
		    movwf   cap_sensor_trip + 1
		    btfsc   cap_sensor_trip + 1, 7 ; Result negative ?
		    goto    cap_sens_calc_avg
		    
		    ; Check if trip is big enough for touch event
		    ; Substract 2,5 time avg high  (5 / 512 ~ 1%)
		    incf    FSR, f
		    movf    INDF, w	    ; avg high
		    subwf   cap_sensor_trip, f
		    btfss   CARRY
		    decf    cap_sensor_trip + 1

		    subwf   cap_sensor_trip, f
		    btfss   CARRY
		    decf    cap_sensor_trip + 1

		    bcf	    CARRY
		    rrf	    INDF, w
		    subwf   cap_sensor_trip, f
		    btfss   CARRY
		    decf    cap_sensor_trip + 1

		    decf    FSR, f
		    btfsc   cap_sensor_trip + 1, 7 ; Result negative ?
		    goto    cap_sens_calc_avg

		    ; Button touched => Set touched flag
		    ;    which will be evaluated in timer 2 ISR
		    movf    cap_sensor, w
		    btfsc   ZERO		    ; In case of zero
		    movlw   4			    ;  set bit 2
		    iorwf   cap_sensor_touched, f
		    goto    cap_sensor_next
		    
		    ; FSR points to avg low
		    ; Button is not touched, update average
		    ; new avg = (avg * 15 + raw) / 16
cap_sens_calc_avg:  bcf	    CARRY
		    rlf	    INDF, w	    ; avg low
		    movwf   cap_new_avg
		    incf    FSR, f
		    rlf	    INDF, w	    ; avg high
		    movwf   cap_new_avg + 1
		    clrf    cap_new_avg + 2
		    btfsc   CARRY
		    incf    cap_new_avg + 2, f
		    ; Now cap_new_avg is avg << 1
		    bcf	    CARRY
		    rlf	    cap_new_avg, f
		    rlf	    cap_new_avg + 1, f
		    rlf	    cap_new_avg + 2, f
		    ; Now cap_new_avg is avg << 2
		    rlf	    cap_new_avg, f
		    rlf	    cap_new_avg + 1, f
		    rlf	    cap_new_avg + 2, f
		    ; Now cap_new_avg is avg << 3
		    rlf	    cap_new_avg, f
		    rlf	    cap_new_avg + 1, f
		    rlf	    cap_new_avg + 2, f
		    ; Now cap_new_avg is avg << 4 ( = * 16 )
		    
		    decf    FSR, f	    ; avg low
		    movf    INDF, w	    ; avg low
		    subwf   cap_new_avg, f
		    incf    FSR, f
		    movf    INDF, w	    ; avg high
		    btfsc   CARRY
		    goto    cap_sens_calc_avg1
		    addlw   1		    ; Add carry to high
		    btfsc   CARRY
		    decf    cap_new_avg + 2, f

cap_sens_calc_avg1: subwf   cap_new_avg + 1, f
		    btfss   CARRY
		    decf    cap_new_avg + 2, f
		    ; Now cap_new_avg is avg * 15
		    
		    movf    TMR1L, w
		    addwf   cap_new_avg, f
		    movf    TMR1H, w
		    btfss   CARRY
		    goto    cap_sens_calc_avg2
		    addlw   1
		    btfsc   CARRY
		    incf    cap_new_avg + 2, f
		    
cap_sens_calc_avg2: addwf   cap_new_avg + 1, f
		    btfsc   CARRY
		    incf    cap_new_avg + 2, f
		    ; Now cap_new_avg is avg * 15 + timer 1

		    ; Don't care about clearing C as we discard the bits later
		    rrf	    cap_new_avg + 2, f
		    rrf	    cap_new_avg + 1, f
		    rrf	    cap_new_avg, f
		    ; / 2
		    rrf	    cap_new_avg + 2, f
		    rrf	    cap_new_avg + 1, f
		    rrf	    cap_new_avg, f
		    ; / 4
		    rrf	    cap_new_avg + 2, f
		    rrf	    cap_new_avg + 1, f
		    rrf	    cap_new_avg, f
		    ; / 8

		    incfsz  cap_new_avg, f	; Add 1 for rounding
		    goto    cap_sens_calc_avg3
		    incfsz  cap_new_avg + 1, f
		    goto    cap_sens_calc_avg3
		    incf    cap_new_avg + 2, f
		    
cap_sens_calc_avg3: rrf	    cap_new_avg + 2, f
		    rrf	    cap_new_avg + 1, w
		    movwf   INDF		; Set avg high
		    decf    FSR, f
		    rrf	    cap_new_avg, w
		    movwf   INDF		; Set avg low

		    ; Button not touched => Clear touched flag
		    ;    which will be evaluated in timer 2 ISR
		    movf    cap_sensor, w
		    btfsc   ZERO		    ; In case of zero
		    movlw   4			    ;  set bit 2
		    xorlw   0ffh
		    andwf   cap_sensor_touched, f

cap_sensor_next:    incf    cap_sensor, f
		    movf    cap_sensor, w
		    addlw   -3
		    btfsc   CARRY
		    clrf    cap_sensor
		    
		    movf    isr_fsr, w	    ; Restore FSR
		    movwf   FSR

cap_sensor_measure: clrf    TMR1H	    ; Start next measure
		    clrf    TMR1L
		    bsf	    TMR1ON
		    movlw   TIMER0_RELOAD
		    movwf   TMR0
		    bcf	    T0IF
		    bsf	    T0IE
    		    goto    isr_ret
    
;--------------------------------------------------------- 
; Timer 2 interrupt
; Running every 8ms (125Hz)
;--------------------------------------------------------- 
isr_timer2:	    bcf	    TMR2IF	    ; Acknoledge interrupt

		    bcf	    PIN_DISP_LEFT
		    bcf	    PIN_DISP_RIGHT
;		    
		    btfss   FLAG_TMR2_DIM
		    goto    isr_timer2_display

		    ; Interrupt for dimming the display
		    ; The remaining time slice to 8ms is
		    ; 200 - brightness timer2 units
		    bcf	    FLAG_TMR2_DIM

		    movf    disp_brightness, w
		    sublw   TIMER2_PERIOD
		    bsf	    RP0			; Bank 1
		    movwf   PR2
		    bcf	    RP0			; Bank 0

		    bcf	    PIN_LED_CELSIUS
		    bcf	    PIN_LED_FAHRENHEIT

		    movf    setup_mode, w
		    btfss   ZERO
		    goto    isr_timer2_dim_end	; In setup mode don't modify the LEDs
		    
		    ; Switch off + / -
		    bsf	    RP0
		    bcf	    PIN_LED_POWER	; TRIS -> output
		    bcf	    RP0
		    bcf	    PIN_LED_POWER
isr_timer2_dim_end: goto    isr_ret		; No then do it in the next interrupt

isr_timer2_display: movf    disp_brightness, w
		    btfsc   ZERO
		    goto    display_nodim	; Brightness 0 => no dimming
		    bsf	    RP0			; Bank 1
		    movwf   PR2
		    bcf	    RP0			; Bank 0
		    sublw   TIMER2_PERIOD - 1	; C   < TIMER2_PERIOD
		    btfss   CARRY
		    goto    display_nodim
		    
		    ; Dim display
		    bsf	    FLAG_TMR2_DIM
		    goto    display_multiplex

		    ; If no dimming set next interrupt to the full 10ms time slice
display_nodim:	    movlw   TIMER2_PERIOD
		    bsf	    RP0			; Bank 1
		    movwf   PR2
		    bcf	    RP0			; Bank 0

display_multiplex:  movf    disp_brightness, w
		    btfss   ZERO
		    goto    display_power
		    
		    ; Display off
		    bcf	    PIN_LED_CELSIUS
		    bcf	    PIN_LED_FAHRENHEIT

		    movf    setup_mode, w	
		    btfss   ZERO
		    goto    display_end		; In setup mode don't modify the LEDs
		    
		    bsf	    RP0
		    bcf	    PIN_LED_POWER	; TRIS -> output
		    bcf	    RP0
		    bcf	    PIN_LED_POWER
		    goto    display_end
		    
		    ; Power / + / -
display_power:	    btfsc   LED_POWER_ON
		    goto    display_power_on
		    ; Off
		    bsf	    RP0
		    bcf	    PIN_LED_POWER	; TRIS -> output
		    bcf	    RP0
		    bcf	    PIN_LED_POWER
		    goto    display_power_end
display_power_on:   btfsc   LED_POWER_RED
		    goto    display_power_red
		    ; + / - lit + blue
		    bsf	    RP0
		    bsf	    PIN_LED_POWER	; TRIS -> input
		    bcf	    RP0			; => lit + blue led			
		    goto    display_power_end
display_power_red:  bsf	    RP0
		    bcf	    PIN_LED_POWER	; TRIS -> output
		    bcf	    RP0
		    bsf	    PIN_LED_POWER
display_power_end:		    

		    ; Unit Celcius
		    btfsc   LED_CELSIUS
		    bsf	    PIN_LED_CELSIUS
		    btfss   LED_CELSIUS
		    bcf	    PIN_LED_CELSIUS

		    ; Unit Fahrenheit
		    btfsc   LED_FAHRENHEIT
		    bsf	    PIN_LED_FAHRENHEIT
		    btfss   LED_FAHRENHEIT
		    bcf	    PIN_LED_FAHRENHEIT
		    
		    ; Display multiplex
		    bcf	    PIN_DISP_A
		    bcf	    PIN_DISP_B
		    bcf	    PIN_DISP_C
		    bcf	    PIN_DISP_D

		    btfsc   FLAG_TMR2_INT_EVEN
		    goto    display_right

		    btfsc   display_bcd, 4
		    bsf	    PIN_DISP_A
		    btfsc   display_bcd, 5
		    bsf	    PIN_DISP_B
		    btfsc   display_bcd, 6
		    bsf	    PIN_DISP_C
		    btfsc   display_bcd, 7
		    bsf	    PIN_DISP_D
		    bsf	    PIN_DISP_LEFT
		    goto    display_end
		    
display_right:	    btfsc   display_bcd, 0
		    bsf	    PIN_DISP_A
		    btfsc   display_bcd, 1
		    bsf	    PIN_DISP_B
		    btfsc   display_bcd, 2
		    bsf	    PIN_DISP_C
		    btfsc   display_bcd, 3
		    bsf	    PIN_DISP_D
		    bsf	    PIN_DISP_RIGHT
display_end:		    

		    incf    var_timer_125hz, f
		    movlw   -125
		    addwf   var_timer_125hz, w
		    btfss   CARRY
		    goto    isr_timer2_8ms

		    clrf    var_timer_125hz
		    bsf	    SIGNAL_TIMER_1HZ

isr_timer2_8ms:	    btfss   FLAG_TMR2_INT_EVEN
		    goto    isr_timer2_sensors
			
;--------------------------------------------------------- 
; Handle timers in even 125Hz interrupts => 16ms
;--------------------------------------------------------- 
		    bcf	    FLAG_TMR2_INT_EVEN

		    btfss   SIGNAL_TIMER_1HZ
		    goto    timer_16ms

		    bcf   SIGNAL_TIMER_1HZ
		    
;--------------------------------------------------------- 
; Handle 1s unit timers
;--------------------------------------------------------- 
		    ; 8 bit Timer for temperature measurement
		    movf    var_timer_thermometer, w
		    btfsc   ZERO
		    goto    timer_inactive_thermometer	; Timer is off
		    decf    var_timer_thermometer, f
		    btfsc   ZERO
		    bsf	    SIGNAL_TIMER_THERMOMETER
timer_inactive_thermometer:

		    ; 8 bit timer for displaying the target temperature
		    movf    var_timer_target_temp, w
		    btfsc   ZERO
		    goto    timer_inactive_target_temp	; Timer is off
		    decf    var_timer_target_temp, f
		    btfsc   ZERO
		    bsf	    SIGNAL_TIMER_TARGET_TEMPERATURE
timer_inactive_target_temp:

		    ; 8 bit timer for keeping display on after a touch event
		    movf    var_timer_night_disable, w
		    btfsc   ZERO
		    goto    timer_inactive_night_disable    ; Timer is inactive
		    decf    var_timer_night_disable, f
		    btfsc   ZERO
		    bsf	    SIGNAL_TIMER_NIGHT_DISABLE
timer_inactive_night_disable:

		    ; 16 bit Valve delay timer
		    movf    var_timer_relay, w
		    iorwf   var_timer_relay + 1, w
		    btfsc   ZERO
		    goto    timer_inactive_relay_delay	; Timer is off (most likely case)
		    ; LSB
		    decfsz  var_timer_relay, f
		    goto    timer_relay_delay
		    ; Zero => Check if timer finished
		    movf    var_timer_relay + 1, w
		    btfss   ZERO
		    goto    timer_inactive_relay_delay
		    ; Timer finished
		    bsf	    SIGNAL_TIMER_VALVE
		    goto    timer_inactive_relay_delay
		    ; Handle underflow
timer_relay_delay:  incf    var_timer_relay, w		; Underflow LSB ?
		    btfsc   ZERO			; Skip if not
		    decf    var_timer_relay + 1, f	; Underflow cannot occur
timer_inactive_relay_delay:
    
		    ; 24 bit timer for valve maintenance
		    movf    var_timer_valve_maint, w
		    iorwf   var_timer_valve_maint + 1, w
		    iorwf   var_timer_valve_maint + 2, w
		    btfsc   ZERO
		    goto    timer_inactive_maintenance	; Timer is off
		    ; LSB
		    decfsz  var_timer_valve_maint, f
		    goto    timer_maintenance
		    ; Zero => Check if timer finished
		    movf    var_timer_valve_maint + 1, w
		    iorwf   var_timer_valve_maint + 2, w
		    btfss   ZERO
		    goto    timer_inactive_maintenance	; No underflow => done
		    ; Timer finished
		    bsf	    SIGNAL_TIMER_VALVE_MAINTAIN
		    goto    timer_inactive_maintenance
		    ; Handle underflow
timer_maintenance:  incfsz  var_timer_valve_maint, w	; Underflow LSB ?
		    goto    timer_inactive_maintenance	; No => done
		    decf    var_timer_valve_maint + 1, f
		    incf    var_timer_valve_maint + 1, w; Underflow byte 2 ?
		    btfsc   ZERO			; Skip if not
		    decf    var_timer_valve_maint + 2, f
timer_inactive_maintenance:
    
;--------------------------------------------------------- 
; Handle 16ms unit timers
;--------------------------------------------------------- 
timer_16ms:		    
		    ; 8 bit Timer for touch repeat events
		    movf    var_timer_touch_repeat, w
		    btfsc   ZERO
		    goto    timer_touch_repeat_off	; Timer is off
		    decf    var_timer_touch_repeat, f
		    btfsc   ZERO
		    bsf	    SIGNAL_TIMER_TOUCH_REPEAT
timer_touch_repeat_off:
		    
		    ; 8 bit ADC timer for light sensor
		    movf    var_timer_adc, w
		    btfsc   ZERO
		    goto    timer_adc_off		; Timer is off
		    decf    var_timer_adc, f
		    btfsc   ZERO
		    bsf	    SIGNAL_TIMER_ADC
timer_adc_off:
    
		    goto    isr_ret
		    
;--------------------------------------------------------- 
; Handle sensor state in odd 125Hz interrupts => 16ms
; The state is set from the timer 0 isr cap measuring
;--------------------------------------------------------- 
isr_timer2_sensors: bsf	    FLAG_TMR2_INT_EVEN
		    movf    FSR, w
		    movwf   isr_fsr		; Save FSR register

		    movlw   1
		    movwf   sensor_state_mask
		    movlw   sensor_hold_time
		    movwf   FSR

sensor_state:	    movf    sensor_state_mask, w
		    andwf   cap_sensor_touched, w
		    btfss   ZERO
		    goto    sensor_hold
		    movf    INDF, w		; hold time
		    btfsc   ZERO
		    goto    sensor_next		; sensor was not hold

		    clrf    INDF		; clear hold time
		    addlw   -LONG_TOUCH		; was this a long touch ?
		    btfss   CARRY
		    goto    sensor_short	; no => check if short touch
		    
		    movf    sensor_state_mask, w
		    iorwf   signal_release, f	; set released signal
		    goto    sensor_next

sensor_short:	    addlw   LONG_TOUCH - MIN_TOUCH  ; Minimum touch time reached ?
		    btfss   CARRY
		    goto    sensor_next		; Ignore if too short
		    
		    movf    sensor_state_mask, w
		    iorwf   signal_touch, f	; if not set short signal
		    swapf   sensor_state_mask, w; high nibble => long
		    xorlw   0ffh
		    andwf   signal_touch, f	; and clear the long signal
		    goto    sensor_next
		    
sensor_hold:	    incf    INDF, w
		    btfsc   ZERO
		    goto    sensor_next		; => Hold time already 255
		    incf    INDF, f
		    addlw   -LONG_TOUCH		; Long touch time reached ?
		    btfss   CARRY
		    goto    sensor_next

		    swapf   sensor_state_mask, w; high nibble for long touch
		    iorwf   signal_touch, f	; set long signal
		    movf    sensor_state_mask, w
		    xorlw   0ffh
		    andwf   signal_touch, f	; and clear the short signal
		    andwf   signal_release, f	; and clear the release signal

		    movlw   0ffh
		    movwf   INDF		; Set hold to 255
		    
sensor_next:	    incf    FSR, f
		    bcf	    CARRY
		    rlf	    sensor_state_mask, f
		    btfss   sensor_state_mask, 3    ; Bit 3 set => done
		    goto    sensor_state

		    movf    isr_fsr, w		; Restore FSR
		    movwf   FSR
		    goto    isr_ret
