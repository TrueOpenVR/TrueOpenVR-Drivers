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
	unsigned short	Buttons;
	float	Trigger;
	float	AxisX;
	float	AxisY;
} TController, *PController;

#define TOVR_SUCCESS 0
#define TOVR_FAILURE 1

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

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *HMD)
{
	if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0 && (GetAsyncKeyState(VK_MENU) & 0x8000) != 0 && (GetAsyncKeyState(49) & 0x8000) != 0)
		HMDMode = 1;
	if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0 && (GetAsyncKeyState(VK_MENU) & 0x8000) != 0 && (GetAsyncKeyState(50) & 0x8000) != 0)
		HMDMode = 2;
	if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0 && (GetAsyncKeyState(VK_MENU) & 0x8000) != 0 && (GetAsyncKeyState(51) & 0x8000) != 0)
		HMDMode = 0;

	switch (HMDMode) {
	case 0:
		HMD->X = 0.015;
		HMD->Y = 0.06;
		HMD->Z = 0.037;
		HMD->Yaw = 45;
		HMD->Pitch = -25;
		HMD->Roll = -10;
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

		HMD->X = myX;
		HMD->Y = myY;
		HMD->Z = myZ;
		HMD->Yaw = myYaw;
		HMD->Pitch = myPitch - 25;
		HMD->Roll = myRoll - 10;
		break;

	case 2:
		HMD->X = (rand() % 1000 + 1) / 1000.0;
		HMD->Y = (rand() % 1000 + 1) / 1000.0;
		HMD->Z = (rand() % 1000 + 1) / 1000.0;
		HMD->Yaw = (rand() % 180 + 1) - (rand() % 180 + 1);
		HMD->Pitch = (rand() % 180 + 1) - (rand() % 180 + 1);
		HMD->Roll = (rand() % 180 + 1) - (rand() % 180 + 1);
		break;
	}

	return TOVR_SUCCESS;
}

DLLEXPORT DWORD __stdcall GetControllersData(__out TController *FirstController, __out TController *SecondController)
{
	if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0 && (GetAsyncKeyState(VK_MENU) & 0x8000) != 0 && (GetAsyncKeyState(52) & 0x8000) != 0)
		ControllerMode = 1;
	if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0 && (GetAsyncKeyState(VK_MENU) & 0x8000) != 0 && (GetAsyncKeyState(53) & 0x8000) != 0)
		ControllerMode = 0;

	switch (ControllerMode) {
	case 0:
		FirstController->X = 0.24;
		FirstController->Y = -0.83;
		FirstController->Z = 0.71;

		FirstController->Yaw = 15;
		FirstController->Pitch = 32;
		FirstController->Roll = -10;

		FirstController->Buttons = 1;
		FirstController->Trigger = 0.78;
		FirstController->AxisX = -0.35;
		FirstController->AxisY = 0.61;


		SecondController->X = 0.25;
		SecondController->Y = 0.83;
		SecondController->Z = 0.74;

		SecondController->Yaw = 31;
		SecondController->Pitch = 12;
		SecondController->Roll = -24;

		SecondController->Buttons = 2;
		SecondController->Trigger = 0.94;
		SecondController->AxisX = -0.25;
		SecondController->AxisY = 1;
		break;
	case 1:
		FirstController->X = (rand() % 1000 + 1) / 1000.0;
		FirstController->Y = (rand() % 1000 + 1) / 1000.0;
		FirstController->Z = (rand() % 1000 + 1) / 1000.0;

		FirstController->Yaw = (rand() % 180 + 1) - (rand() % 180 + 1);
		FirstController->Pitch = (rand() % 180 + 1) - (rand() % 180 + 1);
		FirstController->Roll = (rand() % 180 + 1) - (rand() % 180 + 1);

		FirstController->Buttons = RandBtn[rand() % 5];
		FirstController->Trigger = rand() % 100 * 0.01;
		FirstController->AxisX = (rand() % 100 * 0.01) - (rand() % 100 * 0.01);
		FirstController->AxisY = (rand() % 100 * 0.01) - (rand() % 100 * 0.01);


		SecondController->X = (rand() % 1000 + 1) / 1000.0;
		SecondController->Y = (rand() % 1000 + 1) / 1000.0;
		SecondController->Z = (rand() % 1000 + 1) / 1000.0;

		SecondController->Yaw = (rand() % 180 + 1) - (rand() % 180 + 1);
		SecondController->Pitch = (rand() % 180 + 1) - (rand() % 180 + 1);
		SecondController->Roll = (rand() % 180 + 1) - (rand() % 180 + 1);

		SecondController->Buttons = RandBtn[rand() % 5];
		SecondController->Trigger = rand() % 100 * 0.01;
		SecondController->AxisX = (rand() % 100 * 0.01) - (rand() % 100 * 0.01);
		SecondController->AxisY = (rand() % 100 * 0.01) - (rand() % 100 * 0.01);
		break;
	}

	return TOVR_FAILURE;
}

DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in unsigned char MotorSpeed)
{
	return TOVR_FAILURE;
}
