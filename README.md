[![EN](https://user-images.githubusercontent.com/9499881/33184537-7be87e86-d096-11e7-89bb-f3286f752bc6.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/blob/master/README.md) [![RU](https://user-images.githubusercontent.com/9499881/27683795-5b0fbac6-5cd8-11e7-929c-057833e01fb1.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/blob/master/README.RU.md)
# TrueOpenVR Drivers
Ready and samples drivers for VR devices.

## Drivers
**FreeTrack** - driver that allows head tracking the rotation and positioning of the VR HMD with using [OpenTrack](https://github.com/opentrack/opentrack/). In OpenTrack supports the following trackers: Oculus Rift (DK1, DK2, CV1), Aruco paper marker (webcam + paper), FreePie UDP receiver (Android), Hatire Arduino, PointTracker, Intel RealSense, Razer Hydra, SteamVR). In the OpenTrack settings, you need to change the "Output interface" to "freetrack 2.0 Enhanced".

**Razor IMU** - driver that allows head tracking the rotation of the VR HMD, using the tracker Razor IMU, based on Arduino and GY-85, with firmware [Razor AHRS](https://github.com/Razor-AHRS/razor-9dof-ahrs/tree/master/Arduino). COM port number is changing in the "RazorIMU.ini" file, in the TOVR drivers folder.

**PSMoveService** - driver allowing to receive positioning in space, for HMD and controllers, using ping pong balls with LEDs. Need to work[PSMoveService](https://github.com/cboulay/PSMoveService).

**Splitter** - driver that allows you to connect one driver for the VR HMD, and the second driver for the controllers. You can configure the drivers in the "Splitter.ini" file located in the "TrueOpenVR\Drivers" folder, changing the drivers names.

**Sample** - sample driver for C++ and Delphi.

**Fake** - driver simulating a VR devices.

