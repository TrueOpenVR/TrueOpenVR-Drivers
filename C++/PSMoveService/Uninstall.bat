@echo Off

If Exist "%WINDIR%\SysWOW64" (
   del %WINDIR%\System32\PSMoveClient_CAPI.dll
   del %WINDIR%\SysWOW64\PSMoveClient_CAPI.dll
) Else (
   del %WINDIR%\System32\PSMoveClient_CAPI.dll
)
echo Uninstalled
pause