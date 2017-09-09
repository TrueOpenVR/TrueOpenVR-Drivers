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
    Buttons: dword;
    Trigger: byte;
    ThumbX: smallint;
    ThumbY: smallint;
end;
  Controller = _Controller;
  TController = Controller;

var
  HMDDllHandle, CtrlsDllHandle: HMODULE;
  DriverGetHMDData: function(out myHMD: THMD): DWORD; stdcall;
  DriverGetControllersData: function(out myController, myController2: TController): DWORD; stdcall;
  DriverSetControllerData: function (dwIndex: integer; MotorSpeed: dword): DWORD; stdcall;
  DriverSetCenteringHMD: function (dwIndex: integer): DWORD; stdcall;
  DriverSetCenteringCtrls: function (dwIndex: integer): DWORD; stdcall;

{$R *.res}

function GetHMDData(out myHMD: THMD): DWORD; stdcall;
begin
  Result:=DriverGetHMDData(myHMD);
end;

function GetControllersData(out myController, myController2: TController): DWORD; stdcall;
begin
  Result:=DriverGetControllersData(myController, myController2);
end;

function SetControllerData(dwIndex: integer; MotorSpeed: dword): DWORD; stdcall;
begin
  Result:=DriverSetControllerData(dwIndex, MotorSpeed);
end;

function SetCentering(dwIndex: integer): DWORD; stdcall;
begin
  case dwIndex of
    0: Result:=DriverSetCenteringHMD(0);
    1: Result:=DriverSetCenteringCtrls(1);
    2: Result:=DriverSetCenteringCtrls(2);
  end;
end;

procedure DllMain(Reason: integer);
var
  Ini: TIniFile; Reg: TRegistry; HMDDrvPath, CtrlsDrvPath: string; Error: boolean;
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
          @DriverSetCenteringHMD:=GetProcAddress(HMDDllHandle, 'SetCentering');
          @DriverSetCenteringCtrls:=GetProcAddress(CtrlsDllHandle, 'SetCentering');
        end;
        Reg.Free;
      end;

    DLL_PROCESS_DETACH:
      begin
        FreeLibrary(HMDDllHandle);
        FreeLibrary(CtrlsDllHandle);
      end;
  end;
end;

exports
  GetHMDData index 1, GetControllersData index 2, SetControllerData index 3, SetCentering index 4;

begin
  DllProc:=@DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.
