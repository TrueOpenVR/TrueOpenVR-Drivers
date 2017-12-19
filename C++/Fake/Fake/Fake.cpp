#include "stdafx.h"
#include <windows.h>
#include <stdlib.h>

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

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD* myHMD);
DLLEXPORT DWORD __stdcall GetControllersData(__out TController* MyController, __out TController* MyController2);
DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in WORD	MotorSpeed);
DLLEXPORT DWORD __stdcall SetCentering(__in int dwIndex);

int RandBtn[5] = {1, 2, 4, 8};
int HMDMode = 0, ControllerMode = 0;
double myX = 0, myY = 0, myZ = 0, myYaw = 0, myPitch = 0, myRoll = 0;
double myCtrlX = 0, myCtrlY = 0, myCtrlZ = 0, myCtrlYaw = 0, myCtrlPitch = 0, myCtrlRoll = 0;
double myCtrl2X = 0, myCtrl2Y = 0, myCtrl2Z = 0, myCtrl2Yaw = 0, myCtrl2Pitch = 0, myCtrl2Roll = 0;

BOOL APIENTRY DllMain(HMODULE hModule, DWORD  ul_reason_for_call, LPVOID lpReserved)
{
	/*switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH:
		break;
	}*/
	return TRUE;
}

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD* myHMD)
{
	if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0 && (GetAsyncKeyState(VK_MENU) & 0x8000) != 0 && (GetAsyncKeyState(49) & 0x8000) != 0)
		HMDMode = 1;
	if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0 && (GetAsyncKeyState(VK_MENU) & 0x8000) != 0 && (GetAsyncKeyState(50) & 0x8000) != 0)
		HMDMode = 2;
	if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0 && (GetAsyncKeyState(VK_MENU) & 0x8000) != 0 && (GetAsyncKeyState(51) & 0x8000) != 0)
		HMDMode = 0;

	switch (HMDMode) {
	case 0:
		myHMD->X = 0.015;
		myHMD->Y = 0.06;
		myHMD->Z = 0.037;
		myHMD->Yaw = 45;
		myHMD->Pitch = -25;
		myHMD->Roll = -10;
		break;
	

	case 1:
		if (myX < 0.1) {
			myX += 0.001;
		}
		else if (myY < 0.1) {
			myY += 0.001;
		}
		else if (myZ < 0.1) {
			myZ += 0.001;
		}
		else if (myYaw < 20)
		{
			myYaw += 0.1;
		}
		else if (myPitch < 20)
		{
			myPitch += 0.1;
		}
		else if (myRoll < 20)
		{
			myRoll += 0.1;
		}
		else {
			myX = 0;
			myY = 0;
			myZ = 0;
			myYaw = 0;
			myPitch = 0;
			myRoll = 0;
		}

		myHMD->X = myX;
		myHMD->Y = myY;
		myHMD->Z = myZ;
		myHMD->Yaw = myYaw;
		myHMD->Pitch = myPitch - 25;
		myHMD->Roll = myRoll - 10;
		break;

	case 2:
		myHMD->X = (rand() % 1000 + 1) / 1000.0;
		myHMD->Y = (rand() % 1000 + 1) / 1000.0;
		myHMD->Z = (rand() % 1000 + 1) / 1000.0;
		myHMD->Yaw = (rand() % 180 + 1) - (rand() % 180 + 1);
		myHMD->Pitch = (rand() % 180 + 1) - (rand() % 180 + 1);
		myHMD->Roll = (rand() % 180 + 1) - (rand() % 180 + 1);
		break;
	}

	return 1;
}

DLLEXPORT DWORD __stdcall GetControllersData(__out TController* myController, __out TController* myController2)
{
	if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0 && (GetAsyncKeyState(VK_MENU) & 0x8000) != 0 && (GetAsyncKeyState(52) & 0x8000) != 0)
		ControllerMode = 1;
	if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0 && (GetAsyncKeyState(VK_MENU) & 0x8000) != 0 && (GetAsyncKeyState(53) & 0x8000) != 0)
		ControllerMode = 0;

	switch (ControllerMode) {
	case 0:
		myController->X = 0.24;
		myController->Y = -0.83;
		myController->Z = 0.71;

		myController->Yaw = 15;
		myController->Pitch = 32;
		myController->Roll = -10;

		myController->Buttons = 1;
		myController->Trigger = 135;
		myController->ThumbX = -6371;
		myController->ThumbY = 24459;


		myController2->X = 0.25;
		myController2->Y = 0.83;
		myController2->Z = 0.74;

		myController2->Yaw = 31;
		myController2->Pitch = 12;
		myController2->Roll = -24;

		myController2->Buttons = 2;
		myController2->Trigger = 255;
		myController2->ThumbX = -200;
		myController2->ThumbY = 15392;
		break;
	case 1:
		myController->X = (rand() % 1000 + 1) / 1000.0;
		myController->Y = (rand() % 1000 + 1) / 1000.0;
		myController->Z = (rand() % 1000 + 1) / 1000.0;

		myController->Yaw = (rand() % 180 + 1) - (rand() % 180 + 1);
		myController->Pitch = (rand() % 180 + 1) - (rand() % 180 + 1);
		myController->Roll = (rand() % 180 + 1) - (rand() % 180 + 1);

		myController->Buttons = RandBtn[rand() % 5];
		myController->Trigger = rand() % 255 + 1;
		myController->ThumbX = (rand() % 32767 + 1) - (rand() % 32767 + 1);
		myController->ThumbY = (rand() % 32767 + 1) - (rand() % 32767 + 1);


		myController2->X = (rand() % 1000 + 1) / 1000.0;
		myController2->Y = (rand() % 1000 + 1) / 1000.0;
		myController2->Z = (rand() % 1000 + 1) / 1000.0;

		myController2->Yaw = (rand() % 180 + 1) - (rand() % 180 + 1);
		myController2->Pitch = (rand() % 180 + 1) - (rand() % 180 + 1);
		myController2->Roll = (rand() % 180 + 1) - (rand() % 180 + 1);

		myController2->Buttons = RandBtn[rand() % 5];
		myController2->Trigger = rand() % 255 + 1;
		myController2->ThumbX = (rand() % 32767 + 1) - (rand() % 32767 + 1);
		myController2->ThumbY = (rand() % 32767 + 1) - (rand() % 32767 + 1);
		break;
	}

	return 1;
}

DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in WORD	MotorSpeed)
{
	return 1;
}

DLLEXPORT DWORD __stdcall SetCentering(__in int dwIndex)
{
	return 1;
}