library RazorIMU;

uses
  Windows, IniFiles, SysUtils, Registry;

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

type TRazorIMU = record
    Yaw: double;
    Pitch: double;
    Roll: double;
end;

var
  CommHandle: hFile;
  CommThrd, RBuffThrd: THandle;
  Ovr: TOverlapped;
  Stat: TComStat;
  Kols, TransMask, Errs: DWord;

  PacketBuffer: string;
  PosX, PosY, PosZ: double;
  YawOffset, PitchOffset, RollOffset: double;
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
const
  StepPos = 0.0033;
  StepRot = 0.2;
begin
  //For some games need position tracking which is not have in Razor IMU.
  if GetAsyncKeyState(VK_NUMPAD8) <> 0 then PosZ:=PosZ - StepPos;
  if GetAsyncKeyState(VK_NUMPAD2) <> 0 then PosZ:=PosZ + StepPos;

  if GetAsyncKeyState(VK_NUMPAD4) <> 0 then PosX:=PosX - StepPos;
  if GetAsyncKeyState(VK_NUMPAD6) <> 0 then PosX:=PosX + StepPos;

  if GetAsyncKeyState(VK_PRIOR) <> 0 then PosY:=PosY + StepPos;
  if GetAsyncKeyState(VK_NEXT) <> 0 then PosY:=PosY - StepPos;

  //Yaw fixing
  if GetAsyncKeyState(VK_NUMPAD1) <> 0 then YawOffset:=YawOffset + StepRot;
  if GetAsyncKeyState(VK_NUMPAD3) <> 0 then YawOffset:=YawOffset - StepRot;
  
  //Roll fixing
  if GetAsyncKeyState(VK_NUMPAD7) <> 0 then RollOffset:=RollOffset + StepRot;
  if GetAsyncKeyState(VK_NUMPAD9) <> 0 then RollOffset:=RollOffset - StepRot;

  if GetAsyncKeyState(VK_SUBTRACT) <> 0 then begin
    PosX:=0;
    PosY:=0;
    PosZ:=0;
  end;

  myHMD.X:=PosX;
  myHMD.Y:=PosY;
  myHMD.Z:=PosZ;

  myHMD.Yaw:=0;
  myHMD.Pitch:=0;
  myHMD.Roll:=0;

  Result:=0;

  if HMDConnected then begin
    myHMD.Yaw:=MyOffset(MyRazorIMU.Roll, RollOffset);
    myHMD.Pitch:=MyOffset(MyRazorIMU.Yaw, YawOffset) * -1;
    myHMD.Roll:=MyOffset(MyRazorIMU.Pitch, PitchOffset) * -1;

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

function SetControllerData(dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
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

procedure ReadComm;
var
  Buff: array[0..127] of char;
begin
  while HMDConnected do begin

    TransMask:=0;
    WaitCommEvent(CommHandle,TransMask, @Ovr);

    if (TransMask and EV_RXFLAG) = EV_RXFLAG then begin
      ClearCommError(CommHandle, Errs, @Stat);
      Kols:=Stat.cbInQue;
      ReadFile(CommHandle, Buff, Kols, Kols, @Ovr);

      PacketBuffer:=PacketBuffer + string(Buff);
      FillChar(Buff, Length(Buff), 0);
     end;

  end;
end;

procedure ReadBuffer;
var
  s: string;
begin
  while HMDConnected do begin

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
end;

procedure DllMain(Reason: integer);
var
  Ini: TIniFile; DCB: TDCB; ThreadID, ThreadID2: dword;
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
        Ini:=TIniFile.Create(GetDriversPath() + 'RazorIMU.ini');
        CommPortNum:=Ini.ReadInteger('Main', 'ComPort', 1);
        Ini.Free;

        PosX:=0;
        PosY:=0;
        PosZ:=0;

        YawOffset:=0;
        PitchOffset:=0;
        RollOffset:=0;

        CommHandle:=CreateFile(PChar('\\.\COM' + IntToStr(CommPortNum)), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_OVERLAPPED, 0);
        if (CommHandle = INVALID_HANDLE_VALUE) then
          HMDConnected:=false
        else begin
          SetCommMask(CommHandle, EV_RXFLAG);
          GetCommState(CommHandle, DCB);
          DCB.BaudRate:=CBR_115200;
          DCB.Parity:=NOPARITY;
          DCB.ByteSize:=8;
          DCB.StopBits:=OneStopBit;
          DCB.EvtChar:=chr(13);
          SetCommState(CommHandle, DCB);
          HMDConnected:=true;
          CommThrd:=CreateThread(nil, 0, @ReadComm, nil, 0, ThreadID);
          RBuffThrd:=CreateThread(nil, 0, @ReadBuffer, nil, 0, ThreadID2);
        end;
      end;

    DLL_PROCESS_DETACH:
      begin
        TerminateThread(CommThrd, 0);
        TerminateThread(RBuffThrd, 0);
        CloseHandle(CommHandle);
      end;
  end;
end;

exports
  GetHMDData index 1, GetControllersData index 2, SetControllerData index 3, SetCentering index 4;

begin
  DllProc:=@DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.
 