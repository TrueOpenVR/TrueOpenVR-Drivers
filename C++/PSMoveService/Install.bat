@echo Off

If Exist "%WINDIR%\SysWOW64" (
   copy lib\x64\release\PSMoveClient_CAPI.dll %WINDIR%\System32
   copy lib\x86\release\PSMoveClient_CAPI.dll %WINDIR%\SysWOW64
) Else (
   copy lib\x86\release\PSMoveClient_CAPI.dll %WINDIR%\System32
)
echo Installed
pause