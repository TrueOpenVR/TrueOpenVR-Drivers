[![EN](https://user-images.githubusercontent.com/9499881/33184537-7be87e86-d096-11e7-89bb-f3286f752bc6.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/tree/master/Delphi/SplitterAdvance)
[![RU](https://user-images.githubusercontent.com/9499881/27683795-5b0fbac6-5cd8-11e7-929c-057833e01fb1.png)](https://github.com/TrueOpenVR/TrueOpenVR-Drivers/blob/master/Delphi/SplitterAdvance/README.RU.md)
# Splitter Advance
Настройка производиться в файле "SplitterAdvance.ini" для 32 битных приложений и "SplitterAdvance64.ini" для 64 битых приложений.

В "SplitterAdvance.ini" все названия драйверов должны быть 32 битной архитектуры (например, "Emulation.dll").

В "SplitterAdvance64.ini" все названия драйверов должны быть 64 битной архитектуры (например, "Emulation64.dll").


В конфигурационном файле имеется 3 раздела (HMD, Controller1 и Controller2). Каждый раздел отвечает за свое устройство.
## Параметры
Параметр "Position" отвечает за название позиционного драйвера. Например, можно использовать "PSMoveService.dll" (и "PSMoveService64.dll" для 64 битн.) или "Emulation.dll" (и "Emulation64.dll" для 64 битн.)


Параметр "Rotation" отвечает за название драйвера вращения. Если вращение берется из Position драйвера значит указываем тот же драйвер, если нет, то другой драйвер.


Параметр "Buttons" отвечает за название драйвера, который будет давать нажатия клавиш. Если клавиши уже присутсвуют в позиционном драйвере или дравере вращения, то можно указываем его же, если же нет, то можно указать другой драйвер, например, "XInput.dll" (и "XInput64.dll" для 64 битн.) и кнопки будут работать от Xbox геймпада.


Параметры: "OffsetX", "OffsetY", "OffsetZ" отвечают за смещение позиционного драйвера для каждого устройства.

## Примеры
Например, мы хотим использовать использовать для позиционирования пинг понг шарики со светодиодом и PS3 камеру (PSMoveService), за вращение шлема у нас отвечает Arduino с датчиком вращения, а за вращение контроллеров и кнопки еще 2 ардуино, то конфигурационный файл будет следующим:
```
[HMD]
Position=PSMoveService64.dll
Rotation=ArduinoHMD64.dll
...
[Controller1]
Position=PSMoveService64.dll
Rotation=ArduinoControllers64.dll
Buttons=ArduinoControllers64.dll
...
[Controller2]
Position=PSMoveService64.dll
Rotation=ArduinoControllers64.dll
Buttons=ArduinoControllers64.dll
```

Например, мы хотим использовать использовать для позиционирования пинг понг шарики со светодиодом и PS3 камеру (PSMoveService), за вращение шлема у нас отвечает Arduino с датчиком вращения, а за кнопки контроллеров отвечает Xbox геймпад, то конфигурационный файл будет следующим:
```
[HMD]
Position=PSMoveService64.dll
Rotation=ArduinoHMD64.dll
...
[Controller1]
Position=PSMoveService64.dll
Rotation=PSMoveService64.dll
Buttons=XInput64.dll
...
[Controller2]
Position=PSMoveService64.dll
Rotation=PSMoveService64.dll
Buttons=XInput64.dll
```
На самом деле все не сложно, просто нужно попробовать. 