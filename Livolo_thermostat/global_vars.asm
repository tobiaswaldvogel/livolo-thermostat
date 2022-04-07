#include <xc.inc>
#include "global.inc"

psect	global_var, global, class=BANK0, space=SPACE_DATA, delta=1, noexec
display_bcd:		    ds	1   ; BCD value for display
disp_leds:		    ds	1   ; LED state
disp_brightness:	    ds	1
flags1:			    ds	1    
flags2:			    ds	1    
setup_mode:		    ds	1

brightness:		    ds	1   ; Brightness for normal operation 1..250
brightness_night:	    ds	1    
    
var_timer_125hz:	    ds	1    
var_timer_thermometer:	    ds	1   ; Timer for thermometer sampling
var_timer_adc:		    ds	1   ; Timer for ADC (light sensor)
var_timer_target_temp:	    ds	1   ; Timer for displaying current temperature again after '+'/'-'
var_timer_relay:	    ds	2   ; Timer to wait for temperature to settle (seconds)
var_timer_valve_maint:	    ds	3   ; Timer for valve maintenance    
var_timer_valve_maint_set:  ds	3   ; Value for intializing maintenance timer
timer_valve_maint_mult:	    ds	3   ; Temporary variable for calculating var_timer_valve_maint_set
    
var_timer_night_disable:    ds	1   ; Timer for disableing night mode after touching a sensor (1s unit)
var_timer_touch_repeat:	    ds	1   ; Timer for long press repeat
    
signal_touch:		    ds	1   ; Signals for touch events
signal_release:		    ds	1   ; Signals for release events
signal_timer:		    ds	1   ; Signals for timer events    

current_temperature:	    ds	1   ; Current temperature in 0.5 Celsius / Fahrenheit
target_temperature:	    ds	1   ; Target temperature in 0.5 Celsius / Fahrenheit
relay_delay:		    ds	1 
temperature_offset:	    ds	1   ; Temperature offset in 0.5 Celsius or 1 Fahrenheit steps
light_sensor_limit:	    ds	1   ; Theshold for the light sensor  
light_sensor_value:	    ds	1   ; Current light sensor value
light_sensor_counter:	    ds	1
valve_maintain_days:	    ds	1
operation_mode:		    ds	1
    
isr_status:		    ds	1
isr_fsr:		    ds	1    

psect	common, abs, space=SPACE_DATA, noexec
			    org	70h
arg_0:			    ds	1
arg_1:			    ds	1
arg_2:			    ds	1
arg_3:			    ds	1
arg_4:			    ds	1
arg_5:			    ds	1
arg_6:			    ds	1
arg_7:			    ds	1
    
; Must be in common space because it must be saved before modifying STATUS    
psect	isr_common, abs, space=SPACE_DATA, noexec
			    org	7fh
isr_w:			    ds	1
    
; EEPROM Values    
psect	persistence, class=EEDATA, space=SPACE_EEPROM, noexec
EE_TARGET_TEMPERATURE:	    ds  1
EE_TEMPERATURE_OFFSET:	    ds  1
EE_RELAY_DELAY:		    ds  1
EE_FAHRENHEIT:		    ds  1
EE_LIGHT_SENSOR:	    ds	1
EE_VALVE_MAINTAIN:	    ds	1
EE_OPERATION_MODE:	    ds	1
EE_BRIGHTNESS:		    ds	1    
EE_BRIGHTNESS_NIGHT:	    ds	1        