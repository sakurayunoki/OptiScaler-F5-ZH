@echo off
REM ============================================================================
REM  v0.1.39 中文版 - Windows / 云 Windows 一键编译脚本
REM  前置: Git、Python 3、Visual Studio 2022 或 Build Tools（含 MSVC + Windows SDK）
REM
REM  用法（在源码根目录或任意目录打开 cmd）:
REM    build-windows.bat <源码目录> <产物目录> [v0.1.39 官方zip路径]
REM
REM  示例:
REM    build-windows.bat C:\build\OptiScaler-F5-DLSSNR-Multipass C:\build\dist\ZH "C:\downloads\v0.1.39-Optiscaler-F5.zip"
REM
REM  不传第三个参数也能编译，只是产物里不含 F5Low 帧生成器（f5low.dll / libxess_fg.dll）。
REM ============================================================================
setlocal enabledelayedexpansion

set "SRC=%~1"
set "OUT=%~2"
set "ZIP=%~3"
if "%SRC%"=="" set "SRC=."
if "%OUT%"=="" set "OUT=dist\ZH"

echo [1/3] 重放汉化资产到源码树: %SRC%
python "%~dp0scripts\apply_patch.py" "%SRC%" --report "%SRC%\apply-report.json"
if errorlevel 1 (
  echo [错误] 汉化重放失败，请按上面的锚点报错检查 dict\structural.json
  exit /b 1
)

echo [2/3] 调用 MSBuild 编译并自检打包
if not "%ZIP%"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\build.ps1" ^
    -SourceDir "%SRC%" -OutDir "%OUT%" -AcceptNvidiaLicenses -F5LowSourceZip "%ZIP%"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\build.ps1" ^
    -SourceDir "%SRC%" -OutDir "%OUT%" -AcceptNvidiaLicenses
)
if errorlevel 1 (
  echo [错误] 编译或打包失败，见上方 MSBuild 输出
  exit /b 1
)

echo [3/3] 完成，产物目录: %OUT%
echo 把产物内全部文件解压到游戏 exe 旁；自备神经渲染模型 nvngx_dlssnr.dll。
endlocal
