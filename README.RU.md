[![EN](https://user-images.githubusercontent.com/9499881/33184537-7be87e86-d096-11e7-89bb-f3286f752bc6.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/blob/master/README.md)
[![RU](https://user-images.githubusercontent.com/9499881/27683795-5b0fbac6-5cd8-11e7-929c-057833e01fb1.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/blob/master/README.RU.md)
# TrueOpenVR Драйвера
Готовые и демонстрационные драйверы для VR устройств.

## Драйверы
**PSMoveService** - драйвер позволяющий получать позиционирование в пространстве, для шлема и контроллеров, с помощью пинг понг шариков со светодиодами. Для работы необходим [PSMoveService](https://github.com/cboulay/PSMoveService). Подробнее [тут](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/C%2B%2B/PSMoveService).

**ArduinoControllers** - драйвер позволяющий отслеживать вращение и получать кнопки для VR контроллеров. Вместе с пинг понг шариками, со светодиодами, можно получить полноценные VR контроллеры (запускать через "SpliiterAdvance" драйвер, вместе с "PSMoveService"). Номера COM-портов изменяются в файле "ArduinoControllers.ini", в папке драйверов TOVR. Прошивку для Arduino можно найти [здесь](https://github.com/TrueOpenVR/TrueOpenVR-DIY/blob/master/Controllers/Arduino/Controller.ino). Подробнее о создании контроллеров [тут](https://github.com/TrueOpenVR/TrueOpenVR-DIY/blob/master/Controllers/Controllers.RU.md).

**SplitterAdvance** - драйвер позволяющий подключить один драйвер для позиционирования, второй драйвер для вращения, третий драйвер для кнопок, для VR шлема и VR контроллеров. Настроить драйверы можно в файле "Splitter.ini" или "Splitter64.ini" (для 64 битной архитектуры), находяющийся в папке "TrueOpenVR\Drivers", изменив названия драйверов. Подробнее [тут](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/blob/master/Delphi/SplitterAdvance/README.RU.md).

**SplitterControllers** - драйвей позволяющий подключить один драйвер для одного контроллера и второй для другого. Можно указать изменить индекс устройства. Использовать можно вместе с драйвером "SplitterAdvance". Настроить драйверы можно в файле "SplitterConrollers.ini" или "SplitterConrollers64.ini" (для 64 битной архитектуры), находяющийся в папке "TrueOpenVR\Drivers", изменив названия драйверов.

**Splitter** - драйвер позволяющий подключить один драйвер для VR шлема, а второй драйвер для контроллеров. Настроить драйверы можно в файле "Splitter.ini", находяющийся в папке "TrueOpenVR\Drivers", изменив названия драйверов.

**FreeTrack** - драйвер позволяющий отслеживать вращение и позиционирование VR шлема, с помощью [OpenTrack](https://github.com/opentrack/opentrack/). В OpenTrack поддерживаются следующие трекеры: Oculus Rift (DK1, DK2, CV1), Aruco paper marker (webcam + paper), FreePie UDP receiver (Android), Hatire Arduino, PointTracker, Intel RealSense, Razer Hydra, SteamVR). В настройках OpenTrack нужно изменить "Выходной интерфейс" на "freetrack 2.0 Enhanced".

**Razor IMU** - драйвер позволяющий отслеживать вращения VR шлема, с помощью трекера Razor IMU, на базе Arduino и GY-85, с прошивкой [Razor AHRS](https://github.com/Razor-AHRS/razor-9dof-ahrs/tree/master/Arduino). Номер COM-порта изменяется в файле "RazorIMU.ini", в папке драйверов TOVR. Подробнее [тут](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/C%2B%2B/RazorIMU).

**XInput** - драйвер позволяющий получать кнопки, от Xbox геймпада, для VR контроллеров. Подробнее [тут](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/C%2B%2B/XInput).

**AndroidControllers** - драйвер позволяющий отслеживать вращение и получать кнопки для VR контроллеров. Подробнее [тут](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/C%2B%2B/AndroidControllers).

**Keyboard** - драйвер позволяющий изменять позицию VR шлема, VR контроллеров, вращать их. Необходим для демонстрации и тестов. Подробнее [тут](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/C%2B%2B/Keyboard).

**Emulation** - драйвер имитирующий VR устройства, без данных. Для эмуляции трекеров или устройств.

**Sample** - демонстрационный драйвер на С++ и Delphi. Подходит для тестов.

**Fake** - драйвер имитирующий VR устройства, с данными. Подходит для тестов.

