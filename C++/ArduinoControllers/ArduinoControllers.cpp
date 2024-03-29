#include <windows.h>
#include <thread>
#include <atlstr.h> 
#include "IniReader\IniReader.h"
#include <math.h>

#define DLLEXPORT extern "C" __declspec(dllexport)

typedef struct _HMDData
{
	double	X;
	double	Y;
	double	Z;
	double	Yaw;
	double	Pitch;
	double	Roll;
} THMD, *PHMD;

typedef struct _Controller
{
	double	X;
	double	Y;
	double	Z;
	double	Yaw;
	double	Pitch;
	double	Roll;
	unsigned short	Buttons;
	float	Trigger;
	float	AxisX;
	float	AxisY;
} TController, *PController;

#define TOVR_SUCCESS 0
#define TOVR_FAILURE 1

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *HMD);
DLLEXPORT DWORD __stdcall GetControllersData(__out TController *FirstController, __out TController *SecondController);
DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in unsigned char MotorSpeed);

HANDLE hSerial, hSerial2;
bool Controller1Connected = false, Controller2Connected = false, ControllersInit = false;
std::thread *pCtrl1thread = NULL;
std::thread *pCtrl2thread = NULL;
float ArduinoCtrl1[12] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
float ArduinoCtrl2[12] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
float LastArduinoArduinoCtrl1[12] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
float LastArduinoArduinoCtrl2[12] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
float Ctrl1OffsetYPR[3] = { 0, 0, 0 }, Ctrl2OffsetYPR[3] = { 0, 0, 0 };
bool Ctrl1InitCentring = false, Ctrl2InitCentring = false;
float DefShoulderYaw, DefShoulderPitch, ScalePos, ScalePosZ, OffsetPosZ;

void SetCentering()
{
	Ctrl1OffsetYPR[0] = ArduinoCtrl1[3];
	Ctrl1OffsetYPR[1] = ArduinoCtrl1[4];
	Ctrl1OffsetYPR[2] = ArduinoCtrl1[5];

	Ctrl2OffsetYPR[0] = ArduinoCtrl2[3];
	Ctrl2OffsetYPR[1] = ArduinoCtrl2[4];
	Ctrl2OffsetYPR[2] = ArduinoCtrl2[5];
}

bool CorrectAngleValue(float Value)
{
	if (Value > -180 && Value < 180)
	{
		return true;
	}
	else
	{
		return false;
	}
}

double OffsetYPR(float f, float f2)
{
	f -= f2;
	if (f < -180)
		f += 360;
	else if (f > 180)
		f -= 360;

	return f;
}

void Controller1Read()
{
	DWORD bytesRead;

	while (Controller1Connected) {
		ReadFile(hSerial, &ArduinoCtrl1, sizeof(ArduinoCtrl1), &bytesRead, 0);

		//Filter incorrect values
		if (CorrectAngleValue(ArduinoCtrl1[3]) == false || CorrectAngleValue(ArduinoCtrl1[4]) == false || CorrectAngleValue(ArduinoCtrl1[5]) == false ||
			CorrectAngleValue(ArduinoCtrl1[6]) == false || CorrectAngleValue(ArduinoCtrl1[7]) == false )
		{
			//Last correct values
			ArduinoCtrl1[0] = LastArduinoArduinoCtrl1[0];
			ArduinoCtrl1[1] = LastArduinoArduinoCtrl1[1];
			ArduinoCtrl1[2] = LastArduinoArduinoCtrl1[2];
			ArduinoCtrl1[3] = LastArduinoArduinoCtrl1[3];
			ArduinoCtrl1[4] = LastArduinoArduinoCtrl1[4];
			ArduinoCtrl1[5] = LastArduinoArduinoCtrl1[5];
			ArduinoCtrl1[6] = LastArduinoArduinoCtrl1[6];
			ArduinoCtrl1[7] = LastArduinoArduinoCtrl1[7];
			ArduinoCtrl1[8] = LastArduinoArduinoCtrl1[8];
			ArduinoCtrl1[9] = LastArduinoArduinoCtrl1[9];
			ArduinoCtrl1[10] = LastArduinoArduinoCtrl1[10];
			ArduinoCtrl1[11] = LastArduinoArduinoCtrl1[11];

			PurgeComm(hSerial, PURGE_TXCLEAR | PURGE_RXCLEAR);
		}

		//Save last correct values
		if (CorrectAngleValue(ArduinoCtrl1[3]) && CorrectAngleValue(ArduinoCtrl1[4]) && CorrectAngleValue(ArduinoCtrl1[5]) &&
			CorrectAngleValue(ArduinoCtrl1[6]) && CorrectAngleValue(ArduinoCtrl1[7]) )
		{
			LastArduinoArduinoCtrl1[0] = ArduinoCtrl1[0];
			LastArduinoArduinoCtrl1[1] = ArduinoCtrl1[1];
			LastArduinoArduinoCtrl1[2] = ArduinoCtrl1[2];
			LastArduinoArduinoCtrl1[3] = ArduinoCtrl1[3];
			LastArduinoArduinoCtrl1[4] = ArduinoCtrl1[4];
			LastArduinoArduinoCtrl1[5] = ArduinoCtrl1[5];
			LastArduinoArduinoCtrl1[6] = ArduinoCtrl1[6];
			LastArduinoArduinoCtrl1[7] = ArduinoCtrl1[7];
			LastArduinoArduinoCtrl1[8] = ArduinoCtrl1[8];
			LastArduinoArduinoCtrl1[9] = ArduinoCtrl1[9];
			LastArduinoArduinoCtrl1[10] = ArduinoCtrl1[10];
			LastArduinoArduinoCtrl1[11] = ArduinoCtrl1[11];
		}

		if (Ctrl1InitCentring == false)
			if (ArduinoCtrl1[3] != 0 || ArduinoCtrl1[4] != 0 || ArduinoCtrl1[5] != 0) {
				SetCentering();
				Ctrl1InitCentring = true;
			}

		if (bytesRead == 0) Sleep(1);
	}

}

void Controller2Read()
{
	DWORD bytesRead;

	while (Controller2Connected) {
		ReadFile(hSerial2, &ArduinoCtrl2, sizeof(ArduinoCtrl2), &bytesRead, 0);

		//Filter incorrect values
		if (CorrectAngleValue(ArduinoCtrl2[3]) == false || CorrectAngleValue(ArduinoCtrl2[4]) == false || CorrectAngleValue(ArduinoCtrl2[5]) == false ||
			CorrectAngleValue(ArduinoCtrl2[6]) == false || CorrectAngleValue(ArduinoCtrl2[7]) == false )
		{
			//Last correct values
			ArduinoCtrl2[0] = LastArduinoArduinoCtrl2[0];
			ArduinoCtrl2[1] = LastArduinoArduinoCtrl2[1];
			ArduinoCtrl2[2] = LastArduinoArduinoCtrl2[2];
			ArduinoCtrl2[3] = LastArduinoArduinoCtrl2[3];
			ArduinoCtrl2[4] = LastArduinoArduinoCtrl2[4];
			ArduinoCtrl2[5] = LastArduinoArduinoCtrl2[5];
			ArduinoCtrl2[6] = LastArduinoArduinoCtrl2[6];
			ArduinoCtrl2[7] = LastArduinoArduinoCtrl2[7];
			ArduinoCtrl2[8] = LastArduinoArduinoCtrl2[8];
			ArduinoCtrl2[9] = LastArduinoArduinoCtrl2[9];
			ArduinoCtrl2[10] = LastArduinoArduinoCtrl2[10];
			ArduinoCtrl2[11] = LastArduinoArduinoCtrl2[11];

			PurgeComm(hSerial2, PURGE_TXCLEAR | PURGE_RXCLEAR);
		}

		//Save last correct values
		if (CorrectAngleValue(ArduinoCtrl2[3]) && CorrectAngleValue(ArduinoCtrl2[4]) && CorrectAngleValue(ArduinoCtrl2[5]) &&
			CorrectAngleValue(ArduinoCtrl2[6]) && CorrectAngleValue(ArduinoCtrl2[7]) )
		{
			LastArduinoArduinoCtrl2[0] = ArduinoCtrl2[0];
			LastArduinoArduinoCtrl2[1] = ArduinoCtrl2[1];
			LastArduinoArduinoCtrl2[2] = ArduinoCtrl2[2];
			LastArduinoArduinoCtrl2[3] = ArduinoCtrl2[3];
			LastArduinoArduinoCtrl2[4] = ArduinoCtrl2[4];
			LastArduinoArduinoCtrl2[5] = ArduinoCtrl2[5];
			LastArduinoArduinoCtrl2[6] = ArduinoCtrl2[6];
			LastArduinoArduinoCtrl2[7] = ArduinoCtrl2[7];
			LastArduinoArduinoCtrl2[8] = ArduinoCtrl2[8];
			LastArduinoArduinoCtrl2[9] = ArduinoCtrl2[9];
			LastArduinoArduinoCtrl2[10] = ArduinoCtrl2[10];
			LastArduinoArduinoCtrl2[11] = ArduinoCtrl2[11];
		}

		if (Ctrl2InitCentring == false)
			if (ArduinoCtrl2[3] != 0 || ArduinoCtrl2[4] != 0 || ArduinoCtrl2[5] != 0) {
				SetCentering();
				Ctrl2InitCentring = true;
			}

		if (bytesRead == 0) Sleep(1);
	}
}

void ControllersStart() {
	CRegKey key;
	TCHAR driversPath[MAX_PATH];
	LONG status = key.Open(HKEY_CURRENT_USER, _T("Software\\TrueOpenVR"));
	if (status == ERROR_SUCCESS)
	{
		ULONG regSize = sizeof(driversPath);
		status = key.QueryStringValue(_T("Drivers"), driversPath, &regSize);
	}
	key.Close();

	TCHAR configPath[MAX_PATH] = { 0 };
	_tcscat_s(configPath, sizeof(configPath), driversPath);
	_tcscat_s(configPath, sizeof(configPath), "ArduinoControllers.ini");

	if (status == ERROR_SUCCESS){// && PathFileExists(configPath)) {

		CIniReader IniFile((char *)configPath);
		
		DefShoulderYaw = IniFile.ReadFloat("Main", "ShoulderYaw", 0);
		DefShoulderPitch = IniFile.ReadFloat("Main", "ShoulderPitch", 0);
		ScalePos = IniFile.ReadFloat("Main", "ScalePos", 0.004);
		ScalePosZ = IniFile.ReadFloat("Main", "ScalePosZ", 0.004);
		OffsetPosZ = IniFile.ReadFloat("Main", "OffsetPosZ", 0);

		//Controller 1
		CString sPortName;
		//sPortName.Format(_T("COM%d"), 3);
		sPortName.Format(_T("\\\\.\\COM%d"), IniFile.ReadInteger("Controller1", "ComPort", 2));

		hSerial = ::CreateFile(sPortName, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

		if (hSerial != INVALID_HANDLE_VALUE && GetLastError() != ERROR_FILE_NOT_FOUND) {

			DCB dcbSerialParams = { 0 };
			dcbSerialParams.DCBlength = sizeof(dcbSerialParams);

			if (GetCommState(hSerial, &dcbSerialParams))
			{
				dcbSerialParams.BaudRate = CBR_115200;
				dcbSerialParams.ByteSize = 8;
				dcbSerialParams.StopBits = ONESTOPBIT;
				dcbSerialParams.Parity = NOPARITY;

				if (SetCommState(hSerial, &dcbSerialParams))
				{
					Controller1Connected = true;
					PurgeComm(hSerial, PURGE_TXCLEAR | PURGE_RXCLEAR);
					pCtrl1thread = new std::thread(Controller1Read);
				}
			}
		}

		//Controller 2
		sPortName.Format(_T("\\\\.\\COM%d"), IniFile.ReadInteger("Controller2", "ComPort", 3));

		hSerial2 = ::CreateFile(sPortName, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

		if (hSerial2 != INVALID_HANDLE_VALUE && GetLastError() != ERROR_FILE_NOT_FOUND) {

			DCB dcbSerialParams = { 0 };
			dcbSerialParams.DCBlength = sizeof(dcbSerialParams);

			if (GetCommState(hSerial2, &dcbSerialParams))
			{
				dcbSerialParams.BaudRate = CBR_115200;
				dcbSerialParams.ByteSize = 8;
				dcbSerialParams.StopBits = ONESTOPBIT;
				dcbSerialParams.Parity = NOPARITY;

				if (SetCommState(hSerial2, &dcbSerialParams))
				{
					Controller2Connected = true;
					PurgeComm(hSerial2, PURGE_TXCLEAR | PURGE_RXCLEAR);
					pCtrl2thread = new std::thread(Controller2Read);
				}
			}
		}


	}
}

BOOL APIENTRY DllMain(HMODULE hModule,
	DWORD  ul_reason_for_call,
	LPVOID lpReserved
)
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_DETACH:
		if (Controller1Connected) {
			Controller1Connected = false;
			if (pCtrl1thread) {
				pCtrl1thread->join();
				delete pCtrl1thread;
				pCtrl1thread = nullptr;
			}
			CloseHandle(hSerial);
		}
		if (Controller2Connected) {
			Controller2Connected = false;
			if (pCtrl2thread) {
				pCtrl2thread->join();
				delete pCtrl2thread;
				pCtrl2thread = nullptr;
			}
			CloseHandle(hSerial2);
		}
		break;

	}
	return true;
}

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *HMD)
{
	HMD->X = 0;
	HMD->Y = 0;
	HMD->Z = 0;

	HMD->Yaw = 0;
	HMD->Pitch = 0;
	HMD->Roll = 0;

	return TOVR_FAILURE;
}

double DegToRad(double f) {
	return f * (3.14159265358979323846 / 180);
}

typedef struct
{
	double X, Y, Z, Height, DefHeight, EndX, EndY, EndZ, Radius;
} TBone;

typedef struct
{
	double X, Y, Z;
} handPosition;

handPosition GetHandPosition(bool LeftHand, double ControllerYaw = 0, double ControllerPitch = 0, double ShoulderYaw = 0, double ShoulderPitch = 0)
{
#define ShoulderWidth 21.5 //cm
#define ShoulderHeight 10
#define HeadHeight 18
#define Neck 10

	TBone Shoulder, Forearm;

	Shoulder.DefHeight = 26.9; //cm
	Shoulder.Height = abs(abs(Shoulder.DefHeight / 90.0 * ShoulderPitch) - Shoulder.DefHeight);
	Shoulder.Radius = Shoulder.Height * 2;
	Forearm.DefHeight = 30.2; //cm
	Forearm.Height = abs(abs(Forearm.DefHeight / 90.0 * ControllerPitch) - Forearm.DefHeight);
	Forearm.Radius = Forearm.Height * 2;

	if (LeftHand)
		Shoulder.X = -ShoulderWidth;
	else
		Shoulder.X = ShoulderWidth;
	Shoulder.Y = ShoulderHeight / 2.0;
	Shoulder.Z = HeadHeight + Neck;

	Shoulder.EndX = Shoulder.X + Shoulder.Radius * sin(DegToRad(ShoulderYaw));
	Shoulder.EndY = Shoulder.Y + Shoulder.Radius / 2.0 - Shoulder.Height + Shoulder.Radius * cos(DegToRad(ShoulderYaw));
	Shoulder.EndZ = Shoulder.Z + Shoulder.DefHeight / 90.0 * ShoulderPitch;

	Forearm.X = Shoulder.EndX;
	Forearm.Y = Shoulder.EndY;
	Forearm.Z = Shoulder.EndZ;
	Forearm.EndX = Forearm.X + Forearm.Radius * sin(DegToRad(ControllerYaw));
	Forearm.EndY = Forearm.Y + Forearm.Radius / 2.0 - Forearm.Height + Forearm.Radius * cos(DegToRad(ControllerYaw));
	Forearm.EndZ = Forearm.Z + Forearm.DefHeight / 90.0 * ControllerPitch;

	handPosition HandPos;
	HandPos.X = Forearm.EndX;
	HandPos.Y = Forearm.EndY;
	HandPos.Z = Forearm.EndZ;

	return HandPos;
}

DLLEXPORT DWORD __stdcall GetControllersData(__out TController *FirstController, __out TController *SecondController)
{
	if (ControllersInit == false) {
		ControllersInit = true;
		ControllersStart();
	}

	if ((GetAsyncKeyState(VK_F8) & 0x8000) != 0)
		SetCentering();

	if ((GetAsyncKeyState(VK_F5) & 0x8000) != 0) {
		if (Controller1Connected)
			PurgeComm(hSerial, PURGE_TXCLEAR | PURGE_RXCLEAR);

		if (Controller2Connected)
			PurgeComm(hSerial2, PURGE_TXCLEAR | PURGE_RXCLEAR);
	}

	if (Controller1Connected) {
		FirstController->X = ArduinoCtrl1[0];
		FirstController->Y = ArduinoCtrl1[1];
		FirstController->Z = ArduinoCtrl1[2];

		FirstController->Yaw = OffsetYPR(ArduinoCtrl1[3], Ctrl1OffsetYPR[0]);
		FirstController->Pitch = OffsetYPR(ArduinoCtrl1[4], Ctrl1OffsetYPR[1]);
		FirstController->Roll = OffsetYPR(ArduinoCtrl1[5], Ctrl1OffsetYPR[2]);

		//IMUs Pos
		if (FirstController->X == 0 && FirstController->Y == 0 && FirstController->Z == 0)
		{
			handPosition HandPos;
			if (DefShoulderYaw == 0 && DefShoulderPitch == 0)
				HandPos = GetHandPosition(true, FirstController->Yaw, FirstController->Pitch, ArduinoCtrl1[6], ArduinoCtrl1[7]);
			else //one IMU
				HandPos = GetHandPosition(true, FirstController->Yaw, FirstController->Pitch, -DefShoulderYaw, DefShoulderPitch);
			FirstController->X = HandPos.X * ScalePos;
			FirstController->Y = HandPos.Y * -ScalePos;
			FirstController->Z = HandPos.Z * -ScalePosZ + OffsetPosZ;
		}

		FirstController->Buttons = round(ArduinoCtrl1[8]);
		FirstController->Trigger = ArduinoCtrl1[9];
		FirstController->AxisX = ArduinoCtrl1[10];
		FirstController->AxisY = ArduinoCtrl1[11];
	}
	else 
	{
		FirstController->X = -0.1;
		FirstController->Y = -0.3;
		FirstController->Z = -0.2;

		FirstController->Yaw = 0;
		FirstController->Pitch = 0;
		FirstController->Roll = 0;

		FirstController->Buttons = 0;
		FirstController->Trigger = 0;
		FirstController->AxisX = 0;
		FirstController->AxisY = 0;
	}

	//Controller 2
	if (Controller2Connected) {
		SecondController->X = ArduinoCtrl2[0];
		SecondController->Y = ArduinoCtrl2[1];
		SecondController->Z = ArduinoCtrl2[2];

		SecondController->Yaw = OffsetYPR(ArduinoCtrl2[3], Ctrl2OffsetYPR[0]);
		SecondController->Pitch = OffsetYPR(ArduinoCtrl2[4], Ctrl2OffsetYPR[1]);
		SecondController->Roll = OffsetYPR(ArduinoCtrl2[5], Ctrl2OffsetYPR[2]);

		//IMUs Pos
		if (SecondController->X == 0 && SecondController->Y == 0 && SecondController->Z == 0)
		{
			handPosition HandPos;
			if (DefShoulderYaw == 0 && DefShoulderPitch == 0) 
				HandPos = GetHandPosition(false, SecondController->Yaw, SecondController->Pitch, ArduinoCtrl2[6], ArduinoCtrl2[7]);
			else //one IMU
				HandPos = GetHandPosition(false, SecondController->Yaw, SecondController->Pitch, DefShoulderYaw, DefShoulderPitch);
			SecondController->X = HandPos.X * ScalePos;
			SecondController->Y = HandPos.Y * -ScalePos;
			SecondController->Z = HandPos.Z * -ScalePosZ + OffsetPosZ;
		}

		SecondController->Buttons = round(ArduinoCtrl2[8]);
		SecondController->Trigger = ArduinoCtrl2[9];
		SecondController->AxisX = ArduinoCtrl2[10];
		SecondController->AxisY = ArduinoCtrl2[11];
	}
	else {
		SecondController->X = 0.1;
		SecondController->Y = -0.3;
		SecondController->Z = -0.2;

		SecondController->Yaw = 0;
		SecondController->Pitch = 0;
		SecondController->Roll = 0;

		SecondController->Buttons = 0;
		SecondController->Trigger = 0;
		SecondController->AxisX = 0;
		SecondController->AxisY = 0;
	}

	if (Controller1Connected || Controller2Connected) {
		return TOVR_SUCCESS;
	}
	else {
		return TOVR_FAILURE;
	}
}

DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in unsigned char MotorSpeed)
{
	//Soon
	return TOVR_FAILURE;
}

