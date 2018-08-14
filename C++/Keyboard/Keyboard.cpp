#include "stdafx.h"
#include <windows.h>

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

#define GRIPBTN 0x0001
#define THUMBSTICKBTN 0x0002
#define MENUBTN 0x0004
#define SYSTEMBTN 0x0008

#define StepPos 0.0033;
#define StepRot 0.4;
double HMDPos[3], HMDPitch;

double CtrlPos[3], CtrlYaw, CtrlRoll;

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *myHMD)
{
	if ((GetAsyncKeyState(VK_NUMPAD8) & 0x8000) != 0) HMDPos[2] -= StepPos;
	if ((GetAsyncKeyState(VK_NUMPAD2) & 0x8000) != 0) HMDPos[2] += StepPos;

	if ((GetAsyncKeyState(VK_NUMPAD4) & 0x8000) != 0) HMDPos[0] -= StepPos;
	if ((GetAsyncKeyState(VK_NUMPAD6) & 0x8000) != 0) HMDPos[0] += StepPos;

	if ((GetAsyncKeyState(VK_PRIOR) & 0x8000) != 0) HMDPos[1] += StepPos;
	if ((GetAsyncKeyState(VK_NEXT) & 0x8000) != 0) HMDPos[1] -=  StepPos;

	//Yaw fixing
	if ((GetAsyncKeyState(VK_NUMPAD1) & 0x8000) != 0) HMDPitch += StepRot;
	if ((GetAsyncKeyState(VK_NUMPAD3) & 0x8000) != 0) HMDPitch -= StepRot;

	myHMD->X = HMDPos[0];
	myHMD->Y = HMDPos[1];
	myHMD->Z = HMDPos[2];

	myHMD->Yaw = 0;
	myHMD->Pitch = HMDPitch;
	myHMD->Roll = 0;

	return 1;
}

#define StepCtrlPos 0.005;

DLLEXPORT DWORD __stdcall GetControllersData(__out TController *myController, __out TController *myController2)
{
	if ((GetAsyncKeyState(87) & 0x8000) != 0) CtrlPos[2] -= StepCtrlPos; //W
	if ((GetAsyncKeyState(83) & 0x8000) != 0) CtrlPos[2] += StepCtrlPos; //S

	if ((GetAsyncKeyState(65) & 0x8000) != 0) CtrlPos[0] -= StepCtrlPos; //A
	if ((GetAsyncKeyState(68) & 0x8000) != 0) CtrlPos[0] += StepCtrlPos; //D

	if ((GetAsyncKeyState(81) & 0x8000) != 0) CtrlPos[1] += StepCtrlPos; //Q
	if ((GetAsyncKeyState(69) & 0x8000) != 0) CtrlPos[1] -= StepCtrlPos; //E

	if ((GetAsyncKeyState(85) & 0x8000) != 0) CtrlRoll += StepRot; //U
	if ((GetAsyncKeyState(74) & 0x8000) != 0) CtrlRoll -= StepRot; //J

	if ((GetAsyncKeyState(72) & 0x8000) != 0) CtrlYaw += StepRot; //H
	if ((GetAsyncKeyState(75) & 0x8000) != 0) CtrlYaw -= StepRot; //K

	//Controller 1
	myController->X = CtrlPos[0] + (-0.2);
	myController->Y = CtrlPos[1];
	myController->Z = CtrlPos[2] - 0.5;

	myController->Yaw = CtrlYaw;
	myController->Pitch = 0;
	myController->Roll = CtrlRoll;

	myController->Buttons = 0;
	if ((GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0) myController->Buttons += GRIPBTN;
	if ((GetAsyncKeyState(90) & 0x8000) != 0) myController->Buttons += SYSTEMBTN; //z
	if ((GetAsyncKeyState(49) & 0x8000) != 0) myController->Buttons += THUMBSTICKBTN; //1
	if ((GetAsyncKeyState(51) & 0x8000) != 0) myController->Buttons += MENUBTN; //3

	myController->Trigger = 0;
	if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0) myController->Trigger = 255;

	myController->ThumbX = 0;
	myController->ThumbY = 0;

	//Controller 2
	myController2->X = CtrlPos[0] + 0.2;
	myController2->Y = CtrlPos[1];
	myController2->Z = CtrlPos[2] - 0.5;

	myController2->Yaw = CtrlYaw;
	myController2->Pitch = 0;
	myController2->Roll = CtrlRoll;

	myController2->Buttons = 0;
	if ((GetAsyncKeyState(67) & 0x8000) != 0) myController2->Buttons += GRIPBTN; //c
	if ((GetAsyncKeyState(88) & 0x8000) != 0) myController2->Buttons += SYSTEMBTN; //x
	if ((GetAsyncKeyState(50) & 0x8000) != 0) myController2->Buttons += THUMBSTICKBTN; //2
	if ((GetAsyncKeyState(52) & 0x8000) != 0) myController2->Buttons += MENUBTN; //4

	myController2->Trigger = 0;
	if ((GetAsyncKeyState(VK_MENU) & 0x8000) != 0) myController2->Trigger = 255;
	myController2->ThumbX = 0;
	myController2->ThumbY = 0;

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

BOOL APIENTRY DllMain(HMODULE hModule, DWORD  ul_reason_for_call, LPVOID lpReserved)
{
	/*	{
	case DLL_PROCESS_ATTACH:
	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH:
	break;
	}*/

	return TRUE;
}