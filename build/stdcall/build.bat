@echo off
setlocal
:: call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\vcvars32.bat"
:: call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\amd64\vcvars64.bat"
set lib_name=zstdlib-x86
set cl_exe=cl.exe /nologo /DZSTD_DLL_STDCALL=1
set cl_flags=/MT /LD /O2 /Ox
set link_flags=/link /base:0x3f400000 /version:1.0 /incremental:no /opt:ref /merge:.rdata=.text /ignore:4078,4010
set src_dir=..\..\lib
set bin_dir=Release
set rc_exe=rc.exe
set rc_dir=..\..\build\VS2010\zstdlib
set sdk_dir=C:\Program Files (x86)\Windows Kits\8.1\Include
set rc_include=%src_dir%

if [%VisualStudioVersion%]==[14.0] (
    set link_flags=%link_flags% /subsystem:windows,5.1
    set rc_exe=%rc_exe% /nologo
)

if [%Platform%]==[X64] (
    set lib_name=zstdlib-x64
    set cl_exe=%cl_exe% /DZSTD_DLL_EXPORT=1
)
if exist %lib_name%.def set link_flags=%link_flags% /def:%lib_name%.def
where /q verrsrc.h || set rc_include=%rc_include%;%sdk_dir%\shared;%sdk_dir%\um

pushd %~dp0

:parse_args
if [%1]==[debug] (
    set cl_flags=/MDd /LD /Zi
    set link_flags=%link_flags% /debug
    set bin_dir=Debug
    shift /1
    goto :parse_args
)

%rc_exe% /I "%rc_include%" /Fo .\zstdlib.res %rc_dir%\zstdlib.rc
if errorlevel 1 goto :eof
%cl_exe% %cl_flags% /I "%src_dir%" /I "%src_dir%\common" /Tp "%src_dir%\common\entropy_common.c" /Tp "%src_dir%\common\xxhash.c" /Tp "%src_dir%\common\zstd_common.c" /Tp "%src_dir%\common\fse_decompress.c" /Tp "%src_dir%\compress\fse_compress.c" /Tp "%src_dir%\compress\huf_compress.c" /Tp "%src_dir%\compress\zbuff_compress.c" /Tp "%src_dir%\compress\zstd_compress.c" /Tp "%src_dir%\decompress\huf_decompress.c" /Tp "%src_dir%\decompress\zbuff_decompress.c" /Tp "%src_dir%\decompress\zstd_decompress.c" /Tp "%src_dir%\dictBuilder\divsufsort.c" /Tp "%src_dir%\dictBuilder\zdict.c" .\zstdlib.res /Fe%lib_name%.dll %link_flags%
if errorlevel 1 goto :eof

echo Copying %lib_name% to %bin_dir%...
md %bin_dir% 2> nul
copy %lib_name%.dll %bin_dir% > nul
copy %lib_name%.pdb %bin_dir% > nul

:cleanup
del /q *.exp *.lib *.obj *.dll *.pdb *.ilk *.res ~$* 2> nul

:eof
popd
