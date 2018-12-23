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
	unsigned short	Buttons;
	float	Trigger;
	float	AxisX;
	float	AxisY;
} TController, *PController;

#define TOVR_SUCCESS 0
#define TOVR_FAILURE 1

HANDLE hSerial;
bool HMDConnected = false, RazorInit = false, HMDInitCentring = false;
float RazorIMU[3], yprOffset[3]; //yaw, pitch, roll
double fPos[3];
std::thread *pRRthread = NULL;

DWORD SetCentering(__in int dwIndex)
{
	if (HMDConnected && dwIndex == 0) {
		yprOffset[0] = RazorIMU[0];
		yprOffset[1] = RazorIMU[1];
		yprOffset[2] = RazorIMU[2];

		return TOVR_SUCCESS;
	}
	else {
		return TOVR_FAILURE;
	}

}

void RazorIMURead()
{
	DWORD bytesRead;

	while (HMDConnected) {
		ReadFile(hSerial, &RazorIMU, sizeof(RazorIMU), &bytesRead, 0);
		if (HMDInitCentring == false)
			if (RazorIMU[0] != 0 || RazorIMU[1] != 0 || RazorIMU[2] != 0) {
				SetCentering(0);
				HMDInitCentring = true;
			}	
	}
}

void RazorStart(){
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

float OffsetYPR(float f, float f2)
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

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *HMD)
{
	if (RazorInit == false) {
		RazorInit = true;
		RazorStart();
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

		HMD->X = fPos[0];
		HMD->Y = fPos[1];
		HMD->Z = fPos[2];
		HMD->Yaw = OffsetYPR(RazorIMU[2], yprOffset[2]);
		HMD->Pitch = OffsetYPR(RazorIMU[0], yprOffset[0]) * -1;
		HMD->Roll = OffsetYPR(RazorIMU[1], yprOffset[1]) * -1;

		return TOVR_SUCCESS;
	}
	else {
		HMD->X = 0;
		HMD->Y = 0;
		HMD->Z = 0;

		HMD->X = fPos[0];
		HMD->Y = fPos[1];
		HMD->Z = fPos[2];

		HMD->Yaw = 0;
		HMD->Pitch = 0;
		HMD->Roll = 0;

		return TOVR_FAILURE;
	}
}

DLLEXPORT DWORD __stdcall GetControllersData(__out TController *FirstController, __out TController *SecondController)
{
	//Controller 1
	FirstController->X = 0;
	FirstController->Y = 0;
	FirstController->Z = 0;

	FirstController->Yaw = 0;
	FirstController->Pitch = 0;
	FirstController->Roll = 0;

	FirstController->Buttons = 0;
	FirstController->Trigger = 0;
	FirstController->AxisX = 0;
	FirstController->AxisY = 0;

	//Controller 2
	SecondController->X = 0;
	SecondController->Y = 0;
	SecondController->Z = 0;

	SecondController->Yaw = 0;
	SecondController->Pitch = 0;
	SecondController->Roll = 0;

	SecondController->Buttons = 0;
	SecondController->Trigger = 0;
	SecondController->AxisX = 0;
	SecondController->AxisY = 0;

	return TOVR_FAILURE;
}

DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in unsigned char MotorSpeed)
{
	return TOVR_FAILURE;
}