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
  HMDPosDll, HMDRotDll, Ctrl1PosDll, Ctrl1RotDll, Ctrl1BtnsDll, Ctrl2PosDll, Ctrl2RotDll, Ctrl2BtnsDll: HMODULE;
  Error: boolean;
  
  DriverGetHMDPos: function(out myHMD: THMD): DWORD; stdcall;
  DriverGetHMDRot: function(out myHMD: THMD): DWORD; stdcall;
  DriverSetCenteringHMD: function (dwIndex: integer): DWORD; stdcall;

  DriverGetController1Pos: function(out myController, myController2: TController): DWORD; stdcall;
  DriverGetController1Rot: function(out myController, myController2: TController): DWORD; stdcall;
  DriverGetController1Btns: function(out myController, myController2: TController): DWORD; stdcall;
  DriverSetController1Data: function (dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
  DriverSetCenteringCtrls1: function (dwIndex: integer): DWORD; stdcall;

  DriverGetController2Pos: function(out myController, myController2: TController): DWORD; stdcall;
  DriverGetController2Rot: function(out myController, myController2: TController): DWORD; stdcall;
  DriverGetController2Btns: function(out myController, myController2: TController): DWORD; stdcall;
  DriverSetController2Data: function (dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
  DriverSetCenteringCtrls2: function (dwIndex: integer): DWORD; stdcall;

  CtrlIndex1Pos, CtrlIndex1Rot, CtrlIndex1Btns: Byte;
  CtrlIndex2Pos, CtrlIndex2Rot, CtrlIndex2Btns: Byte;

  HMDUseRot, Ctrl1UseRot, Ctrl1RotBtn, Ctrl1UseBtn, Ctrl2UseRot, Ctrl2RotBtn, Ctrl2UseBtn: boolean;

  HMDPosOffset, Ctrl1PosOffset, Ctrl2PosOffset: TOffsetPos;

{$R *.res}

function GetHMDData(out myHMD: THMD): DWORD; stdcall;
var
  HMDRot: THMD; MyStat, StatCount: DWORD;
begin
  if Error = false then begin

    MyStat:=0;
    StatCount:=0;

    MyStat:=MyStat + DriverGetHMDPos(myHMD);
    StatCount:=StatCount + 1;

    if HMDUseRot then begin
      MyStat:=MyStat + DriverGetHMDRot(HMDRot);
      StatCount:=StatCount + 1;

      myHMD.Yaw:=HMDRot.Yaw;
      myHMD.Pitch:=HMDRot.Pitch;
      myHMD.Roll:=HMDRot.Roll;
    end;

    //HMD offset pos
    myHMD.X:=myHMD.X + HMDPosOffset.X;
    myHMD.Y:=myHMD.Y + HMDPosOffset.Y;
    myHMD.Z:=myHMD.Z + HMDPosOffset.Z;

    if MyStat = StatCount then
      Result:=1
    else
      Result:=0;
  end else begin
    myHMD.X:=0;
    myHMD.Y:=0;
    myHMD.Z:=0;

    myHMD.Yaw:=0;
    myHMD.Pitch:=0;
    myHMD.Roll:=0;

    Result:=0;
  end;
end;

function GetControllersData(out myController, myController2: TController): DWORD; stdcall;
var
  Ctrl1Pos, Ctrl1Rot, Ctrl1Btns: TController;
  Ctrl2Pos, Ctrl2Rot, Ctrl2Btns: TController;
  MyStat, StatCount: DWORD;
begin
  if Error = false then begin

    MyStat:=0;
    StatCount:=0;

    //Controller1
    //Controller1 Position
    MyStat:=MyStat + DriverGetController1Pos(Ctrl1Pos, Ctrl2Pos);
    StatCount:=StatCount + 1;

    if CtrlIndex1Pos = 1 then
      myController:=Ctrl1Pos
    else
      myController:=Ctrl2Pos;

    //Controller1 Rotation
    if Ctrl1UseRot then begin
      MyStat:=MyStat + DriverGetController1Rot(Ctrl1Rot, Ctrl2Rot);
      StatCount:=StatCount + 1;

      if CtrlIndex1Rot = 1 then begin
        myController.Yaw:=Ctrl1Rot.Yaw;
        myController.Pitch:=Ctrl1Rot.Pitch;
        myController.Roll:=Ctrl1Rot.Roll;

        if Ctrl1RotBtn then begin
          myController.Buttons:=Ctrl1Rot.Buttons;
          myController.Trigger:=Ctrl1Rot.Trigger;
          myController.ThumbX:=Ctrl1Rot.ThumbX;
          myController.ThumbY:=Ctrl1Rot.ThumbY;
        end;

      end else begin
        myController.Yaw:=Ctrl2Rot.Yaw;
        myController.Pitch:=Ctrl2Rot.Pitch;
        myController.Roll:=Ctrl2Rot.Roll;

        if Ctrl1RotBtn then begin
          myController.Buttons:=Ctrl2Rot.Buttons;
          myController.Trigger:=Ctrl2Rot.Trigger;
          myController.ThumbX:=Ctrl2Rot.ThumbX;
          myController.ThumbY:=Ctrl2Rot.ThumbY;
        end;

      end;
    end;

    //Contoller1 buttons
    if Ctrl1UseBtn then begin
      MyStat:=MyStat + DriverGetController1Btns(Ctrl1Btns, Ctrl2Btns);
      StatCount:=StatCount + 1;

      if CtrlIndex1Btns = 1 then begin
        myController.Buttons:=Ctrl1Btns.Buttons;
        myController.Trigger:=Ctrl1Btns.Trigger;
        myController.ThumbX:=Ctrl1Btns.ThumbX;
        myController.ThumbY:=Ctrl1Btns.ThumbY;
      end else begin
        myController.Buttons:=Ctrl2Btns.Buttons;
        myController.Trigger:=Ctrl2Btns.Trigger;
        myController.ThumbX:=Ctrl2Btns.ThumbX;
        myController.ThumbY:=Ctrl2Btns.ThumbY;
      end;
    end;
    //Controoler1 offset pos
    myController.X:=myController.X + Ctrl1PosOffset.X;
    myController.Y:=myController.Y + Ctrl1PosOffset.Y;
    myController.Z:=myController.Z + Ctrl1PosOffset.Z;

    //Controller2
    //Controller2 Position
    MyStat:=MyStat + DriverGetController2Pos(Ctrl1Pos, Ctrl2Pos);
    StatCount:=StatCount + 1;

    if CtrlIndex2Pos = 1 then
      myController2:=Ctrl1Pos
    else
      myController2:=Ctrl2Pos;

    //Controller1 Rotation
    if Ctrl2UseRot then begin
      MyStat:=MyStat + DriverGetController2Rot(Ctrl1Rot, Ctrl2Rot);
      StatCount:=StatCount + 1;

      if CtrlIndex2Rot = 1 then begin
        myController2.Yaw:=Ctrl1Rot.Yaw;
        myController2.Pitch:=Ctrl1Rot.Pitch;
        myController2.Roll:=Ctrl1Rot.Roll;

        if Ctrl2RotBtn then begin
          myController2.Buttons:=Ctrl1Rot.Buttons;
          myController2.Trigger:=Ctrl1Rot.Trigger;
          myController2.ThumbX:=Ctrl1Rot.ThumbX;
          myController2.ThumbY:=Ctrl1Rot.ThumbY;
        end;

      end else begin
        myController2.Yaw:=Ctrl2Rot.Yaw;
        myController2.Pitch:=Ctrl2Rot.Pitch;
        myController2.Roll:=Ctrl2Rot.Roll;

        if Ctrl2RotBtn then begin
          myController2.Buttons:=Ctrl2Rot.Buttons;
          myController2.Trigger:=Ctrl2Rot.Trigger;
          myController2.ThumbX:=Ctrl2Rot.ThumbX;
          myController2.ThumbY:=Ctrl2Rot.ThumbY;
        end;

      end;
    end;

    //Contoller2 buttons
    if Ctrl2UseBtn then begin
      MyStat:=MyStat + DriverGetController2Btns(Ctrl1Btns, Ctrl2Btns);
      StatCount:=StatCount + 1;

      if CtrlIndex2Btns = 1 then begin
        myController2.Buttons:=Ctrl1Btns.Buttons;
        myController2.Trigger:=Ctrl1Btns.Trigger;
        myController2.ThumbX:=Ctrl1Btns.ThumbX;
        myController2.ThumbY:=Ctrl1Btns.ThumbY;
      end else begin
        myController2.Buttons:=Ctrl2Btns.Buttons;
        myController2.Trigger:=Ctrl2Btns.Trigger;
        myController2.ThumbX:=Ctrl2Btns.ThumbX;
        myController2.ThumbY:=Ctrl2Btns.ThumbY;
      end;
    end;

    //Controoler2 offset pos
    myController2.X:=myController2.X + Ctrl2PosOffset.X;
    myController2.Y:=myController2.Y + Ctrl2PosOffset.Y;
    myController2.Z:=myController2.Z + Ctrl2PosOffset.Z;

    if MyStat = StatCount then
      Result:=1
    else
      Result:=0;
  end else
    Result:=0;
end;

function SetControllerData(dwIndex: integer; MotorSpeed: word): DWORD; stdcall;
begin
  case dwIndex of
    1: Result:=DriverSetController1Data(CtrlIndex1Btns, MotorSpeed);
    2: Result:=DriverSetController2Data(CtrlIndex2Btns, MotorSpeed);
  else
    Result:=0;
  end;
end;

function SetCentering(dwIndex: integer): DWORD; stdcall;
begin
  case dwIndex of
    0: Result:=DriverSetCenteringHMD(0);
    1: Result:=DriverSetCenteringCtrls1(CtrlIndex1Rot);
    2: Result:=DriverSetCenteringCtrls2(CtrlIndex2Rot);
    else
      Result:=0;
  end;
end;

procedure DllMain(Reason: integer);
var
  Ini: TIniFile; Reg: TRegistry; HMDPosDrvPath, HMDRotDrvPath, Ctrl1PosDrvPath, Ctrl1RotDrvPath, Ctrl1BtnsDrvPath, Ctrl2PosDrvPath, Ctrl2RotDrvPath, Ctrl2BtnsDrvPath: string;
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
          Ctrl1UseRot:=false;
          Ctrl1RotBtn:=false;
          Ctrl1UseBtn:=false;
          Ctrl2UseRot:=false;
          Ctrl1RotBtn:=false;
          Ctrl2UseBtn:=false;

          //HMD
          HMDPosDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('HMD', 'Position', '');
          HMDRotDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('HMD', 'Rotation', '');

          //Different locales have different delimiters, so it will be easier to use everywhere delimiter "." in configs.
          try
            HMDPosOffset.X:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetX', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            HMDPosOffset.Y:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetY', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            HMDPosOffset.Z:=StrToFloat(StringReplace(Ini.ReadString('HMD', 'OffsetZ', '0'), '.', DecimalSeparator, [rfReplaceAll]));
          except
            HMDPosOffset.X:=0;
            HMDPosOffset.Y:=0;
            HMDPosOffset.Z:=0;
          end;

          //Don't load the library more than once if the same
          if HMDPosDrvPath <> HMDRotDrvPath then HMDUseRot:=true;

          //Controller1
          try
            Ctrl1PosOffset.X:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetX', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl1PosOffset.Y:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetY', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl1PosOffset.Z:=StrToFloat(StringReplace(Ini.ReadString('Controller1', 'OffsetZ', '0'), '.', DecimalSeparator, [rfReplaceAll]));
          except
            Ctrl1PosOffset.X:=0;
            Ctrl1PosOffset.Y:=0;
            Ctrl1PosOffset.Z:=0;
          end;

          CtrlIndex1Pos:=Ini.ReadInteger('Controller1', 'PosIndex', 1);
          CtrlIndex1Rot:=Ini.ReadInteger('Controller1', 'RotIndex', 1);
          CtrlIndex1Btns:=Ini.ReadInteger('Controller1', 'BtnsIndex', 1);

          Ctrl1PosDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller1', 'Position', '');
          Ctrl1RotDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller1', 'Rotation', '');
          Ctrl1BtnsDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller1', 'Buttons', '');

          //Don't load the library more than once if the same
          if Ctrl1PosDrvPath <> Ctrl1RotDrvPath then Ctrl1UseRot:=true;

          if (Ctrl1UseRot) and (Ctrl1RotDrvPath = Ctrl1BtnsDrvPath) then Ctrl1RotBtn:=true;

          if (Ctrl1RotBtn = false) and (Ctrl1PosDrvPath <> Ctrl1BtnsDrvPath) then
            Ctrl1UseBtn:=true;

          //Controller2
          try
            Ctrl2PosOffset.X:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetX', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl2PosOffset.Y:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetY', '0'), '.', DecimalSeparator, [rfReplaceAll]));
            Ctrl2PosOffset.Z:=StrToFloat(StringReplace(Ini.ReadString('Controller2', 'OffsetZ', '0'), '.', DecimalSeparator, [rfReplaceAll]));
          except
            Ctrl2PosOffset.X:=0;
            Ctrl2PosOffset.Y:=0;
            Ctrl2PosOffset.Z:=0;
          end;

          CtrlIndex2Pos:=Ini.ReadInteger('Controller2', 'PosIndex', 2);
          CtrlIndex2Rot:=Ini.ReadInteger('Controller2', 'RotIndex', 2);
          CtrlIndex2Btns:=Ini.ReadInteger('Controller2', 'BtnsIndex', 2);

          Ctrl2PosDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller2', 'Position', '');
          Ctrl2RotDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller2', 'Rotation', '');
          Ctrl2BtnsDrvPath:=Reg.ReadString('Drivers') + Ini.ReadString('Controller2', 'Buttons', '');

          if Ctrl2PosDrvPath <> Ctrl2RotDrvPath then Ctrl2UseRot:=true;

          if (Ctrl2UseRot) and (Ctrl2RotDrvPath = Ctrl2BtnsDrvPath) then Ctrl2RotBtn:=true;

          if (Ctrl2RotBtn = false) and (Ctrl2PosDrvPath <> Ctrl2BtnsDrvPath) then
            Ctrl2UseBtn:=true;

          Ini.Free;

          if (FileExists(HMDPosDrvPath) = false) or
              (FileExists(HMDRotDrvPath) = false) or
              (FileExists(Ctrl1PosDrvPath) = false) or
              (FileExists(Ctrl1RotDrvPath) = false) or
              (FileExists(Ctrl1BtnsDrvPath) = false) or
              (FileExists(Ctrl2PosDrvPath) = false) or
              (FileExists(Ctrl2RotDrvPath) = false) or
              (FileExists(Ctrl2BtnsDrvPath) = false) then Error:=true;

          Reg.CloseKey;
        end;

        if Error = false then begin

          //HMD
          HMDPosDll:=LoadLibrary(PChar(HMDPosDrvPath));
          @DriverGetHMDPos:=GetProcAddress(HMDPosDll, 'GetHMDData');

          if HMDUseRot then begin
            HMDRotDll:=LoadLibrary(PChar(HMDRotDrvPath));
            @DriverGetHMDRot:=GetProcAddress(HMDRotDll, 'GetHMDData');
            @DriverSetCenteringHMD:=GetProcAddress(HMDRotDll, 'SetCentering');
          end else
            @DriverSetCenteringHMD:=GetProcAddress(HMDPosDll, 'SetCentering');

          //Controller1
          Ctrl1PosDll:=LoadLibrary(PChar(Ctrl1PosDrvPath));
          @DriverGetController1Pos:=GetProcAddress(Ctrl1PosDll, 'GetControllersData');
          @DriverSetController1Data:=GetProcAddress(Ctrl1PosDll, 'SetControllerData');
          @DriverSetCenteringCtrls1:=GetProcAddress(Ctrl1PosDll, 'SetCentering');

          if Ctrl1UseRot then begin
            Ctrl1RotDll:=LoadLibrary(PChar(Ctrl1RotDrvPath));
            @DriverGetController1Rot:=GetProcAddress(Ctrl1RotDll, 'GetControllersData');
            @DriverSetCenteringCtrls1:=GetProcAddress(Ctrl1RotDll, 'SetCentering');
          end;

          if Ctrl1UseBtn then begin
            Ctrl1BtnsDll:=LoadLibrary(PChar(Ctrl1BtnsDrvPath));
            @DriverGetController1Btns:=GetProcAddress(Ctrl1BtnsDll, 'GetControllersData');
            @DriverSetController1Data:=GetProcAddress(Ctrl1BtnsDll, 'SetControllerData');
          end;

          //Controller2
          Ctrl2PosDll:=LoadLibrary(PChar(Ctrl2PosDrvPath));
          @DriverGetController2Pos:=GetProcAddress(Ctrl2PosDll, 'GetControllersData');
          @DriverSetController2Data:=GetProcAddress(Ctrl2PosDll, 'SetControllerData');
          @DriverSetCenteringCtrls2:=GetProcAddress(Ctrl2PosDll, 'SetCentering');

          if Ctrl2UseRot then begin
            Ctrl2RotDll:=LoadLibrary(PChar(Ctrl2RotDrvPath));
            @DriverGetController2Rot:=GetProcAddress(Ctrl2RotDll, 'GetControllersData');
            @DriverSetCenteringCtrls2:=GetProcAddress(Ctrl2RotDll, 'SetCentering');
          end;

          if Ctrl2UseBtn then begin
            Ctrl2BtnsDll:=LoadLibrary(PChar(Ctrl2BtnsDrvPath));
            @DriverGetController2Btns:=GetProcAddress(Ctrl2BtnsDll, 'GetControllersData');
            @DriverSetController2Data:=GetProcAddress(Ctrl2BtnsDll, 'SetControllerData');
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

        //Controller1 dlls
        FreeLibrary(Ctrl1PosDll);

        if Ctrl2UseRot then
          FreeLibrary(Ctrl1RotDll);

        if Ctrl1UseBtn then
          FreeLibrary(Ctrl1BtnsDll);

        //Controller2 dlls
        FreeLibrary(Ctrl2PosDll);

        if Ctrl2UseRot then
          FreeLibrary(Ctrl2RotDll);

        if Ctrl2UseBtn then
          FreeLibrary(Ctrl2BtnsDll);
      end;
  end;
end;

exports
  GetHMDData index 1, GetControllersData index 2, SetControllerData index 3, SetCentering index 4;

begin
  DllProc:=@DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.
