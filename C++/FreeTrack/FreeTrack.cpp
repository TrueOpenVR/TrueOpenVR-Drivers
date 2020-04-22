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
float CrouchOffset = 0;
int CrouchPressKey;
float PosZOffset = 0;

BOOL APIENTRY DllMain(HMODULE hModule, DWORD  ul_reason_for_call, LPVOID lpReserved)
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH: {
		
		CRegKey key;
		TCHAR _driversPath[MAX_PATH];
		LONG status = key.Open(HKEY_CURRENT_USER, _T("Software\\TrueOpenVR"));
		if (status == ERROR_SUCCESS)
		{
			ULONG regSize = sizeof(_driversPath);
			status = key.QueryStringValue(_T("Drivers"), _driversPath, &regSize);
		}
		key.Close();

		TCHAR configPath[MAX_PATH] = { 0 };
		_tcscat_s(configPath, sizeof(configPath), _driversPath);
		_tcscat_s(configPath, sizeof(configPath), _T("FreeTrack.ini"));

		if (status == ERROR_SUCCESS && PathFileExists(configPath)) {
			CIniReader IniFile((char *)configPath);

			CrouchPressKey = IniFile.ReadInteger("Main", "CrouchPressKey", 0);
			CrouchOffset = IniFile.ReadFloat("Main", "CrouchOffset", 0);
		}

		break;
	}
							
							
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

double RadToDeg(float r) {
	return r * (180 / 3.14159265358979323846); //180 / PI
}

DLLEXPORT DWORD __stdcall GetHMDData(__out THMD *HMD)
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

		if ((GetAsyncKeyState(CrouchPressKey) & 0x8000) != 0)
			PosZOffset = CrouchOffset;
		else
			PosZOffset = 0;

		HMD->X = FreeTrack->X * 0.001;
		HMD->Y = FreeTrack->Y * 0.001 - PosZOffset;
		HMD->Z = FreeTrack->Z * 0.001;
		HMD->Yaw = OffsetYPR(RadToDeg(FreeTrack->Yaw), YawOffset);
		HMD->Pitch = OffsetYPR(RadToDeg(FreeTrack->Pitch), PitchOffset);
		HMD->Roll = OffsetYPR(RadToDeg(FreeTrack->Roll), RollOffset);

		return TOVR_SUCCESS;
	}
	else {
		HMD->X = 0;
		HMD->Y = 0;
		HMD->Z = 0;
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