@echo off
rem Builds every demo with Delphi's dcc64 into bin\ and (with "run") runs it. Usage: build.cmd [run] [Demo ...]
setlocal enabledelayedexpansion
set DCC="C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc64.exe"
set LIBS=C:\Program Files (x86)\Embarcadero\Studio\37.0\lib\win64\release
set HERE=%~dp0
set RUN=0
if /i "%~1"=="run" (
  set RUN=1
  shift
)
set LIST=%1 %2 %3 %4 %5 %6 %7 %8 %9
if "%~1"=="" set LIST=LinqDemo\LinqDemo CollectionsLinqDemo\InventoryQueries CollectionsLinqDemo\LazyQueries CollectionsLinqDemo\OrdersPipeline CollectionsLinqDemo\SetAnalytics AdvancedLinqDemo\AggregateReport AdvancedLinqDemo\SelectManyGroups AdvancedLinqDemo\ToDictionaryIndex AdvancedLinqDemo\ZipColumns
if not exist "%HERE%bin" mkdir "%HERE%bin"
if not exist "%HERE%bin\dcu" mkdir "%HERE%bin\dcu"
for %%D in (%LIST%) do (
  echo == %%D
  %DCC% -B -Q -NSSystem;Winapi -U"%LIBS%" -NU"%HERE%bin\dcu" -E"%HERE%bin" "%HERE%%%D.dpr" || exit /b 1
  if "%RUN%"=="1" "%HERE%bin\%%~nD.exe" < nul
)
