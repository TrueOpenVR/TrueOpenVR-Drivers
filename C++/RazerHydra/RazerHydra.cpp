#include <windows.h>
#include <math.h>
#include "sixense.h"

#if defined _M_X64
	#pragma comment( lib, "lib\\win64\\sixense_s_x64.lib" )
	#pragma comment( lib, "lib\\win64\\sixense_utils_s_x64.lib" )
#elif defined _M_IX86
	#pragma comment( lib, "lib\\win32\\sixense_s.lib" )
	#pragma comment( lib, "lib\\win32\\sixense_utils_s.lib" )
#endif

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

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *HMD);
DLLEXPORT DWORD __stdcall GetControllersData(__out TController *FirstController, __out TController *SecondController);
DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in unsigned char MotorSpeed);

#define TOVR_SUCCESS 0
#define TOVR_FAILURE 1

#define GRIP_BTN	0x0001
#define THUMB_BTN	0x0002
#define A_BTN		0x0004
#define B_BTN		0x0008
#define MENU_BTN	0x0010
#define SYS_BTN		0x0020

sixenseControllerData HydraController;

HMODULE hDll;
bool HydraInit = false, HydraConnected = false;
bool ctrlsInitCentring = false;

//Yaw, Pitch, Roll
float Ctrl1YPR[3], Ctrl2YPR[3];
//Offset YPR
float Ctrl1YPROffset[3] = { 0, 0, 0 }; float Ctrl2YPROffset[3] = { 0, 0, 0 };
//Pos calibration
double Ctrl1POSOffset[3] = { 0, 0.1, 0.3 }; double Ctrl2POSOffset[3] = {0, 0.1, 0.3 };

double HydraYawOffset = 0; 
double HydraPosYOffset = 0;

double RadToDeg(double r) {
	return r * (180 / 3.14159265358979323846); //180 / PI
}

double OffsetYPR(float f, float f2)
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

typedef struct
{
	double yaw, pitch, roll;
} DeviceRotation;

DeviceRotation QuatToYPR(double QuatW, double QuatX, double QuatY, double QuatZ)
{
	// roll (x-axis rotation)
	DeviceRotation OutRot;
	double sinr_cosp = 2.0 * (QuatW * QuatX + QuatY * QuatZ);
	double cosr_cosp = 1.0 - 2.0 * (QuatX * QuatX + QuatY * QuatY);
	OutRot.yaw = RadToDeg(atan2(sinr_cosp, cosr_cosp));

	// pitch (y-axis rotation)
	double sinp = 2.0 * (QuatW * QuatY - QuatZ * QuatX);
	if (fabs(sinp) >= 1)
		OutRot.pitch = RadToDeg(copysign(3.14159265358979323846 / 2, sinp)); // use 90 degrees if out of range
	else
		OutRot.pitch = RadToDeg(asin(sinp));

	// yaw (z-axis rotation)
	double siny_cosp = 2.0 * (QuatW * QuatZ + QuatX * QuatY);
	double cosy_cosp = 1.0 - 2.0 * (QuatY * QuatY + QuatZ * QuatZ);
	OutRot.roll = RadToDeg(atan2(siny_cosp, cosy_cosp));

	return OutRot;
}

void HydraStart()
{
	if (sixenseInit() == SIXENSE_SUCCESS)
		HydraConnected = true;
}

void SetCentering(int dwIndex)
{
	if (HydraConnected) {
		if (dwIndex == 1) {
			Ctrl1YPROffset[0] = Ctrl1YPR[0];
			Ctrl1YPROffset[1] = Ctrl1YPR[1];
			Ctrl1YPROffset[2] = Ctrl1YPR[2];
		}

		if (dwIndex == 2) {
			Ctrl2YPROffset[0] = Ctrl2YPR[0];
			Ctrl2YPROffset[1] = Ctrl2YPR[1];
			Ctrl2YPROffset[2] = Ctrl2YPR[2];
		}
	}
}

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *HMD)
{
	if (HydraInit == false)
	{
		HydraInit = true;
		HydraStart();
	}

	HMD->X = 0;
	HMD->Y = HydraPosYOffset;
	HMD->Z = 0;

	//Load library with rotation for HMD
	HMD->Yaw = 0;
	HMD->Pitch = 0;
	HMD->Pitch = 0;// OffsetYPR(0, HydraYawOffset); //Rotation with buttons like on PavlovVR. For games without button rotation
	HMD->Roll = 0;

	if (HydraConnected) {
		return TOVR_SUCCESS;
	}
	else {
		return TOVR_FAILURE;
	}
}

DLLEXPORT DWORD __stdcall GetControllersData(__out TController *FirstController, __out TController *SecondController)
{
	if (HydraInit == false)
	{
		HydraInit = true;
		HydraStart();
	}

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
	
	if (HydraConnected) {
		
		
		//Controller1
		sixenseGetData(1, 0, &HydraController);

		if (HydraController.buttons & SIXENSE_BUTTON_3)
			HydraPosYOffset += 0.03; //0.0033 def

		if (HydraController.buttons & SIXENSE_BUTTON_1)
			HydraPosYOffset -= 0.03;

		if (HydraController.buttons & SIXENSE_BUTTON_2)
			HydraPosYOffset = 0;
		
		//Position
		FirstController->X = HydraController.pos[0] * 0.001 - Ctrl1POSOffset[0];
		FirstController->Y = HydraController.pos[1] * 0.001 - Ctrl1POSOffset[1] + HydraPosYOffset;
		FirstController->Z = HydraController.pos[2] * 0.001 - Ctrl1POSOffset[2];
		
		//Rotation
		DeviceRotation CtrlRot;
		CtrlRot = QuatToYPR(HydraController.rot_quat[0], HydraController.rot_quat[1], HydraController.rot_quat[2], HydraController.rot_quat[3]);
		FirstController->Yaw = CtrlRot.yaw;
		FirstController->Pitch = CtrlRot.pitch;
		FirstController->Roll = CtrlRot.roll;
		
		//For centring
		Ctrl1YPR[0] = FirstController->Yaw;
		Ctrl1YPR[1] = FirstController->Pitch;
		Ctrl1YPR[2] = FirstController->Roll;

		//Offset YPR
		FirstController->Yaw = OffsetYPR(FirstController->Yaw, Ctrl1YPROffset[0]);
		FirstController->Pitch = OffsetYPR(FirstController->Pitch, Ctrl1YPROffset[1]) * -1; //HydraYawOffset 
		FirstController->Roll = OffsetYPR(FirstController->Roll, Ctrl1YPROffset[2]) * -1;

		//Buttons & axis
		if (HydraController.buttons & SIXENSE_BUTTON_START)
			FirstController->Buttons += SYS_BTN;
		if (HydraController.buttons & SIXENSE_BUTTON_JOYSTICK)
			FirstController->Buttons += THUMB_BTN;
		if (HydraController.buttons & SIXENSE_BUTTON_4)
			FirstController->Buttons += MENU_BTN;
		if (HydraController.buttons & SIXENSE_BUTTON_BUMPER)
			FirstController->Buttons += GRIP_BTN;
		FirstController->Trigger = HydraController.trigger;
		FirstController->AxisX = HydraController.joystick_x;
		FirstController->AxisY = HydraController.joystick_y;
		//end controller 1


		//Controller 2
		sixenseGetData(0, 1, &HydraController);

		//Position
		SecondController->X = HydraController.pos[0] * 0.001 - Ctrl2POSOffset[0];
		SecondController->Y = HydraController.pos[1] * 0.001 - Ctrl2POSOffset[1] + HydraPosYOffset;
		SecondController->Z = HydraController.pos[2] * 0.001 - Ctrl2POSOffset[2];

		//Rotation
		CtrlRot = QuatToYPR(HydraController.rot_quat[0], HydraController.rot_quat[1], HydraController.rot_quat[2], HydraController.rot_quat[3]);
		SecondController->Yaw = CtrlRot.yaw;
		SecondController->Pitch = CtrlRot.pitch;
		SecondController->Roll = CtrlRot.roll;
		
		//For centring
		Ctrl2YPR[0] = SecondController->Yaw;
		Ctrl2YPR[1] = SecondController->Pitch;
		Ctrl2YPR[2] = SecondController->Roll;

		//Offset YPR
		SecondController->Yaw = OffsetYPR(SecondController->Yaw, Ctrl2YPROffset[0]);
		SecondController->Pitch = OffsetYPR(SecondController->Pitch, Ctrl2YPROffset[1]) * -1; // HydraYawOffset
		SecondController->Roll = OffsetYPR(SecondController->Roll, Ctrl2YPROffset[2]) * -1;

		//Buttons & axis
		if (HydraController.buttons & SIXENSE_BUTTON_START)
			SecondController->Buttons += SYS_BTN;
		if (HydraController.buttons & SIXENSE_BUTTON_JOYSTICK)
			SecondController->Buttons += THUMB_BTN;
		if (HydraController.buttons & SIXENSE_BUTTON_3)
			SecondController->Buttons += MENU_BTN;
		if (HydraController.buttons & SIXENSE_BUTTON_BUMPER)
			SecondController->Buttons += GRIP_BTN;
		SecondController->AxisX = HydraController.joystick_x;
		SecondController->AxisY = HydraController.joystick_y;
		SecondController->Trigger = HydraController.trigger;

		/*if (HydraController.buttons & SIXENSE_BUTTON_1)
		if (HydraYawOffset >= -177)
			HydraYawOffset -= 3;

		if (HydraController.buttons & SIXENSE_BUTTON_2)
			if (HydraYawOffset < 177)
				HydraYawOffset += 3;

		if (HydraController.buttons & SIXENSE_BUTTON_4)
			HydraYawOffset = 0;*/

		//end controller 2

		//Calibration, it will be necessary to do as here - https://github.com/ValveSoftware/driver_hydra/blob/master/drivers/driver_hydra/driver_hydra.cpp
		if (!((FirstController->Buttons & GRIP_BTN) && (SecondController->Buttons & GRIP_BTN)))
			if ((FirstController->Buttons & SYS_BTN) && (SecondController->Buttons & SYS_BTN))
			{
				THMD MyHMD;
				GetHMDData(&MyHMD);
				Ctrl1POSOffset[0] = FirstController->X - 0.185; //37 cm between hands   0.0185
				if (SecondController->Y > MyHMD.Y)
				{
					Ctrl1POSOffset[1] = FirstController->Y - (FirstController->Y - MyHMD.Y) - 0.015;
				}
				else {
					Ctrl1POSOffset[1] = FirstController->Y - 0.015;
				}

				Ctrl1POSOffset[2] = FirstController->Z; //  - 0.01


				Ctrl2POSOffset[0] = SecondController->X + 0.185;
				if (SecondController->Y > MyHMD.Y)
				{
					Ctrl2POSOffset[1] = SecondController->Y - (SecondController->Y - MyHMD.Y) - 0.015;
				}
				else {
					Ctrl2POSOffset[1] = SecondController->Y - 0.015;
				}

				Ctrl2POSOffset[2] = SecondController->Z;
			}


		//Centring on start
		if (ctrlsInitCentring == false)
			if (FirstController->Yaw != 0 || FirstController->Pitch != 0 || FirstController->Roll != 0) {
				SetCentering(1);
				SetCentering(2);
				ctrlsInitCentring = true;
		}
		
		return TOVR_SUCCESS;
	}
	else {
		return TOVR_FAILURE;
	}
}

DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in unsigned char MotorSpeed)
{
	return TOVR_SUCCESS;
}

BOOL APIENTRY DllMain(HMODULE hModule,
	DWORD  ul_reason_for_call,
	LPVOID lpReserved
)
{
	switch (ul_reason_for_call)
	{
	//case DLL_PROCESS_ATTACH:
	//case DLL_THREAD_ATTACH:
	//case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH:
		if (hDll != NULL) {
			//sixenseExit();//?
			FreeLibrary(hDll);
			hDll = nullptr;
		}
		break;
	}
	return TRUE;
}

