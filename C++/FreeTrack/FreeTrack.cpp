#include "stdafx.h"
#include <thread>
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
DLLEXPORT DWORD __stdcall GetControllersData(__out TController *myController, __out TController *myController2);
DLLEXPORT DWORD __stdcall SetControllerData(__in int dwIndex, __in WORD	MotorSpeed);
DLLEXPORT DWORD __stdcall SetCentering(__in int dwIndex);

#define FREETRACK_HEAP "FT_SharedMem"
#define FREETRACK_MUTEX "FT_Mutext"

/* only 6 headpose floats and the data id are filled -sh */
typedef struct FTData__ {
	uint32_t DataID;
	int32_t CamWidth;
	int32_t CamHeight;
	/* virtual pose */
	float  Yaw;   /* positive yaw to the left */
	float  Pitch; /* positive pitch up */
	float  Roll;  /* positive roll to the left */
	float  X;
	float  Y;
	float  Z;
	/* raw pose with no smoothing, sensitivity, response curve etc. */
	float  RawYaw;
	float  RawPitch;
	float  RawRoll;
	float  RawX;
	float  RawY;
	float  RawZ;
	/* raw points, sorted by Y, origin top left corner */
	float  X1;
	float  Y1;
	float  X2;
	float  Y2;
	float  X3;
	float  Y3;
	float  X4;
	float  Y4;
} volatile FTData;

typedef struct FTHeap__ {
	FTData data;
	int32_t GameID;
	union
	{
		unsigned char table[8];
		int32_t table_ints[2];
	};
	int32_t GameID2;
} volatile FTHeap;

static HANDLE hFTMemMap = 0;
static FTHeap *ipc_heap = 0;
static HANDLE ipc_mutex = 0;

FTData *FreeTrack;
bool HMDConnected = false, FTThInit = false;
std::thread *pFTthread = NULL;

//FreeTrack implementation from OpenTrack (https://github.com/opentrack/opentrack/tree/unstable/freetrackclient)
static BOOL impl_create_mapping(void)
{
	if (ipc_heap != NULL)
		return TRUE;

	hFTMemMap = CreateFileMappingA(INVALID_HANDLE_VALUE,
		NULL,
		PAGE_READWRITE,
		0,
		sizeof(FTHeap),
		(LPCSTR)FREETRACK_HEAP);

	if (hFTMemMap == NULL)
		return (ipc_heap = NULL), FALSE;

	ipc_heap = (FTHeap*)MapViewOfFile(hFTMemMap, FILE_MAP_WRITE, 0, 0, sizeof(FTHeap));
	ipc_mutex = CreateMutexA(NULL, FALSE, FREETRACK_MUTEX);

	return TRUE;
}

void FTRead()
{
	while (HMDConnected) {
		if (ipc_mutex && WaitForSingleObject(ipc_mutex, 16) == WAIT_OBJECT_0) {
			memcpy(&FreeTrack, &ipc_heap, sizeof(FreeTrack));
			if (ipc_heap->data.DataID > (1 << 29))
				ipc_heap->data.DataID = 0;
			ReleaseMutex(ipc_mutex);
		}
	}
}

double YawOffset = 0, PitchOffset = 0, RollOffset = 0;

BOOL APIENTRY DllMain(HMODULE hModule, DWORD  ul_reason_for_call, LPVOID lpReserved)
{
	switch (ul_reason_for_call)
	{
	//case DLL_PROCESS_ATTACH: 
	//case DLL_THREAD_ATTACH:
	//case DLL_THREAD_DETACH:

	case DLL_PROCESS_DETACH:
		if (HMDConnected) {
			HMDConnected = false;
			if (pFTthread) {
				pFTthread->join();
				delete pFTthread;
				pFTthread = nullptr;
			}
		}
		break;
	}
	
	return true;
}

double MyOffset(float f, double f2)
{
	return fmod(f - f2, 180);
}

double RadToDeg(float r) {
	return r * (180 / 3.14159265358979323846); //180 / PI
}

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *myHMD)
{
	if (FTThInit == false) {
		FTThInit = true;
		if (impl_create_mapping() == false) {
			HMDConnected = false;
		}
		else {
			HMDConnected = true;
			pFTthread = new std::thread(FTRead);
		}
	}
	if (HMDConnected) {
		myHMD->X = FreeTrack->X * 0.001;
		myHMD->Y = FreeTrack->Y * 0.001;
		myHMD->Z = FreeTrack->Z * 0.001;
		myHMD->Yaw = MyOffset(RadToDeg(FreeTrack->Yaw), YawOffset);
		myHMD->Pitch = MyOffset(RadToDeg(FreeTrack->Pitch), PitchOffset);
		myHMD->Roll = MyOffset(RadToDeg(FreeTrack->Roll), RollOffset);

		return 1;
	}
	else {
		myHMD->X = 0;
		myHMD->Y = 0;
		myHMD->Z = 0;
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
	if (dwIndex == 0 && HMDConnected) {
		YawOffset = RadToDeg(FreeTrack->Yaw);
		PitchOffset = RadToDeg(FreeTrack->Pitch);
		RollOffset = RadToDeg(FreeTrack->Roll);
		return 1;
	}
	else {
		return 0;
	}
}