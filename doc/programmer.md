# Software update
To get most out of this new software I recommend doing also the hardware modifications. But you can also use it without them. In this case probably the temperature will be too high as it picks up some heat from the circuit itself. You can try to compensate this with a negative offset.

## Disclaimer
The code inside the controller has the copy prection bit set and cannot be extracted. So once you erase it there is no way back. But why would you want to do that anyway?  
Obviously any modification will void the warranty and I take no responsibility.  
Nevertheless I'm happy to answer any question and if you have and suggestions for improvment please let me know.

## Never connect the board to 220V when connecting it to the pogrammer !!!!!!!
You risk a serios electric shock or even death and your computer can be damaged.  
The board is using 3.3V, so we can power it safely from the PICKit with 3.25.  

## Connecting the programmer to the thermostat
The microcontroller PIC16F690 in this thermostat support in-circuit programming and debugging. There are different programmers and in-circuit debuggers available.  
I used a PICkit 3, which is pretty affordable.
There are already soldering points on the mainboard.
<img src="mod_thermometer.jpg"/>  
Pin 1 is the first pin the left with the square around it.
On the PICKit pin 1 is marked with a triangle.  
<a href="PICkit3 connector.jpg">Board with PICKit connector, external thermometer and light sensor</a>

## MPLab IDE / IPE
There are two tools available for programming / debugging. MPlab IDE and MPlab IPE.  
If you just want to update the software the IPE is sufficient. For builing it yourselve and do modifying the code you will the full IDE.  
You can get both from [https://www.microchip.com/en-us/development-tools-tools-and-software/mplab-x-ide](https://www.microchip.com/en-us/development-tools-tools-and-software/mplab-x-ide)

## Erasing
As the code is copy protected we first need to do a full erase. So let's start the IPE.  
First to to the menu Settings -> Advanced mode. As said in the dialog the password is microchip.
Now in the operate screen select the PIC16F690 and your PICKit device.
Then go to power settings.

If the controller has the copy protect set, then you can perform only a full erase. That requires at least 4.5V. It took me a while to figure that out.  
So mark "Power target circuit from PICKit" and choose 4.5V. No worries, it won't cause any damage although the normal voltage is 3.3V.  

Now go back to "Operate" and press the "Erase" button. Once it is complete got back to the power settings and lower it to 3.3V  
Back in "Operate" run the blank check, which should now confirm that the device is blank (and ready to re-prograam).  

## Programming
* CLick on the "Browse" button next to "Hex file" and select "Livolo_thermostat.hex"  
* Click on "Program" to flash it to the controller. That's all

## MPLab IDE
If you prefer building the hex file on your own, or if you want to change something, then you can use MPLab IDE.  
The programmer is fully integrated in the IDE and you can trigger the build and flashing directly from there.  

[Back to README](/README.md)  
[Hardware description](doc/hardware.md)  
[Hardware modifications](doc/hardware_mod.md)  
[User mannual](doc/user_manual.md)

