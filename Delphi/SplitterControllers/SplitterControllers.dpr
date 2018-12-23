library SplitterControllers;

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
    Trigger: single;
    AxisX: single;
    AxisY: single;
end;
  Controller = _Controller;
  TController = Controller;

const
  TOVR_SUCCESS = 0;
  TOVR_FAILURE = 1;

var
  Ctrl1Dll, Ctrl2Dll: HMODULE;
  Error: boolean;

  DriverGetController1: function(out FirstController, SecondController: TController): DWORD; stdcall;
  DriverGetController2: function(out FirstController, SecondController: TController): DWORD; stdcall;
  DriverSetController1Data: function (dwIndex: integer; MotorSpeed: byte): DWORD; stdcall;
  DriverSetController2Data: function (dwIndex: integer; MotorSpeed: byte): DWORD; stdcall;

  Ctrl1Index, Ctrl2Index: byte;
  UseScndDrv: boolean;

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
var
  Ctrl1, Ctrl2: TController;
  MyStat, StatCount: DWORD;
begin
  if Error = false then begin

    MyStat:=0;
    StatCount:=0;

    //Controller 1
    if DriverGetController1(Ctrl1, Ctrl2) = TOVR_SUCCESS then
      MyStat:=MyStat + 1;
    StatCount:=StatCount + 1;

    if Ctrl1Index = 1 then begin
      FirstController:=Ctrl1;
      SecondController:=Ctrl2; //if not use second driver
    end else begin
      SecondController:=Ctrl1;
      FirstController:=Ctrl2;
    end;

    //Controller 2
    if (UseScndDrv) then begin
      if DriverGetController2(Ctrl1, Ctrl2) = TOVR_SUCCESS then
        MyStat:=MyStat + 1;
      StatCount:=StatCount + 1;

      if Ctrl2Index = 1 then
        SecondController:=Ctrl1
      else
        SecondController:=Ctrl2;
    end;

    if MyStat = StatCount then
      Result:=TOVR_SUCCESS
    else
      Result:=TOVR_FAILURE;
      
  end else
    Result:=TOVR_FAILURE;
end;

function SetControllerData(dwIndex: integer; MotorSpeed: byte): DWORD; stdcall;
var
  MyStat, StatCount: DWORD;
begin
  case dwIndex of
    1: Result:=DriverSetController1Data(Ctrl1Index, MotorSpeed);
    2: if UseScndDrv then Result:=DriverSetController2Data(Ctrl2Index, MotorSpeed) else Result:=DriverSetController1Data(Ctrl2Index, MotorSpeed);
  else
    Result:=TOVR_SUCCESS;
  end;
end;

procedure DllMain(Reason: integer);
var
  Ini: TIniFile; Reg: TRegistry; Ctrl1DrvPath, Ctrl2DrvPath: string;
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
        Error:=false;
        Reg:=TRegistry.Create;
        Reg.RootKey:=HKEY_CURRENT_USER;
        if Reg.OpenKey('\Software\TrueOpenVR', false) = false then Error:=true;
        if DirectoryExists(Reg.ReadString('Drivers')) = false then Error:=true;

        if FileExists(Reg.ReadString('Drivers') + 'SplitterControllers.ini') = false then Error:=true;

        if Error = false then begin
          Ini:=TIniFile.Create(Reg.ReadString('Drivers') + 'SplitterControllers.ini');

          UseScndDrv:=false;

          Ctrl1Index:=Ini.ReadInteger('Controller1', 'Index', 1);
          Ctrl2Index:=Ini.ReadInteger('Controller2', 'Index', 2);

          Ctrl1DrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller1', 'Driver', '');
          Ctrl2DrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller2', 'Driver', '');

          //Don't load the library more than once if the same
          if (Ctrl1DrvPath <> Ctrl2DrvPath) then UseScndDrv:=true;

          Ini.Free;

          if (FileExists(Ctrl1DrvPath) = false) or
              (FileExists(Ctrl2DrvPath) = false) then Error:=true;

          Reg.CloseKey;
        end;

        if Error = false then begin

          //Controller1
          Ctrl1Dll:=LoadLibrary(PChar(Ctrl1DrvPath));
          @DriverGetController1:=GetProcAddress(Ctrl1Dll, 'GetControllersData');
          @DriverSetController1Data:=GetProcAddress(Ctrl1Dll, 'SetControllerData');

          //Controller2
          if UseScndDrv then begin
            Ctrl2Dll:=LoadLibrary(PChar(Ctrl2DrvPath));
            @DriverGetController2:=GetProcAddress(Ctrl2Dll, 'GetControllersData');
            @DriverSetController2Data:=GetProcAddress(Ctrl2Dll, 'SetControllerData');
          end;

        end;
        Reg.Free;
      end;

    DLL_PROCESS_DETACH:
      if Error = false then begin

        FreeLibrary(Ctrl1Dll);

        if UseScndDrv then
          FreeLibrary(Ctrl2Dll);
      end;
  end;
end;

exports
  GetHMDData index 1, GetControllersData index 2, SetControllerData index 3;

begin
  DllProc:=@DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.

