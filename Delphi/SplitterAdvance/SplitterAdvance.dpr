library SplitterAdvance;

uses
  SysUtils,
  Classes,
  Windows,
  IniFiles,
  Registry;

type
  //HMD
  PHMD = ^THMD;
  _HMDData = record
    X: double;
    Y: double;
    Z: double;
    Yaw: double;
    Pitch: double;
    Roll: double;
end;
  HMD = _HMDData;
  THMD = HMD;

  //Controllers
  PController = ^TController;
  _Controller = record
    X: double;
    Y: double;
    Z: double;
    Yaw: double;
    Pitch: double;
    Roll: double;
    Buttons: word;
    Trigger: byte;
    ThumbX: smallint;
    ThumbY: smallint;
end;
  Controller = _Controller;
  TController = Controller;

type TOffsetPos = record
  X: double;
  Y: double;
  Z: double;
end;

type TOffsetYPR = record
  Yaw: double;
  Pitch: double;
  Roll: double;
end;

var
  DriverGetHMDPos: function(out myHMD: THMD): DWORD; stdcall;
  DriverGetHMDRot: function(out myHMD: THMD): DWORD; stdcall;
  DriverSetCenteringHMD: function (dwIndex: integer): DWORD; stdcall;

  DriverGetControllersPos: function(out myController, myController2: TController): DWORD; stdcall;
  DriverGetControllersRot: function(out myController, myController2: TController): DWORD; stdcall;
  DriverGetControllersBtns: function(out myController, myController2: TController): DWORD; stdcall;
  DriverSetControllerData: function (dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
  DriverSetCenteringCtrls: function (dwIndex: integer): DWORD; stdcall;


  HMDPosDll, HMDRotDll, CtrlsPosDll, CtrlsRotDll, CtrlsBtnsDll: HMODULE;
  Error: boolean;

  HMDUseRot, CtrlsUseRot, CtrlsRotBtns, CtrlsUseBtns: boolean;

  HMDPosOffset, Ctrl1PosOffset, Ctrl2PosOffset: TOffsetPos;
  HMDYPROffset, Ctrl1YPROffset, Ctrl2YPROffset: TOffsetYPR;

{$R *.res}

function fmod(x, y: double): double;
begin
  Result:=y * Frac(x / y);
end;

function MyOffset(f, f2: double): double;
begin
  Result:=fmod(f - f2, 180);
end;

function GetHMDData(out myHMD: THMD): DWORD; stdcall;
var
  HMDRot: THMD; MyStat, StatCount: DWORD;
begin
  if Error = false then begin

    MyStat:=0;
    StatCount:=0;

    MyStat:=MyStat + DriverGetHMDPos(myHMD);
    StatCount:=StatCount + 1;

    if HMDUseRot then begin
      MyStat:=MyStat + DriverGetHMDRot(HMDRot);
      StatCount:=StatCount + 1;

      myHMD.Yaw:=HMDRot.Yaw;
      myHMD.Pitch:=HMDRot.Pitch;
      myHMD.Roll:=HMDRot.Roll;
    end;

    //HMD offset pos
    myHMD.X:=myHMD.X + HMDPosOffset.X;
    myHMD.Y:=myHMD.Y + HMDPosOffset.Y;
    myHMD.Z:=myHMD.Z + HMDPosOffset.Z;

    //HMD offset ypr
    myHMD.Yaw:=MyOffset(myHMD.Yaw, HMDYPROffset.Yaw);
    myHMD.Pitch:=MyOffset(myHMD.Pitch, HMDYPROffset.Pitch);
    myHMD.Roll:=MyOffset(myHMD.Roll, HMDYPROffset.Roll);

    if MyStat = StatCount then
      Result:=1
    else
      Result:=0;
  end else begin
    myHMD.X:=0;
    myHMD.Y:=0;
    myHMD.Z:=0;

    myHMD.Yaw:=0;
    myHMD.Pitch:=0;
    myHMD.Roll:=0;

    Result:=0;
  end;
end;

function GetControllersData(out myController, myController2: TController): DWORD; stdcall;
var
  Ctrl1Pos, Ctrl1Rot, Ctrl1Btns: TController;
  Ctrl2Pos, Ctrl2Rot, Ctrl2Btns: TController;
  MyStat, StatCount: DWORD;
begin
  if Error = false then begin

    MyStat:=0;
    StatCount:=0;

    //Position
    MyStat:=MyStat + DriverGetControllersPos(Ctrl1Pos, Ctrl2Pos);
    StatCount:=StatCount + 1;

    myController:=Ctrl1Pos;
    myController2:=Ctrl2Pos;

    //Rotation
    if CtrlsUseRot then begin
      MyStat:=MyStat + DriverGetControllersRot(Ctrl1Rot, Ctrl2Rot);
      StatCount:=StatCount + 1;

        myController.Yaw:=Ctrl1Rot.Yaw;
        myController.Pitch:=Ctrl1Rot.Pitch;
        myController.Roll:=Ctrl1Rot.Roll;

        myController2.Yaw:=Ctrl2Rot.Yaw;
        myController2.Pitch:=Ctrl2Rot.Pitch;
        myController2.Roll:=Ctrl2Rot.Roll;


        if CtrlsRotBtns then begin
          myController.Buttons:=Ctrl1Rot.Buttons;
          myController.Trigger:=Ctrl1Rot.Trigger;
          myController.ThumbX:=Ctrl1Rot.ThumbX;
          myController.ThumbY:=Ctrl1Rot.ThumbY;

          myController2.Buttons:=Ctrl2Rot.Buttons;
          myController2.Trigger:=Ctrl2Rot.Trigger;
          myController2.ThumbX:=Ctrl2Rot.ThumbX;
          myController2.ThumbY:=Ctrl2Rot.ThumbY;
        end;
    end;

    //Buttons
    if CtrlsUseBtns then begin
      MyStat:=MyStat + DriverGetControllersBtns(Ctrl1Btns, Ctrl2Btns);
      StatCount:=StatCount + 1;

      myController.Buttons:=Ctrl1Btns.Buttons;
      myController.Trigger:=Ctrl1Btns.Trigger;
      myController.ThumbX:=Ctrl1Btns.ThumbX;
      myController.ThumbY:=Ctrl1Btns.ThumbY;

      myController2.Buttons:=Ctrl2Btns.Buttons;
      myController2.Trigger:=Ctrl2Btns.Trigger;
      myController2.ThumbX:=Ctrl2Btns.ThumbX;
      myController2.ThumbY:=Ctrl2Btns.ThumbY;
    end;

    //Controoler1 offset pos
    myController.X:=myController.X + Ctrl1PosOffset.X;
    myController.Y:=myController.Y + Ctrl1PosOffset.Y;
    myController.Z:=myController.Z + Ctrl1PosOffset.Z;

    //Controller offset ypr
    myController.Yaw:=MyOffset(myController.Yaw, Ctrl1YPROffset.Yaw);
    myController.Pitch:=MyOffset(myController.Pitch, Ctrl1YPROffset.Pitch);
    myController.Roll:=MyOffset(myController.Roll, Ctrl1YPROffset.Roll);

    //Controoler2 offset pos
    myController2.X:=myController2.X + Ctrl2PosOffset.X;
    myController2.Y:=myController2.Y + Ctrl2PosOffset.Y;
    myController2.Z:=myController2.Z + Ctrl2PosOffset.Z;

    //Controller offset ypr
    myController2.Yaw:=MyOffset(myController2.Yaw, Ctrl2YPROffset.Yaw);
    myController2.Pitch:=MyOffset(myController2.Pitch, Ctrl2YPROffset.Pitch);
    myController2.Roll:=MyOffset(myController2.Roll, Ctrl2YPROffset.Roll);

    if MyStat = StatCount then
      Result:=1
    else
      Result:=0;
  end else
    Result:=0;
end;

function SetControllerData(dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
begin
  Result:=DriverSetControllerData(dwIndex, MotorSpeed);
end;

function SetCentering(dwIndex: integer): DWORD; stdcall;
begin
  case dwIndex of
    0: Result:=DriverSetCenteringHMD(0);
    1: Result:=DriverSetCenteringCtrls(1);
    2: Result:=DriverSetCenteringCtrls(2);
    else
      Result:=0;
  end;
end;

procedure DllMain(Reason: integer);
var
  Ini: TIniFile; Reg: TRegistry; HMDPosDrvPath, HMDRotDrvPath, CtrlsPosDrvPath, CtrlsRotDrvPath, CtrlsBtnsDrvPath: string;
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
        Error:=false;
        Reg:=TRegistry.Create;
        Reg.RootKey:=HKEY_CURRENT_USER;
        if Reg.OpenKey('\Software\TrueOpenVR', false) = false then Error:=true;
        if DirectoryExists(Reg.ReadString('Drivers')) = false then Error:=true;

        if FileExists(Reg.ReadString('Drivers') + 'SplitterAdvance.ini') = false then Error:=true;

        if Error = false then begin
          Ini:=TIniFile.Create(Reg.ReadString('Drivers') + 'SplitterAdvance.ini');

          HMDUseRot:=false;
          CtrlsUseRot:=false;
          CtrlsRotBtns:=false;
          CtrlsUseBtns:=false;

          //HMD
          HMDPosDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('HMD', 'Position', '');
          HMDRotDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('HMD', 'Rotation', '');

          //Different locales have different delimiters, so it will be easier to use everywhere delimiter "." in configs.
          try
            HMDPosOffset.X:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetX', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            HMDPosOffset.Y:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetY', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            HMDPosOffset.Z:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetZ', '0'), '.', DecimalSeparator, [rfReplaceAll]));

            HMDYPROffset.Yaw:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetYaw', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            HMDYPROffset.Pitch:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetPitch', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            HMDYPROffset.Roll:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetRoll', '0'), '.', DecimalSeparator, [rfReplaceAll]));
          except
            HMDPosOffset.X:=0;
            HMDPosOffset.Y:=0;
            HMDPosOffset.Z:=0;

            HMDYPROffset.Yaw:=0;
            HMDYPROffset.Pitch:=0;
            HMDYPROffset.Roll:=0;
          end;

          //Don't load the library more than once if the same
          if HMDPosDrvPath <> HMDRotDrvPath then HMDUseRot:=true;

          //Controllers pos and ypr offset
          try
            Ctrl1PosOffset.X:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetX', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl1PosOffset.Y:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetY', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl1PosOffset.Z:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetZ', '0'), '.', DecimalSeparator, [rfReplaceAll]));

            Ctrl1YPROffset.Yaw:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetYaw', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl1YPROffset.Pitch:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetPitch', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl1YPROffset.Roll:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetRoll', '0'), '.', DecimalSeparator, [rfReplaceAll]));
          except
            Ctrl1PosOffset.X:=0;
            Ctrl1PosOffset.Y:=0;
            Ctrl1PosOffset.Z:=0;

            Ctrl1YPROffset.Yaw:=0;
            Ctrl1YPROffset.Pitch:=0;
            Ctrl1YPROffset.Roll:=0;
          end;

          try
            Ctrl2PosOffset.X:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetX', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl2PosOffset.Y:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetY', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl2PosOffset.Z:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetZ', '0'), '.', DecimalSeparator, [rfReplaceAll]));

            Ctrl2YPROffset.Yaw:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetYaw', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl2YPROffset.Pitch:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetPitch', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl2YPROffset.Roll:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetRoll', '0'), '.', DecimalSeparator, [rfReplaceAll]));
          except
            Ctrl2PosOffset.X:=0;
            Ctrl2PosOffset.Y:=0;
            Ctrl2PosOffset.Z:=0;

            Ctrl2YPROffset.Yaw:=0;
            Ctrl2YPROffset.Pitch:=0;
            Ctrl2YPROffset.Roll:=0;
          end;

          CtrlsPosDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controllers', 'Position', '');
          CtrlsRotDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controllers', 'Rotation', '');
          CtrlsBtnsDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controllers', 'Buttons', '');

          //Don't load the library more than once if the same
          if CtrlsPosDrvPath <> CtrlsRotDrvPath then CtrlsUseRot:=true;

          if (CtrlsUseRot) and (CtrlsRotDrvPath = CtrlsBtnsDrvPath) then CtrlsRotBtns:=true;

          if (CtrlsRotBtns = false) and (CtrlsPosDrvPath <> CtrlsBtnsDrvPath) then
            CtrlsUseBtns:=true;

          Ini.Free;

          if (FileExists(HMDPosDrvPath) = false) or
              (FileExists(HMDRotDrvPath) = false) or
              (FileExists(CtrlsPosDrvPath) = false) or
              (FileExists(CtrlsRotDrvPath) = false) or
              (FileExists(CtrlsBtnsDrvPath) = false) then Error:=true;

          Reg.CloseKey;
        end;

        if Error = false then begin

          //HMD
          HMDPosDll:=LoadLibrary(PChar(HMDPosDrvPath));
          @DriverGetHMDPos:=GetProcAddress(HMDPosDll, 'GetHMDData');

          if HMDUseRot then begin
            HMDRotDll:=LoadLibrary(PChar(HMDRotDrvPath));
            @DriverGetHMDRot:=GetProcAddress(HMDRotDll, 'GetHMDData');
            @DriverSetCenteringHMD:=GetProcAddress(HMDRotDll, 'SetCentering');
          end else
            @DriverSetCenteringHMD:=GetProcAddress(HMDPosDll, 'SetCentering');

          //Controllers
          CtrlsPosDll:=LoadLibrary(PChar(CtrlsPosDrvPath));
          @DriverGetControllersPos:=GetProcAddress(CtrlsPosDll, 'GetControllersData');
          @DriverSetControllerData:=GetProcAddress(CtrlsPosDll, 'SetControllerData');
          @DriverSetCenteringCtrls:=GetProcAddress(CtrlsPosDll, 'SetCentering');

          if CtrlsUseRot then begin
            CtrlsRotDll:=LoadLibrary(PChar(CtrlsRotDrvPath));
            @DriverGetControllersRot:=GetProcAddress(CtrlsRotDll, 'GetControllersData');
            @DriverSetControllerData:=GetProcAddress(CtrlsRotDll, 'SetControllerData');
            @DriverSetCenteringCtrls:=GetProcAddress(CtrlsRotDll, 'SetCentering');
          end;

          if CtrlsUseBtns then begin
            CtrlsBtnsDll:=LoadLibrary(PChar(CtrlsBtnsDrvPath));
            @DriverGetControllersBtns:=GetProcAddress(CtrlsBtnsDll, 'GetControllersData');
            @DriverSetControllerData:=GetProcAddress(CtrlsBtnsDll, 'SetControllerData');
          end;

        end;
        Reg.Free;
      end;

    DLL_PROCESS_DETACH:
      if Error = false then begin

        //HMD dlls
        FreeLibrary(HMDPosDll);

        if HMDUseRot then
          FreeLibrary(HMDRotDll);

        //Controllers dlls
        FreeLibrary(CtrlsPosDll);

        if CtrlsUseRot then
          FreeLibrary(CtrlsRotDll);

        if CtrlsUseBtns then
          FreeLibrary(CtrlsBtnsDll);
      end;
  end;
end;

exports
  GetHMDData index 1, GetControllersData index 2, SetControllerData index 3, SetCentering index 4;

begin
  DllProc:=@DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.
