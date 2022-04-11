# User manual
## Temperature
The temperature can be adjusted by touching "+" or "-".  
The first touch just displays the current target temperature and subsequent touches change it.  
<img src="valve_off.jpg"/>  
The temperature unit flashes to indicate that the target temperature is displayed  .
After 4 seconds the display will display again the current temperature  

The blue circle indicates that the heating/cooling is currently off.  
When the heating/cooling is active the indicator will turn red.  
## Stand by
Touching the 'O' will turn the the thermostat to stand-by, which will turn off the display.  
In heating mode the minimum temperature is set to 5° Celsius / 41° Fahrenheit (freeze protection).

## Night mode
Long touching 'O' (more than 1 second) switches to night mode.  
The brightness for day and night mode can be defined in the setup  .
The range is from 0 (off) to 50 maximum brightness. For day mode the minimum brightness is 2.

## Automatic night mode
If you added the light sensor, night mode will turn on automatically when the light level falls below the threshold.
After touching a sensor the display will turn again and stay on for 10 seconds
Without a sensor the current value is always 50. So if you want to have night permanently you can just a set a threshold above 50

## Setup mode
To enter setup touch '+' and '-' for more than 1 second at the same time or one after each other.  
Each setting can be adjusted with '+' and '-' and 'O' advances to the next setting in the following sequence.  
You can exit the setup at any time by touching 'O' for more than 1 second.

### Operation mode (Right digit flashing, C and F off)
0 and red circle  - Heating, Line active when current temperature is below the target temperature  
1 and blue circle - Cooling, Line active when current temperature is above the target temperature  

### Temperature offset / calibration (Left or right digit is flashing, C and F off)
If the temperature at the thermostat is higher or lower than your reference point you can add a positive or negative offset  
The range is from -9 to 9 and corresponds to steps of 0.5° Celsius or 1° Fahrenheit  
Negative values are displayed on the left  
<img src="negative_offset.jpg"/>  
and positive values on the right  
<img src="positive_offset.jpg"/>  

### Delay after temperature change (Both digits flashing, C and F off)
Time to wait after a temperature change to settle before acting the heating / cooling
The range is from 01 to 99 with a unit of 10s.  
So the minimum delay is 10s and the maximum 16:30 (99 * 10s)  
<img src="valve_delay.jpg"/>  
Setting a new temperature however always has an immediate effect  

### Valve maintenance days (Both digits and C flashing, F off)  
This is a setting for water heating / cooling.  
Automatic valve maintenance opens the valve periodically for 5 minutes, in order to avoid that they get stuck if not in use for a long time (e.g. summer)  
The range is from 0 to 99 days, whereas 0 means off.

### Brightness for day mode (Both digits flashing, circle red, C and F off)  
Brightness for the day mode (range 2..50).

### Brightness for night mode (Both digits flashing, circle blue, C and F off)  
Brightness for the day mode (range 0..50). 0 = display off

### Current light sensor value, read-only (Both digits and C and F flashing)
The current reading of the light sensor with a range from 1..98, where 1 is darkest.  
If no sensor is present then it defaults to 50  
<img src="light_sensor_status.jpg"/>

### Light sensor threshold (Both digits flashing, C and F off)
Threshold for turning the display off (night mode). The light sensor value from the step before can be used to find a good setting.  
As the sensor has range from 1..98, setting it to 0 means deactivate night mode whereas 99 is permanent night mode.

### Unit Celsius / Fahrenheit (Digits off, C or  F flashing)
Switches between Celsius and Fahrenheit


[Back to README](/README.md)  
[Hardware description](/doc/hardware.md)  
[Hardware modifications](/doc/hardware_mod.md)  
[Firmware update](/doc/programmer.md)  
