[![EN](https://user-images.githubusercontent.com/9499881/33184537-7be87e86-d096-11e7-89bb-f3286f752bc6.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/blob/master/README.md) [![RU](https://user-images.githubusercontent.com/9499881/27683795-5b0fbac6-5cd8-11e7-929c-057833e01fb1.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/blob/master/README.RU.md)
# TrueOpenVR Драйвера
Готовые и демонстрационные драйверы для VR устройств.

## Драйверы
**OpenTrackUDP** - драйвер позволяющий подключить множество различных трекеров: Oculus Rift (DK1, DK2, CV1), Aruco paper marker (webcam + paper), FreePie UDP receiver (Android), Hatire Arduino, PointTracker, Intel RealSense, Fusion, Razer Hydra, UDP over network (custom for developers), SteamVR). В настройках OpenTrack нужно изменить "Выходной интерфейс" на "UDP over network" и IP адрес на "127.0.0.1".

**Razor IMU** - драйвер позволяющий отслеживать вращения VR шлема, с помощью трекера Razor IMU, на базе Arduino и GY-85, с прошивкой [Razor AHRS](https://github.com/Razor-AHRS/razor-9dof-ahrs/tree/master/Arduino). Номер COM-порта изменяется в файле "RazorIMU.ini", в папке драйверов TOVR.

**Splitter** - драйвер позволяющий подключить один драйвер для VR шлема, а второй драйвер для контроллеров. Настроить драйверы можно в файле "Splitter.ini", находяющийся в папке "TrueOpenVR\Drivers", изменив названия драйверов.

**Sample** - демонстрационный драйвер на С++ и Delphi. 

**Fake** - драйвер имитирующий VR устройства.

