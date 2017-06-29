library Fake;

uses
  SysUtils, Classes, Windows, IniFiles, Registry, Dialogs;

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

  //VR Init
  PVRInfo = ^TVRInfo;
  _VRInfo = record
    ScreenIndex: integer;
    Scale: boolean;
    UserWidth: integer;
    UserHeight: integer;
  end;
  VRInfo = _VRInfo;
  TVRInfo = VRInfo;

  //Controllers
  PControllers = ^TControllers;
  _Controllers = record
    X: double;
    Y: double;
    Z: double;
    Yaw: double;
    Pitch: double;
    Roll: double;
    Buttons: dword;
    Trigger: byte;
    ThumbX: smallint;
    ThumbY: smallint;
end;
  Controllers = _Controllers;
  TControllers = Controllers;

{$R *.res}

function GetInfo(out myVRInfo: TVRInfo): DWORD; stdcall;
var
  Ini: TIniFile; Reg: TRegistry;
begin
  Reg:=TRegistry.Create;
  Reg.RootKey:=HKEY_CURRENT_USER;
  Result:=0;
  if Reg.OpenKey('\Software\TrueOpenVR', false)=false then Exit;
  if FileExists(Reg.ReadString('Path') + 'TOVR.ini')=false then Exit;

  Ini:=TIniFile.Create(Reg.ReadString('Path') + 'TOVR.ini');
  MyVRInfo.ScreenIndex:=Ini.ReadInteger('VRInit', 'ScreenIndex', 0);
  myVRInfo.Scale:=Ini.ReadBool('VRInit', 'Scale', false);
  myVRInfo.UserWidth:=Ini.ReadInteger('VRInit', 'UserWidth', 1280);
  myVRInfo.UserHeight:=Ini.ReadInteger('VRInit', 'UserHeight', 720);
  Ini.Free;
  Reg.Free;
  Result:=1;
end;

function GetHMDData(out myHMD: THMD): DWORD; stdcall;
begin
  myHMD.X:=0.03214;
  myHMD.Y:=-0.01251;
  myHMD.Z:=0.017812;
  myHMD.Yaw:=0.01;
  myHMD.Pitch:=-0.01;
  myHMD.Roll:=0.01;

  Result:=1;
end;

function GetControllersData(out myController, myController2: TControllers): DWORD; stdcall;
begin
  //Controller 1
  myController.X:=1;
  myController.Y:=2;
  myController.Z:=3;

  myController.Yaw:=4;
  myController.Pitch:=5;
  myController.Roll:=6;

  myController.Buttons:=1;
  myController.Trigger:=7;
  myController.ThumbX:=8;
  myController.ThumbY:=9;

  //Controller 2
  myController2.X:=10;
  myController2.Y:=11;
  myController2.Z:=12;

  myController2.Yaw:=13;
  myController2.Pitch:=14;
  myController2.Roll:=15;

  myController2.Buttons:=2;
  myController2.Trigger:=16;
  myController2.ThumbX:=17;
  myController2.ThumbY:=18;

  Result:=1;
end;

function SetControllerData(dwIndex: integer; MotorSpeed: dword): DWORD; stdcall;
begin
  Result:=1;
end;

function SetCentering(dwIndex: integer): DWORD; stdcall;
begin
  Result:=0;
end;

exports
  GetInfo index 1, GetHMDData index 2, SetCentering index 3, GetControllersData index 4, SetControllerData index 5;

begin

end.
 