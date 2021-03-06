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
	unsigned short	Buttons;
	float	Trigger;
	float	AxisX;
	float	AxisY;
} TController, *PController;

#define TOVR_SUCCESS 0
#define TOVR_FAILURE 1

#define GRIP_BTN	0x0001
#define THUMB_BTN	0x0002
#define A_BTN		0x0004
#define B_BTN		0x0008
#define MENU_BTN	0x0010
#define SYS_BTN		0x0020

#define StepPos 0.0033;
#define StepRot 0.4;
double HMDPos[3] = { 0, 0, 0 }, HMDYaw = 180, HMDPitch = 0;

double CtrlPos[3] = { 0, 0, 0 }, CtrlsPitch = 180, CtrlsRoll = 180;

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *HMD)
{
	if ((GetAsyncKeyState(VK_NUMPAD8) & 0x8000) != 0) HMDPos[1] -= StepPos;
	if ((GetAsyncKeyState(VK_NUMPAD2) & 0x8000) != 0) HMDPos[1] += StepPos;

	if ((GetAsyncKeyState(VK_NUMPAD4) & 0x8000) != 0) HMDPos[0] -= StepPos;
	if ((GetAsyncKeyState(VK_NUMPAD6) & 0x8000) != 0) HMDPos[0] += StepPos;

	if ((GetAsyncKeyState(VK_PRIOR) & 0x8000) != 0) HMDPos[2] += StepPos;
	if ((GetAsyncKeyState(VK_NEXT) & 0x8000) != 0) HMDPos[2] -=  StepPos;

	//Yaw fixing
	if ((GetAsyncKeyState(VK_NUMPAD1) & 0x8000) != 0) HMDYaw -= StepRot;
	if ((GetAsyncKeyState(VK_NUMPAD3) & 0x8000) != 0) HMDYaw += StepRot;
	if (HMDYaw > 360)
		HMDYaw = 0;
	if (HMDYaw < 0)
		HMDYaw = 360;

	if ((GetAsyncKeyState(VK_NUMPAD7) & 0x8000) != 0) HMDPitch += StepRot;
	if ((GetAsyncKeyState(VK_NUMPAD9) & 0x8000) != 0) HMDPitch -= StepRot;
	if (HMDPitch > 90)
		HMDPitch = 90;
	if (HMDPitch < -90)
		HMDPitch = -90;

	if ((GetAsyncKeyState(VK_SUBTRACT) & 0x8000) != 0) {
		HMDPos[0] = 0;
		HMDPos[1] = 0;
		HMDPos[2] = 0;

		HMDYaw = 180;
		HMDPitch = 0;

		CtrlsPitch = 180;
		CtrlsRoll = 180;
	}


	HMD->X = HMDPos[0];
	HMD->Y = HMDPos[1];
	HMD->Z = HMDPos[2];

	HMD->Yaw = HMDYaw - 180;
	HMD->Pitch = HMDPitch;
	HMD->Roll = 0;

	return TOVR_SUCCESS;
}

#define StepCtrlPos 0.005;

DLLEXPORT DWORD __stdcall GetControllersData(__out TController *FirstController, __out TController *SecondController)
{
	if ((GetAsyncKeyState('W') & 0x8000) != 0) CtrlPos[1] -= StepCtrlPos;
	if ((GetAsyncKeyState('S') & 0x8000) != 0) CtrlPos[1] += StepCtrlPos;

	if ((GetAsyncKeyState('A') & 0x8000) != 0) CtrlPos[0] -= StepCtrlPos;
	if ((GetAsyncKeyState('D') & 0x8000) != 0) CtrlPos[0] += StepCtrlPos;

	if ((GetAsyncKeyState('Q') & 0x8000) != 0) CtrlPos[2] += StepCtrlPos;
	if ((GetAsyncKeyState('E') & 0x8000) != 0) CtrlPos[2] -= StepCtrlPos;


	if ((GetAsyncKeyState('U') & 0x8000) != 0) CtrlsPitch += StepRot;
	if ((GetAsyncKeyState('J') & 0x8000) != 0) CtrlsPitch -= StepRot;
	if (CtrlsPitch > 360) CtrlsPitch = 0;
	if (CtrlsPitch < 0) CtrlsPitch = 360;

	if ((GetAsyncKeyState('H') & 0x8000) != 0) CtrlsRoll -= StepRot;
	if ((GetAsyncKeyState('K') & 0x8000) != 0) CtrlsRoll += StepRot;
	if (CtrlsRoll > 360) CtrlsRoll = 0;
	if (CtrlsRoll < 0) CtrlsRoll = 360;

	if ((GetAsyncKeyState('Y') & 0x8000) != 0)
	{
		CtrlsRoll = 180;
		CtrlsPitch = 180;
	}

	//Controller 1
	FirstController->X = CtrlPos[0] - 0.2;
	FirstController->Y = CtrlPos[1] - 0.5;
	FirstController->Z = CtrlPos[2];

	FirstController->Yaw = 0;
	FirstController->Pitch = CtrlsPitch - 180;
	FirstController->Roll = CtrlsRoll - 180;

	FirstController->Buttons = 0;
	if ((GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0) FirstController->Buttons |= GRIP_BTN;
	if ((GetAsyncKeyState('1') & 0x8000) != 0) FirstController->Buttons |= SYS_BTN; //1
	if ((GetAsyncKeyState('2') & 0x8000) != 0) FirstController->Buttons |= THUMB_BTN; //2
	if ((GetAsyncKeyState('3') & 0x8000) != 0) FirstController->Buttons |= MENU_BTN; //3
	if ((GetAsyncKeyState('4') & 0x8000) != 0) FirstController->Buttons |= A_BTN; //4
	if ((GetAsyncKeyState('5') & 0x8000) != 0) FirstController->Buttons |= B_BTN; //5

	FirstController->Trigger = 0;
	if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0) FirstController->Trigger = 1;

	FirstController->AxisX = 0; //1..0..-1
	FirstController->AxisY = 0; //1..0..-1

	//Controller 2
	SecondController->X = CtrlPos[0] + 0.2;
	SecondController->Y = CtrlPos[1] - 0.5;
	SecondController->Z = CtrlPos[2];

	SecondController->Yaw = 0;
	SecondController->Pitch = CtrlsPitch - 180;
	SecondController->Roll = CtrlsRoll - 180;

	SecondController->Buttons = 0;
	if ((GetAsyncKeyState('Z') & 0x8000) != 0) SecondController->Buttons |= GRIP_BTN; 
	if ((GetAsyncKeyState('6') & 0x8000) != 0) SecondController->Buttons |= SYS_BTN;
	if ((GetAsyncKeyState('7') & 0x8000) != 0) SecondController->Buttons |= THUMB_BTN;
	if ((GetAsyncKeyState('8') & 0x8000) != 0) SecondController->Buttons |= MENU_BTN;
	if ((GetAsyncKeyState('9') & 0x8000) != 0) SecondController->Buttons |= A_BTN;
	if ((GetAsyncKeyState('0') & 0x8000) != 0) SecondController->Buttons |= B_BTN;

	SecondController->Trigger = 0;
	if ((GetAsyncKeyState(VK_MENU) & 0x8000) != 0) SecondController->Trigger = 1;
	SecondController->AxisX = 0; //1..0..-1
	SecondController->AxisY = 0; //1..0..-1

	return TOVR_SUCCESS;
}

DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in unsigned char MotorSpeed)
{
	return TOVR_SUCCESS;
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD  ul_reason_for_call, LPVOID lpReserved)
{
	//switch (ul_reason_for_call) {
	//	case DLL_PROCESS_ATTACH:
	//		break;
	//	case DLL_THREAD_ATTACH:
	//		break;
	//	case DLL_THREAD_DETACH:
	//		break;
	//	case DLL_PROCESS_DETACH:
	//		break;
	//}

	return TRUE;
}