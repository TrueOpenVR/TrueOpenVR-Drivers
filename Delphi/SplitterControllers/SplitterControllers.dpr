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

var
  Ctrl1Dll, Ctrl2Dll: HMODULE;
  Error: boolean;

  DriverGetController1: function(out myController, myController2: TController): DWORD; stdcall;
  DriverGetController2: function(out myController, myController2: TController): DWORD; stdcall;
  DriverSetController1Data: function (dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
  DriverSetController2Data: function (dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
  DriverSetCenteringCtrl1: function (dwIndex: integer): DWORD; stdcall;
  DriverSetCenteringCtrl2: function (dwIndex: integer): DWORD; stdcall;

  Ctrl1Index, Ctrl2Index: byte;
  UseScndDrv: boolean;

{$R *.res}

function GetHMDData(out myHMD: THMD): DWORD; stdcall;
begin
  myHMD.X:=0;
  myHMD.Y:=0;
  myHMD.Z:=0;
  myHMD.Yaw:=0;
  myHMD.Pitch:=0;
  myHMD.Roll:=0;
  
  Result:=0;
end;

function GetControllersData(out myController, myController2: TController): DWORD; stdcall;
var
  Ctrl1, Ctrl2: TController;
  MyStat, StatCount: DWORD;
begin
  if Error = false then begin

    MyStat:=0;
    StatCount:=0;

    //Controller 1
    MyStat:=MyStat + DriverGetController1(Ctrl1, Ctrl2);
    StatCount:=StatCount + 1;

    if Ctrl1Index = 1 then begin
      myController:=Ctrl1;
      myController2:=Ctrl2; //if not use second driver
    end else begin
      myController2:=Ctrl1;
      myController:=Ctrl2;
    end;

    //Controller 2
    if (UseScndDrv) then begin
      MyStat:=MyStat + DriverGetController2(Ctrl1, Ctrl2);
      StatCount:=StatCount + 1;

      if Ctrl2Index = 1 then
        myController2:=Ctrl1
      else
        myController2:=Ctrl2;
    end;

    if MyStat = StatCount then
      Result:=1
    else
      Result:=0;
      
  end else
    Result:=0;
end;

function SetControllerData(dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
var
  MyStat, StatCount: DWORD;
begin
  case dwIndex of
    1: Result:=DriverSetController1Data(Ctrl1Index, MotorSpeed);
    2: if UseScndDrv then Result:=DriverSetController2Data(Ctrl2Index, MotorSpeed) else Result:=DriverSetController1Data(Ctrl2Index, MotorSpeed);
  else
    Result:=0;
  end;
end;

function SetCentering(dwIndex: integer): DWORD; stdcall;
begin
  case dwIndex of
    0: Result:=0;
    1: Result:=DriverSetCenteringCtrl1(Ctrl1Index);
    2: if UseScndDrv then Result:=DriverSetCenteringCtrl2(Ctrl2Index) else Result:=DriverSetCenteringCtrl1(Ctrl2Index);
  else
    Result:=0;
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
          @DriverSetCenteringCtrl1:=GetProcAddress(Ctrl1Dll, 'SetCentering');

          //Controller2
          if UseScndDrv then begin
            Ctrl2Dll:=LoadLibrary(PChar(Ctrl2DrvPath));
            @DriverGetController2:=GetProcAddress(Ctrl2Dll, 'GetControllersData');
            @DriverSetController2Data:=GetProcAddress(Ctrl2Dll, 'SetControllerData');
            @DriverSetCenteringCtrl2:=GetProcAddress(Ctrl2Dll, 'SetCentering');
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
  GetHMDData index 1, GetControllersData index 2, SetControllerData index 3, SetCentering index 4;

begin
  DllProc:=@DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.

