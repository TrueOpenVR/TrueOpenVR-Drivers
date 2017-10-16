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
  myHMD.X:=0.287;
  myHMD.Y:=-0.065;
  myHMD.Z:=0.0905;
  myHMD.Yaw:=27;
  myHMD.Pitch:=79;
  myHMD.Roll:=-40;

  Result:=1;
end;

function GetControllersData(out myController, myController2: TController): DWORD; stdcall;
begin
  //Controller 1
  myController.X:=0.236;
  myController.Y:=0.834;
  myController.Z:=0.712;

  myController.Yaw:=-156;
  myController.Pitch:=82;
  myController.Roll:=-10;

  myController.Buttons:=1;
  myController.Trigger:=135;
  myController.ThumbX:=-6395;
  myController.ThumbY:=24459;

  //Controller 2
  myController2.X:=0.695;
  myController2.Y:=0.431;
  myController2.Z:=0.784;

  myController2.Yaw:=-55;
  myController2.Pitch:=83;
  myController2.Roll:=-27;

  myController2.Buttons:=2;
  myController2.Trigger:=255;
  myController2.ThumbX:=-200;
  myController2.ThumbY:=15287;

  Result:=1;
end;

function SetControllerData(dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
begin
  Result:=1;
end;

function SetCentering(dwIndex: integer): DWORD; stdcall;
begin
  Result:=1;
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
 