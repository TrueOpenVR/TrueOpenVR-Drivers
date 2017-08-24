library RazorIMU;

uses
  Windows, CPDrv, Math, IniFiles, SysUtils, Registry;

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

type
  TCommPortDrv = class
  private
    CommPortDriver: TCommPortDriver;
  procedure CommPortDriverReceiveData(Sender: TObject; DataPtr: Pointer;
      DataSize: Cardinal);
  public
  constructor Create; reintroduce;
  destructor Destroy; override;
end;

type TRazorIMU = record
    Yaw: double;
    Pitch: double;
    Roll: double;
end;

var
  CommPortDrv: TCommPortDrv;
  PacketBuffer: string;
  YawOffset, PitchOffset, RollOffset: double;
  hTimer: THandle;
  CommPortNum: integer;
  MyRazorIMU: TRazorIMU;
  HMDConnected: boolean;

{$R *.res}

function fmod(x, y: double): double;
begin
  Result:=y * Frac(x / y);
end;

function MyOffset(f, f2: double): double;
begin
  Result:=fmod(f - f2, 180);
end;

function GetHMDData(out myHMD: THMD): DWORD; stdcall;
begin
  myHMD.X:=0;
  myHMD.Y:=0;
  myHMD.Z:=0;

  myHMD.Yaw:=0;
  myHMD.Pitch:=0;
  myHMD.Roll:=0;

  Result:=0;

  if HMDConnected then begin
    myHMD.Yaw:=MyOffset(MyRazorIMU.Yaw, YawOffset);
    myHMD.Pitch:=MyOffset(MyRazorIMU.Pitch, PitchOffset);
    myHMD.Roll:=MyOffset(MyRazorIMU.Roll, RollOffset);

    Result:=1;
  end;
end;

function GetControllersData(out myController, myController2: TController): DWORD; stdcall;
begin
  //Controller 1
  myController.X:=0;
  myController.Y:=0;
  myController.Z:=0;

  myController.Yaw:=0;
  myController.Pitch:=0;
  myController.Roll:=0;

  myController.Buttons:=0;
  myController.Trigger:=0;
  myController.ThumbX:=0;
  myController.ThumbY:=0;

  //Controller 2
  myController2.X:=0;
  myController2.Y:=0;
  myController2.Z:=0;

  myController2.Yaw:=0;
  myController2.Pitch:=0;
  myController2.Roll:=0;

  myController2.Buttons:=0;
  myController2.Trigger:=0;
  myController2.ThumbX:=0;
  myController2.ThumbY:=0;

  Result:=0;
end;

function SetControllerData(dwIndex: integer; MotorSpeed: dword): DWORD; stdcall;
begin
  Result:=0;
end;

function SetCentering(dwIndex: integer): DWORD; stdcall;
begin
  if dwIndex = 0 then begin
    YawOffset:=MyRazorIMU.Yaw;
    PitchOffset:=MyRazorIMU.Pitch;
    RollOffset:=MyRazorIMU.Roll;
    Result:=1;
  end else
    Result:=0;
end;

procedure TCommPortDrv.CommPortDriverReceiveData(Sender: TObject;
  DataPtr: Pointer; DataSize: Cardinal);
var
  i: integer;
  s: string;
begin
  s:='';
  for i:=0 to DataSize - 1 do
    s:=s + (PChar(DataPtr)[i]);

  PacketBuffer:=PacketBuffer + s;
end;

constructor TCommPortDrv.Create;
begin
  CommPortDriver:=TCommPortDriver.Create(nil);
  CommPortDriver.BaudRateValue:=115200;
  CommPortDriver.PortName:='\\.\Com' + IntToStr(CommPortNum);
  CommPortDriver.DataBits:=db8BITS;
  CommPortDriver.OnReceiveData:=CommPortDriverReceiveData;
  CommPortDriver.Connect;
  if CommPortDriver.Connect = true then
    HMDConnected:=true
  else
    HMDConnected:=false;
end;

destructor TCommPortDrv.Destroy;
begin
  CommPortDriver.Free;
  inherited destroy;
end;

procedure ReadBuffer(WND: HWND; uMsg: UINT; idEvent: UINT; dwTime: DWORD); stdcall;
var
  s: string;
begin
  if Length(PacketBuffer) > 0 then begin
    s:=Copy(PacketBuffer, 1, Pos(#13, PacketBuffer) - 1);

    delete(PacketBuffer, 1, Pos(#13, PacketBuffer) + 1);
    if Copy(s, 1, 5)='#YPR=' then begin
      Delete(s, 1, 5);
      MyRazorIMU.Yaw:=StrToFloat(StringReplace(copy(s, 1, pos(',', s) - 1), '.', ',', [rfIgnoreCase]));

      Delete(s, 1, pos(',', s));
      MyRazorIMU.Pitch:=StrToFloat(StringReplace(copy(s, 1, pos(',', s) - 1), '.', ',', [rfIgnoreCase]));

      Delete(s, 1, pos(',', s));
      MyRazorIMU.Roll:=StrToFloat(StringReplace(Trim(s), '.', ',', [rfIgnoreCase]));

    end;
  end;
end;

procedure DllMain(Reason: integer);
begin
  case Reason of
    DLL_PROCESS_DETACH:
      begin
        KillTimer(0, hTimer);
        CommPortDrv.Free;
      end;
  end;
end;

function GetDriversPath: string;
var
  Reg: TRegistry;
begin
  Reg:=TRegistry.Create;
  Reg.RootKey:=HKEY_CURRENT_USER;
  if Reg.OpenKey('\Software\TrueOpenVR', false) = true then begin
    if DirectoryExists(Reg.ReadString('Drivers')) then
      Result:=Reg.ReadString('Drivers')
    else
      Result:='';
  end;
  Reg.CloseKey;
  Reg.Free;
end;

exports
  GetHMDData index 1, GetControllersData index 2, SetControllerData index 3, SetCentering index 4;

var
  Ini: TIniFile;
begin
  DllProc:=@DllMain;
  DllProc(DLL_PROCESS_ATTACH);

  hTimer:=SetTimer(0, 0, 0, @ReadBuffer);

  GetDriversPath;

  Ini:=TIniFile.Create(GetDriversPath + 'RazorIMU.ini');
  CommPortNum:=Ini.ReadInteger('Main', 'ComPort', 1);
  Ini.Free;

  YawOffset:=0;
  PitchOffset:=0;
  RollOffset:=0;
  
  CommPortDrv:=TCommPortDrv.Create;
end.
 