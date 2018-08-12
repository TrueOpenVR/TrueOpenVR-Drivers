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

var
  HMDPosDll, HMDRotDll, Ctrl1PosDll, Ctrl1RotDll, Ctrl1BtnsDll, Ctrl2PosDll, Ctrl2RotDll, Ctrl2BtnsDll: HMODULE;
  Error: boolean;
  
  DriverGetHMDPos: function(out myHMD: THMD): DWORD; stdcall;
  DriverGetHMDRot: function(out myHMD: THMD): DWORD; stdcall;
  DriverSetCenteringHMD: function (dwIndex: integer): DWORD; stdcall;

  DriverGetController1Pos: function(out myController, myController2: TController): DWORD; stdcall;
  DriverGetController1Rot: function(out myController, myController2: TController): DWORD; stdcall;
  DriverGetController1Btns: function(out myController, myController2: TController): DWORD; stdcall;
  DriverSetController1Data: function (dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
  DriverSetCenteringCtrls1: function (dwIndex: integer): DWORD; stdcall;

  DriverGetController2Pos: function(out myController, myController2: TController): DWORD; stdcall;
  DriverGetController2Rot: function(out myController, myController2: TController): DWORD; stdcall;
  DriverGetController2Btns: function(out myController, myController2: TController): DWORD; stdcall;
  DriverSetController2Data: function (dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
  DriverSetCenteringCtrls2: function (dwIndex: integer): DWORD; stdcall;

  CtrlIndex1Pos, CtrlIndex1Rot, CtrlIndex1Btns: Byte;
  CtrlIndex2Pos, CtrlIndex2Rot, CtrlIndex2Btns: Byte;

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
  Ctrl1Pos, Ctrl1Rot, Ctrl1Btns: TController;
  Ctrl2Pos, Ctrl2Rot, Ctrl2Btns: TController;
begin
  if Error = false then begin
    //Controller1
    DriverGetController1Pos(Ctrl1Pos, Ctrl2Pos);
    DriverGetController1Rot(Ctrl1Rot, Ctrl2Rot);
    DriverGetController1Btns(Ctrl1Btns, Ctrl2Btns);

    if CtrlIndex1Pos = 1 then begin
      myController.X:=Ctrl1Pos.X;
      myController.Y:=Ctrl1Pos.Y;
      myController.Z:=Ctrl1Pos.Z;
    end else begin
      myController.X:=Ctrl2Pos.X;
      myController.Y:=Ctrl2Pos.Y;
      myController.Z:=Ctrl2Pos.Z;
    end;

    if CtrlIndex1Rot = 1 then begin
      myController.Yaw:=Ctrl1Rot.Yaw;
      myController.Pitch:=Ctrl1Rot.Pitch;
      myController.Roll:=Ctrl1Rot.Roll;
    end else begin
      myController.Yaw:=Ctrl2Rot.Yaw;
      myController.Pitch:=Ctrl2Rot.Pitch;
      myController.Roll:=Ctrl2Rot.Roll;
    end;

    if CtrlIndex1Btns = 1 then begin
      myController.Buttons:=Ctrl1Btns.Buttons;
      myController.Trigger:=Ctrl1Btns.Trigger;
      myController.ThumbX:=Ctrl1Btns.ThumbX;
      myController.ThumbY:=Ctrl1Btns.ThumbY;
    end else begin
      myController.Buttons:=Ctrl2Btns.Buttons;
      myController.Trigger:=Ctrl2Btns.Trigger;
      myController.ThumbX:=Ctrl2Btns.ThumbX;
      myController.ThumbY:=Ctrl2Btns.ThumbY;
    end;

    //Controller2
    DriverGetController2Pos(Ctrl1Pos, Ctrl2Pos);
    DriverGetController2Rot(Ctrl1Rot, Ctrl2Rot);
    DriverGetController2Btns(Ctrl1Btns, Ctrl2Btns);

    if CtrlIndex2Pos = 1 then begin
      myController2.X:=Ctrl1Pos.X;
      myController2.Y:=Ctrl1Pos.Y;
      myController2.Z:=Ctrl1Pos.Z;
    end else begin
      myController2.X:=Ctrl2Pos.X;
      myController2.Y:=Ctrl2Pos.Y;
      myController2.Z:=Ctrl2Pos.Z;
    end;

    if CtrlIndex2Rot = 1 then begin
      myController2.Yaw:=Ctrl1Rot.Yaw;
      myController2.Pitch:=Ctrl1Rot.Pitch;
      myController2.Roll:=Ctrl1Rot.Roll;
    end else begin
      myController2.Yaw:=Ctrl2Rot.Yaw;
      myController2.Pitch:=Ctrl2Rot.Pitch;
      myController2.Roll:=Ctrl2Rot.Roll;
    end;

    if CtrlIndex2Btns = 1 then begin
      myController2.Buttons:=Ctrl1Btns.Buttons;
      myController2.Trigger:=Ctrl1Btns.Trigger;
      myController2.ThumbX:=Ctrl1Btns.ThumbX;
      myController2.ThumbY:=Ctrl1Btns.ThumbY;
    end else begin
      myController2.Buttons:=Ctrl2Btns.Buttons;
      myController2.Trigger:=Ctrl2Btns.Trigger;
      myController2.ThumbX:=Ctrl2Btns.ThumbX;
      myController2.ThumbY:=Ctrl2Btns.ThumbY;
    end;

    Result:=1;
  end else
    Result:=0;
end;

function SetControllerData(dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
begin
  case dwIndex of
    1: Result:=DriverSetController1Data(CtrlIndex1Btns, MotorSpeed);
    2: Result:=DriverSetController2Data(CtrlIndex2Btns, MotorSpeed);
  else
    Result:=0;
  end;
end;

function SetCentering(dwIndex: integer): DWORD; stdcall;
begin
  case dwIndex of
    0: Result:=DriverSetCenteringHMD(0);
    1: Result:=DriverSetCenteringCtrls1(CtrlIndex1Rot);
    2: Result:=DriverSetCenteringCtrls2(CtrlIndex2Rot);
    else
      Result:=0;
  end;
end;

procedure DllMain(Reason: integer);
var
  Ini: TIniFile; Reg: TRegistry; HMDPosDrvPath, HMDRotDrvPath, Ctrl1PosDrvPath, Ctrl1RotDrvPath, Ctrl1BtnsDrvPath, Ctrl2PosDrvPath, Ctrl2RotDrvPath, Ctrl2BtnsDrvPath: string;
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
          CtrlIndex1Pos:=Ini.ReadInteger('Controller1', 'PosIndex', 1);
          CtrlIndex1Rot:=Ini.ReadInteger('Controller1', 'RotIndex', 1);
          CtrlIndex1Btns:=Ini.ReadInteger('Controller1', 'BtnsIndex', 1);

          Ctrl1PosDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller1', 'Position', '');
          Ctrl1RotDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller1', 'Rotation', '');
          Ctrl1BtnsDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller1', 'Buttons', '');

          //Controller2
          CtrlIndex2Pos:=Ini.ReadInteger('Controller2', 'PosIndex', 2);
          CtrlIndex2Rot:=Ini.ReadInteger('Controller2', 'RotIndex', 2);
          CtrlIndex2Btns:=Ini.ReadInteger('Controller2', 'BtnsIndex', 2);

          Ctrl2PosDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller2', 'Position', '');
          Ctrl2RotDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller2', 'Rotation', '');
          Ctrl2BtnsDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller2', 'Buttons', '');

          Ini.Free;

          if (FileExists(HMDPosDrvPath) = false) or
              (FileExists(HMDRotDrvPath) = false) or
              (FileExists(Ctrl1PosDrvPath) = false) or
              (FileExists(Ctrl1RotDrvPath) = false) or
              (FileExists(Ctrl1BtnsDrvPath) = false) or
              (FileExists(Ctrl2PosDrvPath) = false) or
              (FileExists(Ctrl2RotDrvPath) = false) or
              (FileExists(Ctrl2BtnsDrvPath) = false) then Error:=true;

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
          Ctrl1BtnsDll:=LoadLibrary(PChar(Ctrl1BtnsDrvPath));
          @DriverGetController1Pos:=GetProcAddress(Ctrl1PosDll, 'GetControllersData');
          @DriverGetController1Rot:=GetProcAddress(Ctrl1RotDll, 'GetControllersData');
          @DriverGetController1Btns:=GetProcAddress(Ctrl1BtnsDll, 'GetControllersData');
          @DriverSetController1Data:=GetProcAddress(Ctrl1BtnsDll, 'SetControllerData'); //Arduino
          @DriverSetCenteringCtrls1:=GetProcAddress(Ctrl1RotDll, 'SetCentering');

          //Controller2
          Ctrl2PosDll:=LoadLibrary(PChar(Ctrl2PosDrvPath));
          Ctrl2RotDll:=LoadLibrary(PChar(Ctrl2RotDrvPath));
          Ctrl2BtnsDll:=LoadLibrary(PChar(Ctrl2BtnsDrvPath));
          @DriverGetController2Pos:=GetProcAddress(Ctrl2PosDll, 'GetControllersData');
          @DriverGetController2Rot:=GetProcAddress(Ctrl2RotDll, 'GetControllersData');
          @DriverGetController2Btns:=GetProcAddress(Ctrl2BtnsDll, 'GetControllersData');
          @DriverSetController2Data:=GetProcAddress(Ctrl2BtnsDll, 'SetControllerData'); //Arduino
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
        FreeLibrary(Ctrl1BtnsDll);

        FreeLibrary(Ctrl2PosDll);
        FreeLibrary(Ctrl2RotDll);
        FreeLibrary(Ctrl2BtnsDll);
      end;
  end;
end;

exports
  GetHMDData index 1, GetControllersData index 2, SetControllerData index 3, SetCentering index 4;

begin
  DllProc:=@DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.
