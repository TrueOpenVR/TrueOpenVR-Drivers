library SplitterAdvance;

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

type TOffsetPos = record
  X: double;
  Y: double;
  Z: double;
end;

type TOffsetYPR = record
  Yaw: double;
  Pitch: double;
  Roll: double;
end;

var
  DriverGetHMDPos: function(out MyHMD: THMD): DWORD; stdcall;
  DriverGetHMDRot: function(out MyHMD: THMD): DWORD; stdcall;

  DriverGetControllersPos: function(out FirstController, SecondController: TController): DWORD; stdcall;
  DriverGetControllersRot: function(out FirstController, SecondController: TController): DWORD; stdcall;
  DriverGetControllersBtns: function(out FirstController, SecondController: TController): DWORD; stdcall;
  DriverSetControllerData: function (dwIndex: integer; MotorSpeed: byte): DWORD; stdcall;


  HMDPosDll, HMDRotDll, CtrlsPosDll, CtrlsRotDll, CtrlsBtnsDll: HMODULE;
  Error: boolean;

  HMDUseRot, CtrlsUseRot, CtrlsRotBtns, CtrlsUseBtns: boolean;

  HMDPosOffset, Ctrl1PosOffset, Ctrl2PosOffset: TOffsetPos;
  HMDYPROffset, Ctrl1YPROffset, Ctrl2YPROffset: TOffsetYPR;

{$R *.res}

function OffsetYPR(f, f2: double): double;
begin
  f:=f - f2;

  if (f < -180) then
    f:=f + 360
  else if (f > 180) then
    f:=f - 360;

	Result:=f;
end;

function GetHMDData(out MyHMD: THMD): DWORD; stdcall;
var
  HMDRot: THMD; MyStat, StatCount: DWORD;
begin
  if Error = false then begin

    MyStat:=0;
    StatCount:=0;

    if DriverGetHMDPos(MyHMD) = TOVR_SUCCESS then
      MyStat:=MyStat + 1;
    StatCount:=StatCount + 1;

    if HMDUseRot then begin
      MyStat:=MyStat + DriverGetHMDRot(HMDRot);
      StatCount:=StatCount + 1;

      MyHMD.Yaw:=HMDRot.Yaw;
      MyHMD.Pitch:=HMDRot.Pitch;
      MyHMD.Roll:=HMDRot.Roll;
    end;

    //HMD offset pos
    MyHMD.X:=MyHMD.X + HMDPosOffset.X;
    MyHMD.Y:=MyHMD.Y + HMDPosOffset.Y;
    MyHMD.Z:=MyHMD.Z + HMDPosOffset.Z;

    //HMD offset ypr
    MyHMD.Yaw:=OffsetYPR(MyHMD.Yaw, HMDYPROffset.Yaw);
    MyHMD.Pitch:=OffsetYPR(MyHMD.Pitch, HMDYPROffset.Pitch);
    MyHMD.Roll:=OffsetYPR(MyHMD.Roll, HMDYPROffset.Roll);

    if MyStat = StatCount then
      Result:=TOVR_SUCCESS
    else
      Result:=TOVR_FAILURE;
  end else begin
    MyHMD.X:=0;
    MyHMD.Y:=0;
    MyHMD.Z:=0;

    MyHMD.Yaw:=0;
    MyHMD.Pitch:=0;
    MyHMD.Roll:=0;

    Result:=TOVR_FAILURE;
  end;
end;

function GetControllersData(out FirstController, SecondController: TController): DWORD; stdcall;
var
  Ctrl1Pos, Ctrl1Rot, Ctrl1Btns: TController;
  Ctrl2Pos, Ctrl2Rot, Ctrl2Btns: TController;
  MyStat, StatCount: DWORD;
begin
  if Error = false then begin

    MyStat:=0;
    StatCount:=0;

    //Position
    if DriverGetControllersPos(Ctrl1Pos, Ctrl2Pos) = TOVR_SUCCESS then
      MyStat:=MyStat + 1;
    StatCount:=StatCount + 1;

    FirstController:=Ctrl1Pos;
    SecondController:=Ctrl2Pos;

    //Rotation
    if CtrlsUseRot then begin
      if DriverGetControllersRot(Ctrl1Rot, Ctrl2Rot) = TOVR_SUCCESS then
        MyStat:=MyStat + 1;
      StatCount:=StatCount + 1;

        FirstController.Yaw:=Ctrl1Rot.Yaw;
        FirstController.Pitch:=Ctrl1Rot.Pitch;
        FirstController.Roll:=Ctrl1Rot.Roll;

        SecondController.Yaw:=Ctrl2Rot.Yaw;
        SecondController.Pitch:=Ctrl2Rot.Pitch;
        SecondController.Roll:=Ctrl2Rot.Roll;


        if CtrlsRotBtns then begin
          FirstController.Buttons:=Ctrl1Rot.Buttons;
          FirstController.Trigger:=Ctrl1Rot.Trigger;
          FirstController.AxisX:=Ctrl1Rot.AxisX;
          FirstController.AxisY:=Ctrl1Rot.AxisY;

          SecondController.Buttons:=Ctrl2Rot.Buttons;
          SecondController.Trigger:=Ctrl2Rot.Trigger;
          SecondController.AxisX:=Ctrl2Rot.AxisX;
          SecondController.AxisY:=Ctrl2Rot.AxisY;
        end;
    end;

    //Buttons
    if CtrlsUseBtns then begin
      if DriverGetControllersBtns(Ctrl1Btns, Ctrl2Btns) = TOVR_SUCCESS then
        MyStat:=MyStat + 1;
      StatCount:=StatCount + 1;

      FirstController.Buttons:=Ctrl1Btns.Buttons;
      FirstController.Trigger:=Ctrl1Btns.Trigger;
      FirstController.AxisX:=Ctrl1Btns.AxisX;
      FirstController.AxisY:=Ctrl1Btns.AxisY;

      SecondController.Buttons:=Ctrl2Btns.Buttons;
      SecondController.Trigger:=Ctrl2Btns.Trigger;
      SecondController.AxisX:=Ctrl2Btns.AxisX;
      SecondController.AxisY:=Ctrl2Btns.AxisY;
    end;

    //Controoler1 offset pos
    FirstController.X:=FirstController.X + Ctrl1PosOffset.X;
    FirstController.Y:=FirstController.Y + Ctrl1PosOffset.Y;
    FirstController.Z:=FirstController.Z + Ctrl1PosOffset.Z;

    //Controller offset ypr
    FirstController.Yaw:=OffsetYPR(FirstController.Yaw, Ctrl1YPROffset.Yaw);
    FirstController.Pitch:=OffsetYPR(FirstController.Pitch, Ctrl1YPROffset.Pitch);
    FirstController.Roll:=OffsetYPR(FirstController.Roll, Ctrl1YPROffset.Roll);

    //Controoler2 offset pos
    SecondController.X:=SecondController.X + Ctrl2PosOffset.X;
    SecondController.Y:=SecondController.Y + Ctrl2PosOffset.Y;
    SecondController.Z:=SecondController.Z + Ctrl2PosOffset.Z;

    //Controller offset ypr
    SecondController.Yaw:=OffsetYPR(SecondController.Yaw, Ctrl2YPROffset.Yaw);
    SecondController.Pitch:=OffsetYPR(SecondController.Pitch, Ctrl2YPROffset.Pitch);
    SecondController.Roll:=OffsetYPR(SecondController.Roll, Ctrl2YPROffset.Roll);

    if MyStat = StatCount then
      Result:=TOVR_SUCCESS
    else
      Result:=TOVR_FAILURE;
  end else
    Result:=TOVR_FAILURE;
end;

function SetControllerData(dwIndex: integer; MotorSpeed: byte): DWORD; stdcall;
begin
  Result:=DriverSetControllerData(dwIndex, MotorSpeed);
end;

procedure DllMain(Reason: integer);
var
  Ini: TIniFile; Reg: TRegistry; HMDPosDrvPath, HMDRotDrvPath, CtrlsPosDrvPath, CtrlsRotDrvPath, CtrlsBtnsDrvPath: string;
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
        Error:=false;
        Reg:=TRegistry.Create;
        Reg.RootKey:=HKEY_CURRENT_USER;
        if Reg.OpenKey('\Software\TrueOpenVR', false) = false then Error:=true;
        if DirectoryExists(Reg.ReadString('Drivers')) = false then Error:=true;

        if FileExists(Reg.ReadString('Drivers') + 'SplitterAdvance.ini') = false then Error:=true;

        if Error = false then begin
          Ini:=TIniFile.Create(Reg.ReadString('Drivers') + 'SplitterAdvance.ini');

          HMDUseRot:=false;
          CtrlsUseRot:=false;
          CtrlsRotBtns:=false;
          CtrlsUseBtns:=false;

          //HMD
          HMDPosDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('HMD', 'Position', '');
          HMDRotDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('HMD', 'Rotation', '');

          //Different locales have different delimiters, so it will be easier to use everywhere delimiter "." in configs.
          try
            HMDPosOffset.X:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetX', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            HMDPosOffset.Y:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetY', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            HMDPosOffset.Z:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetZ', '0'), '.', DecimalSeparator, [rfReplaceAll]));

            HMDYPROffset.Yaw:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetYaw', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            HMDYPROffset.Pitch:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetPitch', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            HMDYPROffset.Roll:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetRoll', '0'), '.', DecimalSeparator, [rfReplaceAll]));
          except
            HMDPosOffset.X:=0;
            HMDPosOffset.Y:=0;
            HMDPosOffset.Z:=0;

            HMDYPROffset.Yaw:=0;
            HMDYPROffset.Pitch:=0;
            HMDYPROffset.Roll:=0;
          end;

          //Don't load the library more than once if the same
          if HMDPosDrvPath <> HMDRotDrvPath then HMDUseRot:=true;

          //Controllers pos and ypr offset
          try
            Ctrl1PosOffset.X:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetX', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl1PosOffset.Y:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetY', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl1PosOffset.Z:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetZ', '0'), '.', DecimalSeparator, [rfReplaceAll]));

            Ctrl1YPROffset.Yaw:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetYaw', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl1YPROffset.Pitch:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetPitch', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl1YPROffset.Roll:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetRoll', '0'), '.', DecimalSeparator, [rfReplaceAll]));
          except
            Ctrl1PosOffset.X:=0;
            Ctrl1PosOffset.Y:=0;
            Ctrl1PosOffset.Z:=0;

            Ctrl1YPROffset.Yaw:=0;
            Ctrl1YPROffset.Pitch:=0;
            Ctrl1YPROffset.Roll:=0;
          end;

          try
            Ctrl2PosOffset.X:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetX', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl2PosOffset.Y:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetY', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl2PosOffset.Z:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetZ', '0'), '.', DecimalSeparator, [rfReplaceAll]));

            Ctrl2YPROffset.Yaw:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetYaw', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl2YPROffset.Pitch:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetPitch', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl2YPROffset.Roll:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetRoll', '0'), '.', DecimalSeparator, [rfReplaceAll]));
          except
            Ctrl2PosOffset.X:=0;
            Ctrl2PosOffset.Y:=0;
            Ctrl2PosOffset.Z:=0;

            Ctrl2YPROffset.Yaw:=0;
            Ctrl2YPROffset.Pitch:=0;
            Ctrl2YPROffset.Roll:=0;
          end;

          CtrlsPosDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controllers', 'Position', '');
          CtrlsRotDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controllers', 'Rotation', '');
          CtrlsBtnsDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controllers', 'Buttons', '');

          //Don't load the library more than once if the same
          if CtrlsPosDrvPath <> CtrlsRotDrvPath then CtrlsUseRot:=true;

          if (CtrlsUseRot) and (CtrlsRotDrvPath = CtrlsBtnsDrvPath) then CtrlsRotBtns:=true;

          if (CtrlsRotBtns = false) and (CtrlsPosDrvPath <> CtrlsBtnsDrvPath) then
            CtrlsUseBtns:=true;

          Ini.Free;

          if (FileExists(HMDPosDrvPath) = false) or
              (FileExists(HMDRotDrvPath) = false) or
              (FileExists(CtrlsPosDrvPath) = false) or
              (FileExists(CtrlsRotDrvPath) = false) or
              (FileExists(CtrlsBtnsDrvPath) = false) then Error:=true;

          Reg.CloseKey;
        end;

        if Error = false then begin

          //HMD
          HMDPosDll:=LoadLibrary(PChar(HMDPosDrvPath));
          @DriverGetHMDPos:=GetProcAddress(HMDPosDll, 'GetHMDData');

          if HMDUseRot then begin
            HMDRotDll:=LoadLibrary(PChar(HMDRotDrvPath));
            @DriverGetHMDRot:=GetProcAddress(HMDRotDll, 'GetHMDData');
          end;

          //Controllers
          CtrlsPosDll:=LoadLibrary(PChar(CtrlsPosDrvPath));
          @DriverGetControllersPos:=GetProcAddress(CtrlsPosDll, 'GetControllersData');
          @DriverSetControllerData:=GetProcAddress(CtrlsPosDll, 'SetControllerData');

          if CtrlsUseRot then begin
            CtrlsRotDll:=LoadLibrary(PChar(CtrlsRotDrvPath));
            @DriverGetControllersRot:=GetProcAddress(CtrlsRotDll, 'GetControllersData');
            @DriverSetControllerData:=GetProcAddress(CtrlsRotDll, 'SetControllerData');
          end;

          if CtrlsUseBtns then begin
            CtrlsBtnsDll:=LoadLibrary(PChar(CtrlsBtnsDrvPath));
            @DriverGetControllersBtns:=GetProcAddress(CtrlsBtnsDll, 'GetControllersData');
            @DriverSetControllerData:=GetProcAddress(CtrlsBtnsDll, 'SetControllerData');
          end;

        end;
        Reg.Free;
      end;

    DLL_PROCESS_DETACH:
      if Error = false then begin

        //HMD dlls
        FreeLibrary(HMDPosDll);

        if HMDUseRot then
          FreeLibrary(HMDRotDll);

        //Controllers dlls
        FreeLibrary(CtrlsPosDll);

        if CtrlsUseRot then
          FreeLibrary(CtrlsRotDll);

        if CtrlsUseBtns then
          FreeLibrary(CtrlsBtnsDll);
      end;
  end;
end;

exports
  GetHMDData index 1, GetControllersData index 2, SetControllerData index 3;

begin
  DllProc:=@DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.
