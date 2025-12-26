@echo off
echo Building Firebase Release libraries...

REM Navigate to Firebase SDK directory
cd /d "C:\Users\stard\Desktop\toothfile\build\windows\x64\extracted\firebase_cpp_sdk_windows"

REM Create Release build directory
if not exist "build_release" mkdir build_release
cd build_release

REM Try to build with MSBuild (if available)
echo Attempting to build with MSBuild...
msbuild ..\CMakeLists.txt /p:Configuration=Release /p:Platform=x64 /t:firebase_app

if %errorlevel% neq 0 (
    echo MSBuild failed, trying alternative approach...
    
    REM Copy Debug libraries to Release and rename
    echo Copying Debug libraries to Release folder...
    xcopy /Y "..\libs\windows\VS2019\MD\x64\Debug\*.lib" "..\libs\windows\VS2019\MD\x64\Release\"
    
    echo Libraries copied. You may need to rebuild the project.
)

echo Done.
pause