#!/bin/sh

export cmake_PROJ_NAME=kaldi

#export cmake_PROCESSOR_BITS=32
export cmake_PROCESSOR_BITS=64

export cmake_BUILD_TYPE=Release
#export cmake_BUILD_TYPE=Debug

rm -rf ./!proj_${cmake_PROJ_NAME}
mkdir ./!proj_${cmake_PROJ_NAME}
cd ./!proj_${cmake_PROJ_NAME}

cmake -G"Eclipse CDT4 - Unix Makefiles" ../${cmake_PROJ_NAME} -DPROCESSOR_BITS=${cmake_PROCESSOR_BITS} -DCMAKE_BUILD_TYPE=${cmake_BUILD_TYPE}

cd ..
