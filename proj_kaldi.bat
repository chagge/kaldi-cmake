echo off

REM set VSVER=2010
set VSVER=2012
REM set cmake_PROCESSOR_BITS=32
set cmake_PROCESSOR_BITS=64

set cmake_DIR_PREFIX=!proj_
set cmake_TEMP_DIR=!temp_files
set cmake_PROJ_NAME=kaldi

set STCASRGENERIC_MODULE_PATH=
set STCASRGAUSSMIX_MODULE_PATH=
set STCASRACOMODELMAP_MODULE_PATH=
set STCASRPACK_MODULE_PATH=
set STCASRPHONESET_MODULE_PATH=
set STCASRSUPPORT_MODULE_PATH=
set STCASRDECODER_MODULE_PATH=
set STCASRDECTESTS_MODULE_PATH=
set STCASRRESULT_MODULE_PATH=
set STCASRACOMODELTRAIN_MODULE_PATH=
set STCASRSRLOCALWIN_MODULE_PATH=
set STCASRVAD_MODULE_PATH=
set STCASRVADPOSTPROC_MODULE_PATH=
set STCASRVADDECODER_MODULE_PATH=
set STCASRSPEECHPARAM_MODULE_PATH=
set STCASRANN_MODULE_PATH=
set STCASRCOMMON_MODULE_PATH=
set STCASRTRANSCRIPTOR_MODULE_PATH=
set STCASRGAUSSMIXCOMP_MODULE_PATH=

REM set STCASRGENERIC_MODULE_PATH=d:\Work\stc\SRGeneric
REM set STCASRGAUSSMIX_MODULE_PATH=d:\Work\stc\SRGaussMix
REM set STCASRACOMODELMAP_MODULE_PATH=d:\Work\stc\AcoModelMap
REM set STCASRPACK_MODULE_PATH=d:\Work\stc\SRPack
REM set STCASRPHONESET_MODULE_PATH=d:\Work\stc\SRPhoneSet
REM set STCASRSUPPORT_MODULE_PATH=d:\Work\stc\SRSupport
REM set STCASRDECODER_MODULE_PATH=d:\Work\stc\SRDecoder
REM set STCASRDECTESTS_MODULE_PATH=d:\Work\stc\SRDecTests
REM set STCASRRESULT_MODULE_PATH=d:\Work\stc\StcResult
REM set STCASRACOMODELTRAIN_MODULE_PATH=d:\Work\stc\AcoModelTrain
REM set STCASRSRLOCALWIN_MODULE_PATH=d:\Work\stc\SRLocalWin
REM set STCASRVAD_MODULE_PATH=d:\Work\stc\VAD_OSF
REM set STCASRVADPOSTPROC_MODULE_PATH=d:\Work\stc\VADPostProc
REM set STCASRVADDECODER_MODULE_PATH=d:\Work\stc\VADDecoder
REM set STCASRSPEECHPARAM_MODULE_PATH=d:\Work\stc\!other_proj\StcSpeechParam
REM set STCASRANN_MODULE_PATH=d:\Work\stc\!other_proj\IANN
REM set STCASRCOMMON_MODULE_PATH=d:\Work\stc\!other_proj\Common
REM set STCASRTRANSCRIPTOR_MODULE_PATH=d:\Work\stc\!other_proj\Transcriptor
REM set STCASRGAUSSMIXCOMP_MODULE_PATH=d:\Work\stc\GaussMixComp

if %VSVER% == 2010 (
	echo "Visual Studio 2010"
	set BOOST_ROOT=d:\Boost\boost_1_51_0
	if %cmake_PROCESSOR_BITS% == 64 (
		echo "64 bit mode"
		set BOOST_LIBRARYDIR=d:\Boost\boost_1_51_0\stage\lib64
		set cmake_BUILD_TYPE=Visual Studio 10 Win64
	) else (
		echo "32 bit mode"
		set BOOST_LIBRARYDIR=d:\Boost\boost_1_51_0\stage\lib
		set cmake_BUILD_TYPE=Visual Studio 10
	)
) else (
	echo "Visual Studio 2012"
	set BOOST_ROOT=d:\Boost\boost_1_51_0
	if %cmake_PROCESSOR_BITS% == 64 (
		echo "64 bit mode"
		set BOOST_LIBRARYDIR=d:\Boost\boost_1_51_0\stage_vs2012\lib64
		set cmake_BUILD_TYPE=Visual Studio 11 Win64
	) else (
		echo "32 bit mode"
		set BOOST_LIBRARYDIR=d:\Boost\boost_1_51_0\stage_vs2012\lib
		set cmake_BUILD_TYPE=Visual Studio 11
	)
)

set cmake_PROJ_DIR=%cmake_DIR_PREFIX%%cmake_PROJ_NAME%
set cmake_INI_DIR_D=%cmake_PROJ_DIR%\Debug\ini
set cmake_INI_DIR_R=%cmake_PROJ_DIR%\Release\ini
set cmake_TEMP_INI_DIR_D=%cmake_TEMP_DIR%\Debug\ini
set cmake_TEMP_INI_DIR_R=%cmake_TEMP_DIR%\Release\ini

if not exist %cmake_PROJ_DIR% (
	mkdir %cmake_PROJ_DIR%
)

if exist %cmake_TEMP_DIR% (
	rmdir /S /Q %cmake_TEMP_DIR%
)
mkdir %cmake_TEMP_DIR%

if exist %cmake_INI_DIR_D% (
	xcopy %cmake_INI_DIR_D%\*.* %cmake_TEMP_INI_DIR_D%\ /E/Y
)
if exist %cmake_INI_DIR_R% (
	xcopy %cmake_INI_DIR_R%\*.* %cmake_TEMP_INI_DIR_R%\ /E/Y
)

cd .\%cmake_PROJ_DIR%

cmake ..\%cmake_PROJ_NAME% -G"%cmake_BUILD_TYPE%" -DCMAKE_INSTALL_PREFIX=install

cd ..

if exist %cmake_TEMP_INI_DIR_D% (
	xcopy %cmake_TEMP_INI_DIR_D%\*.* %cmake_INI_DIR_D%\ /E/Y
)
if exist %cmake_TEMP_INI_DIR_R% (
	xcopy %cmake_TEMP_INI_DIR_R%\*.* %cmake_INI_DIR_R%\ /E/Y
)

PAUSE
