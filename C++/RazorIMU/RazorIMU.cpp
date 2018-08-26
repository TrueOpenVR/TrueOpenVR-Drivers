#include "stdafx.h"
#include <windows.h>
#include <thread>
#include <atlstr.h> 
#include "IniReader\IniReader.h"

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
	WORD	Buttons;
	BYTE	Trigger;
	SHORT	ThumbX;
	SHORT	ThumbY;
} TController, *PController;

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *myHMD);
DLLEXPORT DWORD __stdcall GetControllersData(__out TController *MyController, __out TController *MyController2);
DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in WORD	MotorSpeed);
DLLEXPORT DWORD __stdcall SetCentering(__in int dwIndex);

HANDLE hSerial;
bool HMDConnected = false, RInit = false;
float RazorIMU[3], yprOffset[3]; //yaw, pitch, roll
double fPos[3];
std::thread *pRRthread = NULL;

void RazorIMURead()
{
	DWORD bytesRead;

	while (HMDConnected) {
		ReadFile(hSerial, &RazorIMU, sizeof(RazorIMU), &bytesRead, 0);
	}
}

void RazorInit(){
	CRegKey key;
	TCHAR _driversPath[MAX_PATH];
	LONG status = key.Open(HKEY_CURRENT_USER, _T("Software\\TrueOpenVR"));
	if (status == ERROR_SUCCESS)
	{
		ULONG regSize = sizeof(_driversPath);
		status = key.QueryStringValue(_T("Drivers"), _driversPath, &regSize);
	}
	key.Close();

	CString configPath(_driversPath);
	configPath.Format(_T("%sRazorIMU.ini"), _driversPath);

	if (status == ERROR_SUCCESS && PathFileExists(configPath)) {
		CIniReader IniFile((char *)configPath.GetBuffer());

		CString sPortName;
		sPortName.Format(_T("COM%d"), IniFile.ReadInteger("Main", "ComPort", 2));

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
					HMDConnected = true;
					PurgeComm(hSerial, PURGE_TXCLEAR | PURGE_RXCLEAR);
					pRRthread = new std::thread(RazorIMURead);
				}
			}
		}
	}
}

float MyOffset(float f, float f2)
{
	f -= f2;
	if (f < -180) {
		f += 360;
	} else if (f > 180) {
		f -= 360;
	}

	return f;
}

BOOL APIENTRY DllMain(HMODULE hModule,
	DWORD  ul_reason_for_call,
	LPVOID lpReserved
)
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_DETACH: 
		if (HMDConnected) {
			HMDConnected = false;
			if (pRRthread) {
				pRRthread->join();
				delete pRRthread;
				pRRthread = nullptr;
			}
			CloseHandle(hSerial);
		}
		break;
		
	}
	return true;
}

#define StepPos 0.0033;
#define StepRot 0.1;

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *myHMD)
{
	if (RInit == false) {
		RInit = true;
		RazorInit();
	}

	if (HMDConnected) {

		if ((GetAsyncKeyState(VK_NUMPAD8) & 0x8000) != 0) fPos[2] -= StepPos;
		if ((GetAsyncKeyState(VK_NUMPAD2) & 0x8000) != 0) fPos[2] += StepPos;

		if ((GetAsyncKeyState(VK_NUMPAD4) & 0x8000) != 0) fPos[0] -= StepPos;
		if ((GetAsyncKeyState(VK_NUMPAD6) & 0x8000) != 0) fPos[0] += StepPos;

		if ((GetAsyncKeyState(VK_PRIOR) & 0x8000) != 0) fPos[1] += StepPos;
		if ((GetAsyncKeyState(VK_NEXT) & 0x8000) != 0) fPos[1] -= StepPos;

		//Yaw fixing
		if ((GetAsyncKeyState(VK_NUMPAD1) & 0x8000) != 0 && yprOffset[0] < 180) yprOffset[0] += StepRot;
		if ((GetAsyncKeyState(VK_NUMPAD3) & 0x8000) != 0 && yprOffset[0] > -180) yprOffset[0] -= StepRot;

		//Roll fixing
		if ((GetAsyncKeyState(VK_NUMPAD7) & 0x8000) != 0 && yprOffset[2] < 180) yprOffset[2] += StepRot;
		if ((GetAsyncKeyState(VK_NUMPAD9) & 0x8000) != 0 && yprOffset[2] > -180) yprOffset[2] -= StepRot;

		if ((GetAsyncKeyState(VK_SUBTRACT) & 0x8000) != 0) {
			fPos[0] = 0;
			fPos[1] = 0;
			fPos[2] = 0;
		}

		myHMD->X = fPos[0];
		myHMD->Y = fPos[1];
		myHMD->Z = fPos[2];
		myHMD->Yaw = MyOffset(RazorIMU[2], yprOffset[2]);
		myHMD->Pitch = MyOffset(RazorIMU[0], yprOffset[0]) * -1;
		myHMD->Roll = MyOffset(RazorIMU[1], yprOffset[1]) * -1;

		return 1;
	}
	else {
		myHMD->X = 0;
		myHMD->Y = 0;
		myHMD->Z = 0;

		myHMD->X = fPos[0];
		myHMD->Y = fPos[1];
		myHMD->Z = fPos[2];

		myHMD->Yaw = 0;
		myHMD->Pitch = 0;
		myHMD->Roll = 0;

		return 0;
	}
}

DLLEXPORT DWORD __stdcall GetControllersData(__out TController *myController, __out TController *myController2)
{
	//Controller 1
	myController->X = 0;
	myController->Y = 0;
	myController->Z = 0;

	myController->Yaw = 0;
	myController->Pitch = 0;
	myController->Roll = 0;

	myController->Buttons = 0;
	myController->Trigger = 0;
	myController->ThumbX = 0;
	myController->ThumbY = 0;

	//Controller 2
	myController2->X = 0;
	myController2->Y = 0;
	myController2->Z = 0;

	myController2->Yaw = 0;
	myController2->Pitch = 0;
	myController2->Roll = 0;

	myController2->Buttons = 0;
	myController2->Trigger = 0;
	myController2->ThumbX = 0;
	myController2->ThumbY = 0;

	return 0;
}

DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in WORD	MotorSpeed)
{
	return 0;
}

DLLEXPORT DWORD __stdcall SetCentering(__in int dwIndex)
{
	if (HMDConnected && dwIndex == 0) {
		yprOffset[0] = RazorIMU[0];
		yprOffset[1] = RazorIMU[1];
		yprOffset[2] = RazorIMU[2];

		return 1;
	}
	else {
		return 0;
	}

}