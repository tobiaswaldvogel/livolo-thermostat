#include <xc.inc>
#include "global.inc"

psect	global_var, global, class=BANK0, space=SPACE_DATA, delta=1, noexec
disp_l:			    ds  1   ; Left digit
disp_r:			    ds  1   ; Right digit
flags1:			    ds	1    
flags2:			    ds	1    
setup_mode:		    ds	1

timer50hz:		    ds	1    
var_timer_thermometer:	    ds	1   ; Timer for thermometer sampling
var_timer_adc:		    ds	1   ; Timer for ADC (light sensor)
var_timer_inactivity:	    ds	1
var_timer_relay:	    ds	3
var_timer_valve_maint:	    ds	4    
var_timer_valve_maint_set:  ds	4   ; Value for intializing maintenance timer
timer_valve_maint_mult:	    ds	4
    
var_timer_keep_displ_on:    ds	2   ; Timer for keeping the display on after touching a sensor    

signal_touch:		    ds	1   ; Signals for touch events
signal_timer:		    ds	1   ; Signals for timer events    

current_temperature:	    ds	1
target_temperature:	    ds	1
relay_delay:		    ds	1    
temperature_offset:	    ds	1
light_sensor_limit:	    ds	1    
light_sensor_value:	    ds	1
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