#!/bin/sh

export cmake_PROJ_NAME=kaldi

#export cmake_PROCESSOR_BITS=32
export cmake_PROCESSOR_BITS=64

export cmake_BUILD_TYPE=Release
#export cmake_BUILD_TYPE=Debug

#export STCASRGENERIC_MODULE_PATH=/media/work/proj/SRGeneric
#export STCASRCONTAINER_MODULE_PATH=/media/work/proj/SRContainer
#export STCASRGAUSSMIX_MODULE_PATH=/media/work/proj/SRGaussMix
#export STCASRACOMODELMAP_MODULE_PATH=/media/work/proj/AcoModelMap
#export STCASRPACK_MODULE_PATH=/media/work/proj/SRPack
#export STCASRPHONESET_MODULE_PATH=/media/work/proj/SRPhoneSet
#export STCASRSUPPORT_MODULE_PATH=/media/work/proj/SRSupport
#export STCASRDECODER_MODULE_PATH=/media/work/proj/SRDecoder
#export STCASRDECTESTS_MODULE_PATH=/media/work/proj/SRDecTests
#export STCASRRESULT_MODULE_PATH=/media/work/proj/StcResult

echo "cmake_PROCESSOR_BITS = $cmake_PROCESSOR_BITS"

if [ $cmake_PROCESSOR_BITS -eq 64 ]; then
	echo "64 bit mode"
	export BOOST_ROOT=/home/vm/install/boost_1_55_0
	export BOOST_LIBRARYDIR64=/home/vm/install/boost_1_55_0/stage/lib64
else
	echo "32 bit mode"
	export BOOST_ROOT=/home/yuri/boost_1_53_0
	echo "ERROR"
	exit 1
fi

export proj_dir="./!proj_${cmake_PROJ_NAME}"
if [ ! -d "$proj_dir" ]; then
    mkdir "$proj_dir"
fi
cd "$proj_dir"

#cmake -G"Eclipse CDT4 - Unix Makefiles" ../SRPhoneSet -DPROCESSOR_BITS=64
#cmake -G"Eclipse CDT4 - Unix Makefiles" ../SRPhoneSet -DPROCESSOR_BITS=64 -DCMAKE_BUILD_TYPE=Debug

cmake -G"Eclipse CDT4 - Unix Makefiles" ../${cmake_PROJ_NAME} -DPROCESSOR_BITS=${cmake_PROCESSOR_BITS} -DCMAKE_BUILD_TYPE=${cmake_BUILD_TYPE}

cd ..
