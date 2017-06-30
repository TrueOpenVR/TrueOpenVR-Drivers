library OpenTrackUDP;

uses
  SysUtils, Classes, Windows, IdSocketHandle, IdUDPServer, IniFiles, Registry;

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

  //VR Init
  PVRInfo = ^TVRInfo;
  _VRInfo = record
    ScreenIndex: integer;
    Scale: boolean;
    UserWidth: integer;
    UserHeight: integer;
  end;
  VRInfo = _VRInfo;
  TVRInfo = VRInfo;

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
  TUDPServer = class
  procedure IdUDPServerUDPRead(ASender: TObject;AData: TStream; ABinding: TIdSocketHandle);
  private
    IdUDPServer: TIdUDPServer;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
end;

type TOpenTrackPacket = record
    X: double;
    Y: double;
    Z: double;
    Yaw: double;
    Pitch: double;
    Roll: double;
end;

var
  OpenTrack: TOpenTrackPacket;

{$R *.res}

function GetInfo(out myVRInfo: TVRInfo): DWORD; stdcall;
var
  Ini: TIniFile; Reg: TRegistry;
begin
  Reg:=TRegistry.Create;
  Reg.RootKey:=HKEY_CURRENT_USER;
  Result:=0;
  if Reg.OpenKey('\Software\TrueOpenVR', false)=false then Exit;
  if FileExists(Reg.ReadString('Path') + 'TOVR.ini')=false then Exit;

  Ini:=TIniFile.Create(Reg.ReadString('Path') + 'TOVR.ini');
  MyVRInfo.ScreenIndex:=Ini.ReadInteger('VRInit', 'ScreenIndex', 0);
  myVRInfo.Scale:=Ini.ReadBool('VRInit', 'Scale', false);
  myVRInfo.UserWidth:=Ini.ReadInteger('VRInit', 'UserWidth', 1280);
  myVRInfo.UserHeight:=Ini.ReadInteger('VRInit', 'UserHeight', 720);
  Ini.Free;
  Reg.Free;
  Result:=1;
end;

function GetHMDData(out myHMD: THMD): DWORD; stdcall;
begin
  myHMD.X:=OpenTrack.X;
  myHMD.Y:=OpenTrack.Y;
  myHMD.Z:=OpenTrack.Z;
  myHMD.Yaw:=OpenTrack.Yaw;
  myHMD.Pitch:=OpenTrack.Pitch;
  myHMD.Roll:=OpenTrack.Roll;
  Result:=1;
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
  Result:=0;
end;

exports
  GetInfo index 1, GetHMDData index 2, SetCentering index 3, GetControllersData index 4, SetControllerData index 5;

{ TUDPServer }

constructor TUDPServer.Create;
begin
  idUDPServer:=TIdUDPServer.Create(nil);
  idUDPServer.DefaultPort:=4242;
  idUDPServer.BufferSize:=8192;
  idUDPServer.BroadcastEnabled:=false;
  idUDPServer.OnUDPRead:=IdUDPServerUDPRead;
  IdUDPServer.ThreadedEvent:=true;
  IdUDPServer.Active:=true;
end;

destructor TUDPServer.Destroy;
begin
  IdUDPServer.Active:=false;
  IdUDPServer.Free;
  inherited destroy;
end;

procedure TUDPServer.IdUDPServerUDPRead(ASender: TObject; AData: TStream;
  ABinding: TIdSocketHandle);
begin
  Adata.Read(OpenTrack, SizeOf(OpenTrack));
end;

begin
  TUDPServer.Create;
end.
 