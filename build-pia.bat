@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd %~dp0

set OPENVPN_SOURCE=git
set OPENVPN_BRANCH=v2.4.7
set RELEASE=Release
set TOOLSET=v141
set SDKVERSION=10.0.17763.0
set OPENSSL_VERSION=1.1.1d
set LZO_VERSION=2.10

set CPPFLAGS_32=%CPPFLAGS%;-D"_USE_32BIT_TIME_T"
set CPPFLAGS_64=%CPPFLAGS%
rem These paths are relative to the .\build.tmp\openvpn-build\msvc directory
set OUT_32=..\..\..\out\artifacts\x86
set OUT_64=..\..\..\out\artifacts\x86_64

rem Set OpenSSL configuration directory.  This has to be set at compile time,
rem since Qt always forces OpenSSL to load a configuration file, and there's no
rem reliable way to override OPENSSL_DIR in the daemon process before OpenSSL
rem is loaded.
rem
rem This must be a non-user-writeable location, since it can be used to load
rem arbitrary DLLs into the daemon process.
rem
rem This isn't perfect since we can't guarantee that the user's Windows
rem installation is actually on the C: drive.  However, there's no way to set
rem it at runtime, and it must be an absolute path.
rem
rem This path can't end with '\', because that'd be interpreted as escaping the
rem final quotation mark somewhere in the OpenSSL build
set OPENSSL_DIR=C:\Program Files\Private Internet Access

rem Add perl to PATH locally if it's installed but not in PATH
perl -e "exit 0" > nul 2>&1
if not errorlevel 1 (
    echo Found Perl in PATH
) else (
    if exist C:\Perl64\bin\perl.exe (
        echo Found Perl installation
        PATH=!PATH!;C:\Perl64\bin\
    ) else (
        echo Perl is required: https://www.activestate.com/products/activeperl/downloads/
        echo Or check: https://downloads.activestate.com/ActivePerl/releases/
        set PREREQ_ERROR=1
    )
)

rem Find 7-zip
set "P7Z=%PROGRAMFILES%\7-Zip\7z.exe"
if exist "%P7Z%" (
    echo Found 7-Zip installation
) else (
    echo Error: 7-Zip not found ^(install from https://7-zip.org/^)
    set PREREQ_ERROR=1
)

rem Find NASM (needed for 32-bit builds only)
rem For 64-bit only, you can comment this out
nasm -v > nul 2>&1
if not errorlevel 1 (
    echo Found NASM in PATH
) else (
    if exist "C:\Program Files\NASM\nasm.exe" (
        echo Found NASM installation
        PATH=!PATH!;C:\Program Files\NASM\
    ) else (
        echo Error: NASM not found ^(install from https://www.nasm.us/^)
        echo ^(choose the version matching the host architecture^)
        set PREREQ_ERROR=1
    )
)

if "%PREREQ_ERROR%"=="1" (
    echo Install prerequisites and try again
    goto error
)

rem Make sure repos are clean, since uncommitted changes would be ignored by
rem the clone below
git -C .\openvpn-build\ diff-index --quiet HEAD --
if not errorlevel 0 (
    echo openvpn-build submodule is not clean, commit or revert changes before building
    goto error
)
git -C .\openvpn\ diff-index --quiet HEAD --
if not errorlevel 0 (
    echo openvpn submodule is not clean, commit or revert changes before building
    goto error
)

rem Clone repos and apply patches.  (Do this to a clone so we don't mess with
rem WIP changes in the working tree)
rmdir /Q /S .\build.tmp
mkdir .\build.tmp\
git clone .\openvpn-build\ .\build.tmp\openvpn-build
git clone .\openvpn\ .\build.tmp\openvpn
for %%i in (.\patch-openvpn-build-windows\*.patch) do (
    git -C .\build.tmp\openvpn-build\ am < %%i
)
for %%i in (.\patch-openvpn\*.patch) do (
    git -C .\build.tmp\openvpn\ am < %%i
)
rem Create a branch here since we have to tell openvpn-build to check out a
rem specific branch (set in build-env-local.bat)
git -C .\build.tmp\openvpn\ checkout -B pia-openvpn-build

rem Copy in build-env-local.bat
copy /Y .\build-env-local.bat .\build.tmp\openvpn-build\msvc

rem Copy in source archives instead of downloading them
mkdir .\build.tmp\openvpn-build\msvc\sources
copy /Y .\source-archives\* .\build.tmp\openvpn-build\msvc\sources
copy /Y .\source-archives-windows\* .\build.tmp\openvpn-build\msvc\sources

rmdir /Q /S .\out > nul 2>&1
if not exist .\out\artifacts mkdir .\out\artifacts

rem Move to openvpn-build to run build.bat
pushd .\build.tmp\openvpn-build\msvc

for %%G in (32 64) do (
    set BITS=%%G
    set CPPFLAGS=!CPPFLAGS_%%G!
    echo.
    echo * Building !BITS!-bit OpenVPN binaries...
    echo.
    call build.bat
    if !errorlevel! neq 0 goto error
    mkdir !OUT_%%G!
    xcopy image\bin "!OUT_%%G!" /Q /E /I /Y
    del /F "!OUT_%%G!\openssl.exe" "!OUT_%%G!\openvpnserv.exe"
    rename "!OUT_%%G!\openvpn.exe" "pia-openvpn.exe"
)

echo.
dir "%OUT_32%" "%OUT_64%"
echo.
echo Build successful.

popd

set rc=0
goto end
:error
set rc=1
:end
endlocal
popd
exit /b %rc%
