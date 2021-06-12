# New Firmware for Livolo Thermostat VL-C7-01TM
This firmware adresses the following issues:
* Wrong temperature  
Just after powering up the temperature looks quite ok, but after approx. 2 minutes it starts going up or down. Sometimes there are suddenly jumps of 2 degrees
* No temperature calibration possible
* No delay for switching on/off  
If the measured temperature is just between the target temperature and one degree lower, then it can jump frequently one degree up and down. Best practice here is to wait for some time for the temperature to settle. However, this thermostat immediately acts the valve relay, which is annoying due the noise of the relay and probably it is also not the best for the valves
* No indicator if currently heating or not
* No valve maintenance function  
If the heating is not in use (summer) then it is best practice to open the valves every week for a few minutes to avoid them from getting stuck. Unfortunately, this is not implemented.
* Unsuitable for bedroom  
For a bedroom the display is too bright and won't let you sleep (me at least)

## <a href="doc/introduction.html">Introduction</a>
