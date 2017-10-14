library Fake;

uses
  Windows;

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

{$R *.res}

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

function GetControllersData(out myController, myController2: TController): DWORD; stdcall;
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

function SetControllerData(dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
begin
  Result:=1;
end;

function SetCentering(dwIndex: integer): DWORD; stdcall;
begin
  Result:=0;
end;

procedure DllMain(Reason: integer);
begin
  {case Reason of
    DLL_PROCESS_ATTACH:
    DLL_PROCESS_DETACH:
  end;}
end;

exports
  GetHMDData index 1, GetControllersData index 2, SetControllerData index 3, SetCentering index 4;

begin
  DllProc:=@DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.
 