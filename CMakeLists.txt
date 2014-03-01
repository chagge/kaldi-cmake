cmake_minimum_required (VERSION 2.8)

if (DEFINED ENV{kaldi_INCLUDED})
    return()
endif()
set (ENV{kaldi_INCLUDED} 1)

project (kaldi)
include (cmake/CMakeInit.cmake)

#####################
### Find packages ###
#####################

#set_property(GLOBAL PROPERTY FIND_LIBRARY_USE_LIB64_PATHS ON)

#set(OPENFSTLIBS "/home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/lib")
set(FSTROOT "/home/yuri/work/install/kaldi-trunk-gpu/tools/openfst")
set(FSTINC "/home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/include")
set(ATLASINC "/home/yuri/work/install/kaldi-trunk-gpu/tools/ATLAS/include")

set(OPENFSTLIBS
  /home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/lib/libfst.so
  /home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/lib/fst/libfstfar.so
  /home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/lib/fst/libfstfarscript.so
  /home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/lib/fst/libfstngram.so
  /home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/lib/fst/ngram-fst.so
)
set(ATLASLIBS
  /usr/lib/atlas-base/libatlas.so.3.0
  /usr/lib/atlas-base/libf77blas.so.3.0
  /usr/lib/atlas-base/libcblas.so.3
  /usr/lib/atlas-base/liblapack_atlas.so.3
)

add_definitions(-DKALDI_DOUBLEPRECISION=0)
add_definitions(-DHAVE_POSIX_MEMALIGN)
add_definitions(-DHAVE_EXECINFO_H=1)
add_definitions(-DHAVE_CXXABI_H)
add_definitions(-DHAVE_ATLAS)

#####################
### Add externals ###
#####################

include_directories(${FSTINC})
include_directories(${ATLASINC})

#include_directories("externals/WaveReader")

#add_module(StcAsrAcoModelMap)

#if (NOT UNIX)
#    add_module(sndfile ${PROJECT_SOURCE_DIR}/externals/sndfile)
#endif()

#if(MSVC)
#	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")
#endif()

###################
### Compilation ###
###################

#add_library(StcAsrAMTrainLib STATIC ${SRC_AMTRAIN_LIB} ${HEADER_AMTRAIN_LIB} ${SRC_WAVEREADER})
#set_default_library_target_properties(StcAsrAMTrainLib)
#import_shared_library(StcAsrAMTrainLib StcAsrAcoModelMap)
#import_static_library(StcAsrAMTrainLib StcAsrDecoderLib)
#target_link_libraries(StcAsrAMTrainLib ${log4cxx_LIBRARIES} ${Boost_LIBRARIES})
#add_target_compile_definitions(StcAsrAMTrainLib LOGGER_NAME=L"STC.ASR.AMTRAIN")

#add_library(StcAsrAMTrain SHARED ${SRC_AMTRAIN} ${HEADER_AMTRAIN} ${SRC_WAVEREADER} ${VERSION_RC_FILE})
#set_default_library_target_properties(StcAsrAMTrain)
#import_shared_library(StcAsrAMTrain StcAsrAcoModelMap)
#import_static_library(StcAsrAMTrain StcAsrAMTrainLib)
#target_link_libraries(StcAsrAMTrain ${log4cxx_LIBRARIES} ${Boost_LIBRARIES})
#if (UNIX)
#	target_link_libraries(StcAsrAMTrain sndfile)
#else()
#	target_link_libraries(StcAsrAMTrain libsndfile-1)
#endif()
#add_target_compile_definitions(StcAsrAMTrain LOGGER_NAME=L"STC.ASR.AMTRAIN")

#
# Проект StcAsrArtModelTrainEx
#
#add_executable(StcAsrArtModelTrainEx src/ArtModelTrainEx.cpp ${VERSION_RC_FILE})
#set_default_executable_target_properties(StcAsrArtModelTrainEx)
#import_shared_library(StcAsrArtModelTrainEx StcAsrContainer)
#import_static_library(StcAsrArtModelTrainEx StcAsrGeneric)
#target_link_libraries(StcAsrArtModelTrainEx ${log4cxx_LIBRARIES} ${Boost_LIBRARIES})
#add_target_compile_definitions(StcAsrArtModelTrainEx LOGGER_NAME=L"STC.ASR.ARTMODTRAIN")
#add_target_compile_definitions(StcAsrArtModelTrainEx PRODUCT_FULL_VERSION=L"${${PROJECT_NAME}_VERSION_FULL}")
