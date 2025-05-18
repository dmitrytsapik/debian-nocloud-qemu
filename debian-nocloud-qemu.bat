@echo off
setlocal enabledelayedexpansion
cls
echo ------------------------------- Welcome^^! ------------------------------
echo ^|  This script will help you run the 'Debian NoCloud Image' on QEMU^^!  ^|
echo ^|   Press 'CTRL+C' to stop the script, or press any key to continue.  ^|
echo -----------------------------------------------------------------------
echo Copyright (c) 2025 Dmitry Tsapik (https://tsapik.xyz)
echo=
echo Permission is hereby granted, free of charge, to any person obtaining a
echo copy of this software and associated documentation files
echo (the "Software"), to deal in the Software without restriction,
echo including without limitation the rights to use, copy, modify, merge,
echo publish, distribute, sublicense, and/or sell copies of the Software,
echo and to permit persons to whom the Software is furnished to do so,
echo subject to the following conditions:
echo=
echo The above copyright notice and this permission notice shall be included
echo in all copies or substantial portions of the Software.
echo=
echo THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
echo OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
echo MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
echo IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
echo CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
echo TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
echo SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
echo -----------------------------------------------------------------------
pause
:start
cls
where qemu-system-x86_64 >nul 2>nul
if %errorlevel%==0 goto skip_path_alert
REM setx PATH "%PATH%;C:\Program Files\QEMU"
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo ~~~~~~~~~~~~~~~~~~~~~~~~ QEMU not found in PATH^^! ~~~~~~~~~~~~~~~~~~~~~~~
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo ------------------------- How to install QEMU? -------------------------
echo ------------------------------------------------------------------------
echo ^| 1. Download QEMU from https://qemu.weilnetz.de/                      ^|
echo ^| 2. Launch the QEMU installer.                                        ^|
echo ^|  a. In the 'Choose Components' step, under the 'System Emulation'    ^|
echo ^|     group, select 'x86_64' and 'x86_64w'.                            ^|
echo ^|  b. Remember the destination folder in the 'Choose Install Location' ^|
echo ^|     step.                                                            ^|
echo ^| 2. Add the QEMU installation directory to the system PATH.           ^|
echo ^|  a. Press Win + X and select System.                                 ^|
echo ^|  b. In the System Properties window, click Environment Variables.    ^|
echo ^|  c. Under System Variables, find and select Path, then click Edit.   ^|
echo ^|  d. Click New, then enter the QEMU installation directory            ^|
echo ^| (e.g., C:\Program Files\QEMU).                                       ^|
echo ^|  e. Click OK to save changes.                                        ^|
echo ^|  f. Restart your computer for the changes to apply.                  ^|
echo ------------------------------------------------------------------------
pause
:skip_path_alert
for /f %%f in (
        'dir /b ^| findstr /m debian-.*-nocloud-amd64.qcow2'
) do set image=%%f
if defined image goto show_image_name
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo ~~~~~~~~~~~~~~~~~~~~~~~~ Disk image not found^^! ~~~~~~~~~~~~~~~~~~~~~~~
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo ---------- Do you want to download the QCOW2 nocloud image? ----------
echo ^|                   Debian Official Cloud Images                     ^|
echo ^|             https://cdimage.debian.org/images/cloud/               ^|
echo ----------------------------------------------------------------------
echo Type the codename and digital code of the Debian release
echo ^(e.g., 'bookworm 12' or 'bookworm-backports 12'^)
echo By default, it's 'bookworm 12'. Press 'CTRL+C' to stop the script
set /p codename=:
if not defined codename set codename=bookworm 12
for /f "tokens=1,2 delims= " %%a in ("!codename!") do (
        set url=https://cdimage.debian.org/images/cloud/%%a/latest/^
debian-%%b-nocloud-amd64.qcow2
)
echo --------------------------- Download link: ---------------------------
echo ^|!url!^|
echo ^|   Press 'CTRL+C' to stop the script, or press any key to continue. ^|
echo ----------------------------------------------------------------------
pause
for %%a in (!url!) do set filename=%%~nxa
bitsadmin /cancel "Downloading !codename! Image"
bitsadmin /transfer "Downloading !codename! Image" !url! "%cd%\!filename!"
if exist "%cd%\!filename!" (
        echo Image: !filename!
        for %%A in ("%cd%!filename!") do set fileSize=%%~zA
        echo Image size: !fileSize! bytes
) else (
        echo Error. No image was found.
        pause
        exit /b
)
pause
goto start
:show_image_name
echo ----------------------------------------------------------------------
echo ------------ Disk image is: %image% ------------
echo ----------------------------------------------------------------------
echo ---------- Do you want to resize the QCOW2 nocloud image? ------------
echo ----------------------------------------------------------------------
echo Enter the value of MB to add to the QCOW2 image. Enter 0 or anything 
echo else to cancel the addition.
set /p size=":"
set /a extra_mb=size 2>nul
if %extra_mb% gtr 0 (
        @echo on
        qemu-img resize %image% +%extra_mb%M
        @echo off
) else (
        echo Resizing canceled.
)
echo --------------- Checking WHPX acceleration support ... ---------------
echo Press 'CTRL+C' to stop the script ...
systeminfo | find "Hyper-V Requirements" >nul
goto accel%errorlevel%
:accel1
echo !!! Not Supported or Not Found. !!!
echo -------------------------------- NOTE!!! -------------------------------
echo !!! Follow these steps to enable WHPX ^(Windows Hypervisor Platform^) !!!
echo ------------------------------------------------------------------------
echo ^| 1. Check your CPU for virtualization support.                        ^|
echo ^|  a. Open 'Task Manager' by pressing Ctrl+Shift+Esc, then switch to   ^|
echo ^|      the 'Performance' tab.                                          ^|
echo ^|  b. Check if the virtualization is enabled (in the 'CPU' section,    ^|
echo ^|      the parameter 'Virtualization' must be enabled^)^.              ^|
echo ^|  c. If virtualization is disabled, turn it on in the BIOS/UEFI:      ^|
echo ^|     for Intel CPUs, enable Intel VT-x;                               ^|
echo ^|     for AMD CPUs, enable 'SVM Mode'.                                 ^|
echo ^| 2. Turn on WHPX in Windows components:                               ^|
echo ^|  a. Press Windows + R, type 'optionalfeatures', and press Enter.     ^|
echo ^|  b. In the list of components, find 'Windows Hypervisor Platform'    ^|
echo ^|     and check the box.                                               ^|
echo ^|  c. Click OK and restart the PC.                                     ^|
echo ------------------------------------------------------------------------
goto accel_define
:accel0
REM systeminfo | find "Hyper-V Requirements"
echo A hypervisor has been detected.
set /p accel_check=Type 'y' and press 'Enter' to enable WHPX acceleration: 
if /i "%accel_check%"=="y" (
        set accel=-accel whpx
)
:accel_define
if "!accel!"=="-accel whpx" (
        echo -------------- WHPX acceleration has been enabled^^! --------------
)
set host_fwd=hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80
echo -------------- Port Forwarding Rules for TCP Protocol ----------------
echo ^|   This script will help you run the 'Debian Cloud Image' on QEMU^^!  ^|
echo ^| Default settings are '%host_fwd%' ^|
echo ----------------------------------------------------------------------
set /p fwd=To use the default settings, press Enter, or type 'y' to customize: 
if /i "%fwd%"=="y" (
        set host_fwd=
        :next_port
        set /p port_host=Enter host port ^(or type 'exit' to finish^): 
        if /i "!port_host!"=="exit" goto end_forwarding
        set /p port_guest=Enter guest port: 
        if not defined host_fwd (
                set host_fwd=hostfwd=tcp::!port_host!-:!port_guest!
        ) else (
                set host_fwd=!host_fwd!,hostfwd=tcp::!port_host!-:!port_guest!
        )
        echo Current: !host_fwd!
        goto next_port
        :end_forwarding
        pause
)
:cpu_input
set /p cpu_cores="Enter the number of CPU cores: "
set /a test=cpu_cores 2>nul
if %test% LEQ 0 (
        echo Error: Please enter an integer greater than 0.
        goto cpu_input
)
:ram_input
set /p ram_size="Enter the amount of RAM (in GB): "
set /a test=ram_size 2>nul
if %test% LEQ 0 (
        echo Error: Please enter an integer greater than 0.
        goto ram_input
)
echo Type a BATCH filename and press ENTER to save parameters for running
echo QEMU in a file (e.g., run.bat), or press ENTER without typing anything
echo to start QEMU immediately.
set /p batch_filename=Filename:
set launch_params=qemu-system-x86_64 -smp %cpu_cores% -m %ram_size%G ^
-hda %image% %accel% -nic user,%host_fwd%
if not defined batch_filename (
        call %launch_params%
        exit
)
(
        echo qemu-system-x86_64^^
        echo         -name "Debian"^^
        echo         -smp %cpu_cores%^^
        echo         -m %ram_size%G^^
        echo         -hda %image%^^
        echo         %accel%^^
        echo         -nic user,%host_fwd%
) > "%batch_filename%"