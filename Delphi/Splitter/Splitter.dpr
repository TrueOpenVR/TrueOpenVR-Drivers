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
  HMDDllHandle, CtrlsDllHandle: HMODULE;
  Error: boolean;
  DriverGetHMDData: function(out myHMD: THMD): DWORD; stdcall;
  DriverGetControllersData: function(out FirstController, SecondController: TController): DWORD; stdcall;
  DriverSetControllerData: function (dwIndex: integer; MotorSpeed: byte): DWORD; stdcall;

{$R *.res}

function GetHMDData(out MyHMD: THMD): DWORD; stdcall;
begin
  Result:=DriverGetHMDData(MyHMD);
end;

function GetControllersData(out FirstController, SecondController: TController): DWORD; stdcall;
begin
  Result:=DriverGetControllersData(FirstController, SecondController);
end;

function SetControllerData(dwIndex: integer; MotorSpeed: byte): DWORD; stdcall;
begin
  Result:=DriverSetControllerData(dwIndex, MotorSpeed);
end;

procedure DllMain(Reason: integer);
var
  Ini: TIniFile; Reg: TRegistry; HMDDrvPath, CtrlsDrvPath: string;
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
        Error:=false;
        Reg:=TRegistry.Create;
        Reg.RootKey:=HKEY_CURRENT_USER;
        if Reg.OpenKey('\Software\TrueOpenVR', false) = false then Error:=true;
        if DirectoryExists(Reg.ReadString('Drivers')) = false then Error:=true;

        if FileExists(Reg.ReadString('Drivers') + 'Splitter.ini') = false then Error:=true;

        if Error = false then begin
          Ini:=TIniFile.Create(Reg.ReadString('Drivers') + 'Splitter.ini');
          HMDDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Drivers', 'HMD', '');
          CtrlsDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Drivers', 'Controllers', '');
          Ini.Free;

          if (FileExists(HMDDrvPath) = false) or (FileExists(CtrlsDrvPath) = false) then Error:=true;

          Reg.CloseKey;
        end;

        if Error = false then begin
          HMDDllHandle:=LoadLibrary(PChar(HMDDrvPath));
          CtrlsDllHandle:=LoadLibrary(PChar(CtrlsDrvPath));
          @DriverGetHMDData:=GetProcAddress(HMDDllHandle, 'GetHMDData');
          @DriverGetControllersData:=GetProcAddress(CtrlsDllHandle, 'GetControllersData');
          @DriverSetControllerData:=GetProcAddress(CtrlsDllHandle, 'SetControllerData');
        end;
        Reg.Free;
      end;

    DLL_PROCESS_DETACH:
      if Error = false then begin
        FreeLibrary(HMDDllHandle);
        FreeLibrary(CtrlsDllHandle);
      end;
  end;
end;

exports
  GetHMDData index 1, GetControllersData index 2, SetControllerData index 3;

begin
  DllProc:=@DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.
