#include "stdafx.h"
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
	WORD	Buttons;
	BYTE	Trigger;
	SHORT	ThumbX;
	SHORT	ThumbY;
} TController, *PController;

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *myHMD);
DLLEXPORT DWORD __stdcall GetControllersData(__out TController *MyController, __out TController *MyController2);
DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in WORD	MotorSpeed);
DLLEXPORT DWORD __stdcall SetCentering(__in int dwIndex);

HANDLE hSerial, hSerial2;
bool Controller1Connected = false, Controller2Connected = false, ControllersInit = false;
float Ctrl1YRPOffset[3], Ctrl2YRPOffset[3];
std::thread *pCtrl1thread = NULL;
std::thread *pCtrl2thread = NULL;
float ArduinoCtrl1[7], ArduinoCtrl2[7];

void Controller1Read()
{
	DWORD bytesRead;
	memset(&ArduinoCtrl1, 0, sizeof(ArduinoCtrl1));

	while (Controller1Connected) {
		ReadFile(hSerial, &ArduinoCtrl1, sizeof(ArduinoCtrl1), &bytesRead, 0);
	}
}

void Controller2Read()
{
	DWORD bytesRead;
	memset(&ArduinoCtrl2, 0, sizeof(ArduinoCtrl2));

	while (Controller2Connected) {
		ReadFile(hSerial2, &ArduinoCtrl2, sizeof(ArduinoCtrl2), &bytesRead, 0);
	}
}

void ControllersStart() {
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
	configPath.Format(_T("%sArduinoControllers.ini"), _driversPath);

	if (status == ERROR_SUCCESS && PathFileExists(configPath)) {

		CIniReader IniFile((char *)configPath.GetBuffer());
		//Controller 1
		CString sPortName;
		//sPortName.Format(_T("COM%d"), 3);
		sPortName.Format(_T("COM%d"), IniFile.ReadInteger("Controller1", "ComPort", 2));

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
		sPortName.Format(_T("COM%d"), IniFile.ReadInteger("Controller2", "ComPort", 3));

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

double MyOffset(float f, float f2)
{
	f -= f2;
	if (f < -180) {
		f += 360;
	}
	else if (f > 180) {
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

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *myHMD)
{
	myHMD->X = 0;
	myHMD->Y = 0;
	myHMD->Z = 0;

	myHMD->Yaw = 0;
	myHMD->Pitch = 0;
	myHMD->Roll = 0;

	return 0;
}

DLLEXPORT DWORD __stdcall GetControllersData(__out TController *myController, __out TController *myController2)
{
	if (ControllersInit == false) {
		ControllersInit = true;
		ControllersStart();
	}
	//Controller 1
	myController->X = -0.1;
	myController->Y = -0.05;
	myController->Z = -0.25;

	if (Controller1Connected) {
		myController->Yaw = MyOffset(ArduinoCtrl1[0], Ctrl1YRPOffset[0]);
		myController->Pitch = MyOffset(ArduinoCtrl1[1], Ctrl1YRPOffset[1]);
		myController->Roll = MyOffset(ArduinoCtrl1[2], Ctrl1YRPOffset[2]);

		myController->Buttons = round(ArduinoCtrl1[4]);
		myController->Trigger = round(ArduinoCtrl1[3]);
		myController->ThumbX = round(ArduinoCtrl1[5]);
		myController->ThumbY = round(ArduinoCtrl1[6]);
	}
	else {
		myController->Yaw = 0;
		myController->Pitch = 0;
		myController->Roll = 0;

		myController->Buttons = 0;
		myController->Trigger = 0;
		myController->ThumbX = 0;
		myController->ThumbY = 0;
	}

	//Controller 2
	myController2->X = 0.1;
	myController2->Y = -0.05;
	myController2->Z = -0.25;

	if (Controller2Connected) {
		myController2->Yaw = MyOffset(ArduinoCtrl2[0], Ctrl2YRPOffset[0]);
		myController2->Pitch = MyOffset(ArduinoCtrl2[1], Ctrl2YRPOffset[1]);
		myController2->Roll = MyOffset(ArduinoCtrl2[2], Ctrl2YRPOffset[2]);

		myController2->Buttons = round(ArduinoCtrl2[4]);
		myController2->Trigger = round(ArduinoCtrl2[3]);
		myController2->ThumbX = round(ArduinoCtrl2[5]);
		myController2->ThumbY = round(ArduinoCtrl2[6]);
	}
	else {
		myController2->Yaw = 0;
		myController2->Pitch = 0;
		myController2->Roll = 0;

		myController2->Buttons = 0;
		myController2->Trigger = 0;
		myController2->ThumbX = 0;
		myController2->ThumbY = 0;
	}

	if (Controller1Connected || Controller2Connected) {
		return 1;
	}
	else {
		return 0;
	}
}

DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in WORD	MotorSpeed)
{
	//Soon
	return 0;
}

DLLEXPORT DWORD __stdcall SetCentering(__in int dwIndex)
{
	if (Controller1Connected && dwIndex == 1) {
		Ctrl1YRPOffset[0] = ArduinoCtrl1[0];
		Ctrl1YRPOffset[1] = ArduinoCtrl1[1];
		Ctrl1YRPOffset[2] = ArduinoCtrl1[2];
	}
	if (Controller2Connected && dwIndex == 2) {
		Ctrl2YRPOffset[0] = ArduinoCtrl2[0];
		Ctrl2YRPOffset[1] = ArduinoCtrl2[1];
		Ctrl2YRPOffset[2] = ArduinoCtrl2[2];
	}
	if (Controller1Connected || Controller2Connected) {
		return 1;
	}
	else {
		return 0;
	}

}