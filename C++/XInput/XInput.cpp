#include "stdafx.h"
#include <windows.h>
#include <atlstr.h> 

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

#define XINPUT_GAMEPAD_DPAD_UP          0x0001
#define XINPUT_GAMEPAD_DPAD_DOWN        0x0002
#define XINPUT_GAMEPAD_DPAD_LEFT        0x0004
#define XINPUT_GAMEPAD_DPAD_RIGHT       0x0008
#define XINPUT_GAMEPAD_START            0x0010
#define XINPUT_GAMEPAD_BACK             0x0020
#define XINPUT_GAMEPAD_LEFT_THUMB       0x0040
#define XINPUT_GAMEPAD_RIGHT_THUMB      0x0080
#define XINPUT_GAMEPAD_LEFT_SHOULDER    0x0100
#define XINPUT_GAMEPAD_RIGHT_SHOULDER   0x0200
#define XINPUT_GAMEPAD_A                0x1000
#define XINPUT_GAMEPAD_B                0x2000
#define XINPUT_GAMEPAD_X                0x4000
#define XINPUT_GAMEPAD_Y				0x8000

#define XUSER_MAX_COUNT                 4
#define XUSER_INDEX_ANY					0x000000FF

#define ERROR_DEVICE_NOT_CONNECTED		1167
#define ERROR_SUCCESS					0

//
// Structures used by XInput APIs
//
typedef struct _XINPUT_GAMEPAD
{
	WORD                                wButtons;
	BYTE                                bLeftTrigger;
	BYTE                                bRightTrigger;
	SHORT                               sThumbLX;
	SHORT                               sThumbLY;
	SHORT                               sThumbRX;
	SHORT                               sThumbRY;
} XINPUT_GAMEPAD, *PXINPUT_GAMEPAD;

typedef struct _XINPUT_STATE
{
	DWORD                               dwPacketNumber;
	XINPUT_GAMEPAD                      Gamepad;
} XINPUT_STATE, *PXINPUT_STATE;

/*typedef struct _XINPUT_VIBRATION
{
	WORD                                wLeftMotorSpeed;
	WORD                                wRightMotorSpeed;
} XINPUT_VIBRATION, *PXINPUT_VIBRATION;*/

typedef DWORD(__stdcall *_XInputGetState)(_In_ DWORD dwUserIndex, _Out_ XINPUT_STATE *pState);
//typedef DWORD(__stdcall *_XInputSetState)(_In_ DWORD dwUserIndex, _In_ XINPUT_VIBRATION *pVibration);

_XInputGetState MyXInputGetState;
//_XInputSetState MyXInputSetState;

HMODULE hDll;
bool GamePadConnected = false, GamePadInit = false;
XINPUT_STATE myPState;

void GamePadStart() {
	hDll = LoadLibrary(_T("C:\\Windows\\System32\\xinput1_3.dll"));

	if (hDll != NULL) {

		MyXInputGetState = (_XInputGetState)GetProcAddress(hDll, "XInputGetState");
		//MyXInputSetState = (_XInputSetState)GetProcAddress(hDll, "XInputSetState"); //Vibration 

		if (MyXInputGetState != NULL)// && MyXInputSetState != NULL) {
			if (MyXInputGetState(0, &myPState) == ERROR_SUCCESS)
				GamePadConnected = true;
		//} 
	}
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
	if (GamePadInit == false) {
		GamePadInit = true;
		GamePadStart();
	}

	//Controller 1
	myController->X = 0;
	myController->Y = 0;
	myController->Z = 0;

	myController->Yaw = 0;
	myController->Pitch = 0;
	myController->Roll = 0;

	myController->Buttons = 0;

	//Controller 2
	myController2->X = 0;
	myController2->Y = 0;
	myController2->Z = 0;

	myController2->Yaw = 0;
	myController2->Pitch = 0;
	myController2->Roll = 0;

	myController2->Buttons = 0;

	if (GamePadConnected) {
		MyXInputGetState(0, &myPState);

		//Controller 1
		myController->Trigger = myPState.Gamepad.bLeftTrigger;
		myController->ThumbX = myPState.Gamepad.sThumbLX;
		myController->ThumbY = myPState.Gamepad.sThumbLY;

		if (myPState.Gamepad.wButtons & XINPUT_GAMEPAD_BACK)
			myController->Buttons += SYSTEMBTN;

		if (myPState.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER)
			myController->Buttons += GRIPBTN;

		if (myPState.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB)
			myController->Buttons += THUMBSTICKBTN;

		if (myPState.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_UP)
			myController->Buttons += MENUBTN;

		//Controller 2
		myController2->Trigger = myPState.Gamepad.bRightTrigger;
		myController2->ThumbX = myPState.Gamepad.sThumbRX;
		myController2->ThumbY = myPState.Gamepad.sThumbRY;

		if (myPState.Gamepad.wButtons & XINPUT_GAMEPAD_START)
			myController2->Buttons += SYSTEMBTN;

		if (myPState.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER)
			myController2->Buttons += GRIPBTN;

		if (myPState.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_THUMB)
			myController2->Buttons += THUMBSTICKBTN;

		if (myPState.Gamepad.wButtons &  XINPUT_GAMEPAD_Y)
			myController2->Buttons += MENUBTN;

		return 1;
	}
	else {
		//Controller 1
		myController->Trigger = 0;
		myController->ThumbX = 0;
		myController->ThumbY = 0;

		//Controller 2
		myController2->Trigger = 0;
		myController2->ThumbX = 0;
		myController2->ThumbY = 0;

		return 0;
	}
}

DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in WORD	MotorSpeed)
{
	return 0;
}

DLLEXPORT DWORD __stdcall SetCentering(__in int dwIndex)
{
	return 0;
}

BOOL APIENTRY DllMain(HMODULE hModule,
	DWORD  ul_reason_for_call,
	LPVOID lpReserved
)
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_DETACH:
		if (hDll != NULL) {
			FreeLibrary(hDll);
			hDll = nullptr;
		}
		break;
	}
	return TRUE;
}
