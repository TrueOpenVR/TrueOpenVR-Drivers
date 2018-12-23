[![EN](https://user-images.githubusercontent.com/9499881/33184537-7be87e86-d096-11e7-89bb-f3286f752bc6.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/blob/master/README.md)
[![RU](https://user-images.githubusercontent.com/9499881/27683795-5b0fbac6-5cd8-11e7-929c-057833e01fb1.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/blob/master/README.RU.md)
# TrueOpenVR Drivers
Ready and samples drivers for VR devices.

## Drivers
**PSMoveService** - driver allowing to get position in space for DIY devices (using ping pong balls with LEDs) and use PS Move controllers and PSVR HMD. Need to work [PSMoveService](https://github.com/cboulay/PSMoveService). Read more [here](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/C%2B%2B/PSMoveService).

**RazerHydra** - driver allowing to use the Razer Hydra controllers. To work you need to install "SixenceSDK" ("Additionally\RazerHydra\Install.bat"). Read more [here](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/C%2B%2B/RazerHydra).

**ArduinoControllers** - driver allowing tracking the rotation and receive buttons for VR controllers. Together with ping pong balls, with LEDs, you can get full VR controllers (run through the "SpliiterAdvance" driver with "PSMoveService"). COM ports numbers is changing in the "ArduinoControllers.ini" file, in the TOVR drivers folder. Firmware for Arduino can be found [here](https://github.com/TrueOpenVR/TrueOpenVR-DIY/blob/master/Controllers/Arduino/Controller.ino). Read more about creating controllers. [here](https://github.com/TrueOpenVR/TrueOpenVR-DIY/blob/master/Controllers/Controllers.md).

**SplitterAdvance** - driver allowing to connect one driver for positioning, a second driver for rotation, a third driver for buttons, for VR HMD and VR controllers. You can configure the drivers in the "SplitterAdvance.ini" or "SplitterAdvance64.ini" (for 64 bit architecture) file located in the "TrueOpenVR\Drivers" folder, changing the drivers names. Read more [here](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/Delphi/SplitterAdvance).

**SplitterControllers** - driver allowing to connect one driver for one controller and two driver for two controller. You can specify to change the index of the device. You can use it together with the "SplitterAdvance" driver. You can configure the drivers in the file "SplitterConrollers.ini" or "SplitterConrollers64.ini" (for 64-bit architecture) located in the "TrueOpenVR\Drivers" folder, changing the driver names.

**Splitter** - driver allowing to connect one driver for the VR HMD, and the second driver for the controllers. You can configure the drivers in the "Splitter.ini" file located in the "TrueOpenVR\Drivers" folder, changing the drivers names.

**FreeTrack** - driver allowing head tracking the rotation and positioning of the VR HMD with using [OpenTrack](https://github.com/opentrack/opentrack/). In OpenTrack supports the following trackers: Oculus Rift (DK1, DK2, CV1), Aruco paper marker (webcam + paper), FreePie UDP receiver (Android), Hatire Arduino, PointTracker, Intel RealSense, Razer Hydra, SteamVR). In the OpenTrack settings, you need to change the "Output interface" to "freetrack 2.0 Enhanced".

**Razor IMU** - driver allowing head tracking the rotation of the VR HMD, using the tracker Razor IMU, based on Arduino and GY-85, with firmware [Razor AHRS](https://github.com/Razor-AHRS/razor-9dof-ahrs/tree/master/Arduino). COM port number is changing in the "RazorIMU.ini" file, in the TOVR drivers folder. Read more [here](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/C%2B%2B/RazorIMU).

**XInput** - driver allowing to receive buttons from the Xbox gamepad for VR controllers. Read more [here](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/C%2B%2B/XInput).

**AndroidControllers** - driver allowing tracking the rotation and receive buttons for VR controllers. Read more [here](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/C%2B%2B/AndroidControllers).

**Keyboard** - driver allowing to change the position of the VR HMD, VR controllers, rotation them. Required for demonstrations and tests. Read more [here](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/C%2B%2B/Keyboard).

**Emulation** - driver simulating a VR devices without data. To emulate trackers or devices.

**Sample** - sample driver for C++ and Delphi. Suitable for tests and development.

**Fake** - driver simulating a VR devices with data. Suitable for tests.