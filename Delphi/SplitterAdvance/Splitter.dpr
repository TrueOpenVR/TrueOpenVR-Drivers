library Splitter;

uses
  SysUtils, Classes, Windows, IniFiles, Registry;

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

var
  HMDPosDll, HMDRotDll, Ctrl1PosDll, Ctrl1RotDll, Ctrl2PosDll, Ctrl2RotDll: HMODULE;
  Error: boolean;
  
  DriverGetHMDPos: function(out myHMD: THMD): DWORD; stdcall;
  DriverGetHMDRot: function(out myHMD: THMD): DWORD; stdcall;
  DriverSetCenteringHMD: function (dwIndex: integer): DWORD; stdcall;

  DriverGetController1Pos: function(out myController, myController2: TController): DWORD; stdcall;
  DriverGetController1Rot: function(out myController, myController2: TController): DWORD; stdcall;
  DriverSetController1Data: function (dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
  DriverSetCenteringCtrls1: function (dwIndex: integer): DWORD; stdcall;

  DriverGetController2Pos: function(out myController, myController2: TController): DWORD; stdcall;
  DriverGetController2Rot: function(out myController, myController2: TController): DWORD; stdcall;
  DriverSetController2Data: function (dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
  DriverSetCenteringCtrls2: function (dwIndex: integer): DWORD; stdcall;

  CtrlIndex1, CtrlIndex2: Byte;

{$R *.res}

function GetHMDData(out myHMD: THMD): DWORD; stdcall;
var
  HMD1, HMD2: THMD;
begin
  if (DriverGetHMDPos(HMD1) = 1) and (DriverGetHMDRot(HMD2) = 1) then begin
    HMD1.Yaw:=HMD2.Yaw;
    HMD1.Pitch:=HMD2.Pitch;
    HMD1.Roll:=HMD2.Roll;
    myHMD:=HMD1;
    Result:=1;
  end else
    Result:=0;
end;

function GetControllersData(out myController, myController2: TController): DWORD; stdcall;
var
  Ctrl1Pos, Ctrl1Rot, Ctrl2Pos, Ctrl2Rot, Ctrl3Pos, Ctrl3Rot, Ctrl4Pos, Ctrl4Rot: TController;
begin
  if (DriverGetController1Pos(Ctrl1Pos, Ctrl2Pos) = 1) and (DriverGetController1Rot(Ctrl1Rot, Ctrl2Rot) = 1) and
    (DriverGetController2Pos(Ctrl3Pos, Ctrl4Pos) = 1) and (DriverGetController2Rot(Ctrl3Rot, Ctrl4Rot) = 1) then begin

    //Controller1
    if CtrlIndex1 = 1 then begin

      Ctrl1Pos.Yaw:=Ctrl1Rot.Yaw;
      Ctrl1Pos.Pitch:=Ctrl1Rot.Pitch;
      Ctrl1Pos.Roll:=Ctrl1Rot.Roll;

    end else begin

      Ctrl1Pos.X:=Ctrl2Pos.X;
      Ctrl1Pos.Y:=Ctrl2Pos.Y;
      Ctrl1Pos.Z:=Ctrl2Pos.Z;

      Ctrl1Pos.Yaw:=Ctrl2Rot.Yaw;
      Ctrl1Pos.Pitch:=Ctrl2Rot.Pitch;
      Ctrl1Pos.Roll:=Ctrl2Rot.Roll;
    end;

    myController:=Ctrl1Pos;


    //Controller2

    if CtrlIndex2 = 1 then begin

      Ctrl3Pos.Yaw:=Ctrl3Rot.Yaw;
      Ctrl3Pos.Pitch:=Ctrl3Rot.Pitch;
      Ctrl3Pos.Roll:=Ctrl3Rot.Roll;

    end else begin

      Ctrl3Pos.X:=Ctrl4Pos.X;
      Ctrl3Pos.Y:=Ctrl4Pos.Y;
      Ctrl3Pos.Z:=Ctrl4Pos.Z;

      Ctrl3Pos.Yaw:=Ctrl4Rot.Yaw;
      Ctrl3Pos.Pitch:=Ctrl4Rot.Pitch;
      Ctrl3Pos.Roll:=Ctrl4Rot.Roll;
    end;

    myController2:=Ctrl3Pos;

  end else
    Result:=0;
end;

function SetControllerData(dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
begin
  case dwIndex of
    1: Result:=DriverSetController1Data(CtrlIndex1, MotorSpeed);
    2: Result:=DriverSetController2Data(CtrlIndex2, MotorSpeed);
  else
    Result:=0;
  end;
end;

function SetCentering(dwIndex: integer): DWORD; stdcall;
begin
  case dwIndex of
    0: Result:=DriverSetCenteringHMD(0);
    1: Result:=DriverSetCenteringCtrls1(CtrlIndex1);
    2: Result:=DriverSetCenteringCtrls2(CtrlIndex2);
    else
      Result:=0;
  end;
end;

procedure DllMain(Reason: integer);
var
  Ini: TIniFile; Reg: TRegistry; HMDPosDrvPath, HMDRotDrvPath, Ctrl1PosDrvPath, Ctrl1RotDrvPath, Ctrl2PosDrvPath, Ctrl2RotDrvPath: string;
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

          //HMD
          HMDPosDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('HMD', 'Position', '');
          HMDRotDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('HMD', 'Rotation', '');

          //Controller1
          CtrlIndex1:=Ini.ReadInteger('Controller1', 'Index', 1);
          Ctrl1PosDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller1', 'Position', '');
          Ctrl1RotDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller1', 'Rotation', '');

          //Controller2
          CtrlIndex2:=Ini.ReadInteger('Controller2', 'Index', 2);
          Ctrl2PosDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller2', 'Position', '');
          Ctrl2RotDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller2', 'Rotation', '');

          Ini.Free;

          if (FileExists(HMDPosDrvPath) = false) or
              (FileExists(HMDRotDrvPath) = false) or
              (FileExists(Ctrl1PosDrvPath) = false) or
              (FileExists(Ctrl1RotDrvPath) = false) or
              (FileExists(Ctrl2PosDrvPath) = false) or
              (FileExists(Ctrl2RotDrvPath) = false) then Error:=true;

          Reg.CloseKey;
        end;

        if Error = false then begin

          //HMD
          HMDPosDll:=LoadLibrary(PChar(HMDPosDrvPath));
          HMDRotDll:=LoadLibrary(PChar(HMDRotDrvPath));
          @DriverGetHMDPos:=GetProcAddress(HMDPosDll, 'GetHMDData');
          @DriverGetHMDRot:=GetProcAddress(HMDRotDll, 'GetHMDData');
          @DriverSetCenteringHMD:=GetProcAddress(HMDRotDll, 'SetCentering');

          //Controller1
          Ctrl1PosDll:=LoadLibrary(PChar(Ctrl1PosDrvPath));
          Ctrl1RotDll:=LoadLibrary(PChar(Ctrl1RotDrvPath));
          @DriverGetController1Pos:=GetProcAddress(Ctrl1PosDll, 'GetControllersData');
          @DriverGetController1Rot:=GetProcAddress(Ctrl1RotDll, 'GetControllersData');
          @DriverSetController1Data:=GetProcAddress(Ctrl1RotDll, 'SetControllerData'); //Пока Rot драйвер
          @DriverSetCenteringCtrls1:=GetProcAddress(Ctrl1RotDll, 'SetCentering');

          //Controller2
          Ctrl2PosDll:=LoadLibrary(PChar(Ctrl2PosDrvPath));
          Ctrl2RotDll:=LoadLibrary(PChar(Ctrl2RotDrvPath));
          @DriverGetController2Pos:=GetProcAddress(Ctrl2PosDll, 'GetControllersData');
          @DriverGetController2Rot:=GetProcAddress(Ctrl2RotDll, 'GetControllersData');
          @DriverSetController2Data:=GetProcAddress(Ctrl2RotDll, 'SetControllerData'); //Пока Rot драйвер
          @DriverSetCenteringCtrls2:=GetProcAddress(Ctrl2RotDll, 'SetCentering');

        end;
        Reg.Free;
      end;

    DLL_PROCESS_DETACH:
      if Error = false then begin
        FreeLibrary(HMDPosDll);
        FreeLibrary(HMDRotDll);

        FreeLibrary(Ctrl1PosDll);
        FreeLibrary(Ctrl1RotDll);

        FreeLibrary(Ctrl2PosDll);
        FreeLibrary(Ctrl2RotDll);
      end;
  end;
end;

exports
  GetHMDData index 1, GetControllersData index 2, SetControllerData index 3, SetCentering index 4;

begin
  DllProc:=@DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.
