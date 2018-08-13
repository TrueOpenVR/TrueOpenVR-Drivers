[![EN](https://user-images.githubusercontent.com/9499881/33184537-7be87e86-d096-11e7-89bb-f3286f752bc6.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/blob/master/README.md) [![RU](https://user-images.githubusercontent.com/9499881/27683795-5b0fbac6-5cd8-11e7-929c-057833e01fb1.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/blob/master/README.RU.md)
# TrueOpenVR Драйвера
Готовые и демонстрационные драйверы для VR устройств.

## Драйверы
**FreeTrack** - драйвер позволяющий отслеживать вращение и позиционирование VR шлема, с помощью [OpenTrack](https://github.com/opentrack/opentrack/). В OpenTrack поддерживаются следующие трекеры: Oculus Rift (DK1, DK2, CV1), Aruco paper marker (webcam + paper), FreePie UDP receiver (Android), Hatire Arduino, PointTracker, Intel RealSense, Razer Hydra, SteamVR). В настройках OpenTrack нужно изменить "Выходной интерфейс" на "freetrack 2.0 Enhanced".

**Razor IMU** - драйвер позволяющий отслеживать вращения VR шлема, с помощью трекера Razor IMU, на базе Arduino и GY-85, с прошивкой [Razor AHRS](https://github.com/Razor-AHRS/razor-9dof-ahrs/tree/master/Arduino). Номер COM-порта изменяется в файле "RazorIMU.ini", в папке драйверов TOVR.

**PSMoveService** - драйвер позволяющий получать позиционирование в пространстве, для шлема и контроллеров, с помощью пинг понг шариков со светодиодами. Для работы необходим [PSMoveService](https://github.com/cboulay/PSMoveService).

**XInput** - драйвер позволяющий получать кнопки, от Xbox геймпада, для VR контроллеров.

**Splitter** - драйвер позволяющий подключить один драйвер для VR шлема, а второй драйвер для контроллеров. Настроить драйверы можно в файле "Splitter.ini", находяющийся в папке "TrueOpenVR\Drivers", изменив названия драйверов.

**SplitterAdvance** - драйвер позволяющий подключить один драйвер для позиционирования, второй драйвер для вращения, третий драйвер для кнопок, для каждого устройства. Настроить драйверы можно в файле "Splitter.ini" или "Splitter64.ini" (для 64 битной архитектуры), находяющийся в папке "TrueOpenVR\Drivers", изменив названия драйверов.

**Sample** - демонстрационный драйвер на С++ и Delphi. 

**Fake** - драйвер имитирующий VR устройства.

