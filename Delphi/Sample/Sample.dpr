library Sample;

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
    Trigger: single;
    AxisX: single;
    AxisY: single;
end;
  Controller = _Controller;
  TController = Controller;

const
  TOVR_SUCCESS = 0;
  TOVR_FAILURE = 1;

{$R *.res}

function GetHMDData(out MyHMD: THMD): DWORD; stdcall;
begin
  MyHMD.X:=0;
  MyHMD.Y:=0;
  MyHMD.Z:=0;
  MyHMD.Yaw:=0;
  MyHMD.Pitch:=0;
  MyHMD.Roll:=0;

  Result:=TOVR_FAILURE;
end;

function GetControllersData(out FirstController, SecondController: TController): DWORD; stdcall;
begin
  //Controller 1
  FirstController.X:=0;
  FirstController.Y:=0;
  FirstController.Z:=0;

  FirstController.Yaw:=0;
  FirstController.Pitch:=0;
  FirstController.Roll:=0;

  FirstController.Buttons:=0;
  FirstController.Trigger:=0;
  FirstController.AxisX:=0;
  FirstController.AxisY:=0;

  //Controller 2
  SecondController.X:=0;
  SecondController.Y:=0;
  SecondController.Z:=0;

  SecondController.Yaw:=0;
  SecondController.Pitch:=0;
  SecondController.Roll:=0;

  SecondController.Buttons:=0;
  SecondController.Trigger:=0;
  SecondController.AxisX:=0;
  SecondController.AxisY:=0;

  Result:=TOVR_FAILURE;
end;

function SetControllerData(dwIndex: integer; MotorSpeed: byte): DWORD; stdcall;
begin
  Result:=TOVR_FAILURE;
end;

procedure DllMain(Reason: integer);
begin
  {case Reason of
    DLL_PROCESS_ATTACH:
    DLL_PROCESS_DETACH:
  end;}
end;

exports
  GetHMDData index 1, GetControllersData index 2, SetControllerData index 3;

begin
  DllProc:=@DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.
 