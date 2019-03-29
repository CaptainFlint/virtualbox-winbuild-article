@echo off

set WORKING_DIR=%~dp0
set WORKING_DIR_NIX=%WORKING_DIR:\=/%
cd /d %WORKING_DIR%
if ERRORLEVEL 1 exit /b 1

for /f "tokens=3" %%i in ('findstr /B /R /C:"VBOX_VERSION_MAJOR *=" Version.kmk') do SET VBOX_VER_MJ=%%i
for /f "tokens=3" %%i in ('findstr /B /R /C:"VBOX_VERSION_MINOR *=" Version.kmk') do SET VBOX_VER_MN=%%i
for /f "tokens=3" %%i in ('findstr /B /R /C:"VBOX_VERSION_BUILD *=" Version.kmk') do SET VBOX_VER_BLD=%%i
for /f "tokens=6" %%i in ('findstr /C:"$Rev: " Config.kmk') do SET VBOX_REV=%%i

rem Hardcode for when there are several local configs include the same common part
if exist LocalConfig-common.kmk for /f "tokens=3" %%i in ('findstr /B /C:"VBOX_BUILD_PUBLISHER :=" LocalConfig-common.kmk') do SET VBOX_VER_PUB=%%i
for /f "tokens=3" %%i in ('findstr /B /C:"VBOX_BUILD_PUBLISHER :=" LocalConfig.kmk') do SET VBOX_VER_PUB=%%i

SET WIN10_MS_SIGN=0
if exist LocalConfig-common.kmk for /f "tokens=3" %%i in ('findstr /B /C:"WIN10_MS_SIGN :=" LocalConfig-common.kmk') do SET WIN10_MS_SIGN=%%i
for /f "tokens=3" %%i in ('findstr /B /C:"WIN10_MS_SIGN :=" LocalConfig.kmk') do SET WIN10_MS_SIGN=%%i

if exist LocalConfig-common.kmk for /f "tokens=3" %%i in ('findstr /B /C:"VBOX_PATH_SIGN_TOOLS :=" LocalConfig-common.kmk') do SET VBOX_PATH_SIGN_TOOLS=%%i
for /f "tokens=3" %%i in ('findstr /B /C:"VBOX_PATH_SIGN_TOOLS :=" LocalConfig.kmk') do SET VBOX_PATH_SIGN_TOOLS=%%i

set VERSION=%VBOX_VER_MJ%.%VBOX_VER_MN%.%VBOX_VER_BLD%%VBOX_VER_PUB%-r%VBOX_REV%
set VERSION_CAB=%VBOX_VER_MJ%.%VBOX_VER_MN%.%VBOX_VER_BLD%%VBOX_VER_PUB%r%VBOX_REV%
set VBOX_VER_MJ=
set VBOX_VER_MN=
set VBOX_VER_BLD=
set VBOX_VER_PUB=

del /q build-tmp.cmd 2>nul

echo @echo off>> build-tmp.cmd
echo call "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv.Cmd" /Release /x64 /win7>> build-tmp.cmd
echo color 07>> build-tmp.cmd
echo echo.>> build-tmp.cmd
echo echo ### %VERSION%: BUILDING x64 VERSION ###>> build-tmp.cmd
echo echo.>> build-tmp.cmd
echo set BUILD_TARGET_ARCH=amd64>> build-tmp.cmd
echo cscript configure.vbs --with-DDK=C:\WinDDK\7600.16385.1 --with-MinGW-w64=C:\Programs\mingw64 --with-MinGW32=C:\Programs\mingw32 --with-libSDL=C:\Programs\SDL\x64 --with-openssl=C:\Programs\OpenSSL\x64 --with-openssl32=C:\Programs\OpenSSL\x32 --with-libcurl=C:\Programs\curl\x64 --with-libcurl32=C:\Programs\curl\x32 --with-Qt5=C:\Programs\Qt\5.6.3-x64 --with-libvpx=C:\Programs\libvpx --with-libopus=C:\Programs\libopus --with-python=C:/Programs/Python>> build-tmp.cmd
echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd
echo call env.bat>> build-tmp.cmd
echo kmk>> build-tmp.cmd
echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd
if NOT ".%WIN10_MS_SIGN%" == ".0" (
	echo echo ### Signing 64-bit drivers for Windows 10>> build-tmp.cmd
	echo cd %WORKING_DIR%out\win.amd64\release\repack>> build-tmp.cmd
	echo call PackDriversForSubmission.cmd -x>> build-tmp.cmd
	echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd
	echo set KBUILD_DEVTOOLS=%WORKING_DIR%tools>> build-tmp.cmd
	echo set KBUILD_BIN_PATH=%WORKING_DIR%kBuild\bin\win.amd64>> build-tmp.cmd
	echo set _MY_SIGNTOOL=%VBOX_PATH_SIGN_TOOLS%\signtool.exe>> build-tmp.cmd
	echo set SRC_FILE=VBoxDrivers-%VERSION_CAB%-amd64.cab>> build-tmp.cmd
	echo set DST_FILE=VBoxDrivers-%VERSION_CAB%-amd64-mssigned.zip>> build-tmp.cmd
	echo call sign-dual.cmd %%SRC_FILE%%>> build-tmp.cmd
	echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd
	echo python %WORKING_DIR%sign_ms.py %%SRC_FILE%% %%DST_FILE%%>> build-tmp.cmd
	echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd
	echo call UnpackBlessedDrivers.cmd -n -i %%DST_FILE%%>> build-tmp.cmd
	echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd
	echo set KBUILD_DEVTOOLS=>> build-tmp.cmd
	echo set KBUILD_BIN_PATH=>> build-tmp.cmd
	echo set _MY_SIGNTOOL=>> build-tmp.cmd
	echo set SRC_FILE=>> build-tmp.cmd
	echo set DST_FILE=>> build-tmp.cmd
	echo cd %WORKING_DIR%>> build-tmp.cmd
)
echo echo ### Building the 64-bit MSI>> build-tmp.cmd
echo kmk %WORKING_DIR_NIX%out/win.x86/release/obj/Installer/VirtualBox-%VERSION%-MultiArch_amd64.msi>> build-tmp.cmd
echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd

cmd /c build-tmp.cmd
if ERRORLEVEL 1 exit /b 1

del /q build-tmp.cmd 2>nul

echo @echo off>> build-tmp.cmd
echo call "C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\SetEnv.Cmd" /Release /x86 /win7>> build-tmp.cmd
echo color 07>> build-tmp.cmd
echo echo.>> build-tmp.cmd
echo echo ### %VERSION%: BUILDING x32 VERSION ###>> build-tmp.cmd
echo echo.>> build-tmp.cmd
echo set BUILD_TARGET_ARCH=x86>> build-tmp.cmd
echo cscript configure.vbs --with-DDK=C:\WinDDK\7600.16385.1 --with-MinGW-w64=C:\Programs\mingw64 --with-MinGW32=C:\Programs\mingw32 --with-libSDL=C:\Programs\SDL\x32 --with-openssl=C:\Programs\OpenSSL\x32 --with-libcurl=C:\Programs\curl\x32 --with-Qt5=C:\Programs\Qt\5.6.3-x32 --with-libvpx=C:\Programs\libvpx --with-libopus=C:\Programs\libopus --with-python=C:/Programs/Python>> build-tmp.cmd
echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd
echo call env.bat>> build-tmp.cmd
echo kmk>> build-tmp.cmd
echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd
if NOT ".%WIN10_MS_SIGN%" == ".0" (
	echo echo ### Signing 32-bit drivers for Windows 10>> build-tmp.cmd
	echo cd %WORKING_DIR%out\win.x86\release\repack>> build-tmp.cmd
	echo call PackDriversForSubmission.cmd -x>> build-tmp.cmd
	echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd
	echo set KBUILD_DEVTOOLS=%WORKING_DIR%tools>> build-tmp.cmd
	echo set KBUILD_BIN_PATH=%WORKING_DIR%kBuild\bin\win.x86>> build-tmp.cmd
	echo set _MY_SIGNTOOL=%VBOX_PATH_SIGN_TOOLS%\signtool.exe>> build-tmp.cmd
	echo set SRC_FILE=VBoxDrivers-%VERSION_CAB%-x86.cab>> build-tmp.cmd
	echo set DST_FILE=VBoxDrivers-%VERSION_CAB%-x86-mssigned.zip>> build-tmp.cmd
	echo call sign-dual.cmd %%SRC_FILE%%>> build-tmp.cmd
	echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd
	echo python %WORKING_DIR%sign_ms.py %%SRC_FILE%% %%DST_FILE%%>> build-tmp.cmd
	echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd
	echo call UnpackBlessedDrivers.cmd -n -i %%DST_FILE%%>> build-tmp.cmd
	echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd
	echo set KBUILD_DEVTOOLS=>> build-tmp.cmd
	echo set KBUILD_BIN_PATH=>> build-tmp.cmd
	echo set _MY_SIGNTOOL=>> build-tmp.cmd
	echo set SRC_FILE=>> build-tmp.cmd
	echo set DST_FILE=>> build-tmp.cmd
	echo cd %WORKING_DIR%>> build-tmp.cmd
)
echo echo ### Building the full installer>> build-tmp.cmd
echo kmk %WORKING_DIR_NIX%out/win.x86/release/bin/VirtualBox-%VERSION%-MultiArch.exe>> build-tmp.cmd
echo if ERRORLEVEL 1 exit /b ^1>> build-tmp.cmd

cmd /c build-tmp.cmd
if ERRORLEVEL 1 exit /b 1

del /q build-tmp.cmd AutoConfig.kmk configure.log env.bat 2>nul

echo.
echo ### BUILD COMPLETE ###
echo.
