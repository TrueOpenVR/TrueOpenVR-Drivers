[![EN](https://user-images.githubusercontent.com/9499881/33184537-7be87e86-d096-11e7-89bb-f3286f752bc6.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/Delphi/SplitterAdvance)
[![RU](https://user-images.githubusercontent.com/9499881/27683795-5b0fbac6-5cd8-11e7-929c-057833e01fb1.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/blob/master/Delphi/SplitterAdvance/README.RU.md)
# Splitter Advance
The setting is made in the file "SplitterAdvance.ini" for 32 bit applications and "SplitterAdvance64.ini" for 64 bit applications.


In "SplitterAdvance.ini" all driver names must be a 32-bit architecture (for example, "Emulation.dll").

In "SplitterAdvance64.ini" all driver names must be a 64-bit architecture (for example, "Emulation64.dll").


There are 4 sections in the configuration file (HMD, Controllers, Controller1 and Controller2). Each section is responsible for its device.

## Parameters
The "Position" parameter is responsible for the name of the position driver. For example, you can use "PSMoveService.dll" (and "PSMoveService64.dll" for 64 bit.) Or "Emulation.dll" (and "Emulation64.dll" for 64 bits.)


The "Rotation" parameter is responsible for the name of the rotation driver. If the rotation is taken from the Position driver, then indicate the same driver, if not, then another driver.


The "Buttons" parameter is responsible for the name of the button driver. If the buttons are already present in the position driver or the rotation driver, you can specify it, if not, you can specify another driver, for example, "XInput.dll" (and "XInput64.dll" for 64 bit.) And the buttons will work from the Xbox gamepad.


Parameters: "OffsetX", "OffsetY", "OffsetZ" are responsible for offsetting the position driver for each device.


Parameters: "OffsetYaw", "OffsetPitch", "OffsetRoll" are responsible for the rotation of the driver rotation for each device.
## Examples
For example, we want to use Ping Pong balls with LED and PS3 camera (PSMoveService) to use for positioning, for the rotation of the helmet we have Arduino with the rotation sensor, and for rotating the controllers and the buttons for 2 more arduino, the configuration file will be as follows:
```
[HMD]
Position = PSMoveService64.dll
Rotation = ArduinoHMD64.dll
...
[Controllers]
Position = PSMoveService64.dll
Rotation = ArduinoControllers64.dll
Buttons = ArduinoControllers64.dll
```

For example, we want to use Ping Pong balls, with LED and PS3 camera (PSMoveService) to use for positioning, for the helmet rotation we have Arduino, with a rotation sensor, and for the buttons of the controllers an Xbox gamepad answers, then the configuration file will be as follows:
```
[HMD]
Position = PSMoveService64.dll
Rotation = ArduinoHMD64.dll
...
[Controller1]
Position = PSMoveService64.dll
Rotation = PSMoveService64.dll
Buttons = XInput64.dll
```
In fact, everything is not difficult, just need to try.