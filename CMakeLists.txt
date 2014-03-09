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

if (UNIX)
	#set(OPENFSTLIBS "/home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/lib")
	set(FSTROOT "/home/yuri/work/install/kaldi-trunk-gpu/tools/openfst")
	set(FSTINC "/home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/include")
	set(ATLASINC "/home/yuri/work/install/kaldi-trunk-gpu/tools/ATLAS/include")
else()
	# set(FSTINC "d:/Work/OpenFst/openfstwin-1.3.1/src/include")
endif()

if (UNIX)
	set(OPENFSTLIBS
	  /home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/lib/libfst.so
	  /home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/lib/fst/libfstfar.so
	  /home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/lib/fst/libfstfarscript.so
	  /home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/lib/fst/libfstngram.so
	  /home/yuri/work/install/kaldi-trunk-gpu/tools/openfst/lib/fst/ngram-fst.so
	)
else()
endif()

if (UNIX)
	set(ATLASLIBS
	  /usr/lib/atlas-base/libatlas.so.3.0
	  /usr/lib/atlas-base/libf77blas.so.3.0
	  /usr/lib/atlas-base/libcblas.so.3
	  /usr/lib/atlas-base/liblapack_atlas.so.3
	)
endif()

if (WINDOWS)
	set(Boost_USE_STATIC_LIBS   ON)
else()
	add_definitions(-DBOOST_TEST_DYN_LINK)
	add_definitions(-DBOOST_TEST_MAIN)
endif()
find_package(Boost 1.51 REQUIRED COMPONENTS system filesystem thread date_time regex unit_test_framework chrono program_options)
if(Boost_FOUND)
	include_directories(${Boost_INCLUDE_DIRS})
endif()
add_definitions(-DBOOST_ALL_NO_LIB)
add_definitions(-DBOOST_FILESYSTEM_VERSION=3)

if (WINDOWS)
	find_package(MKLM_11)
	if(MKL_FOUND)
		message("-- MKL_INCLUDE_DIRS: ${MKL_INCLUDE_DIRS}")
		message("-- MKL_LIBRARIES: ${MKL_LIBRARIES}")
		include_directories("${MKL_INCLUDE_DIRS}")
	endif()
endif()

if (UNIX)
	include_directories(${FSTINC})
	include_directories(${ATLASINC})
else()
	# include_directories(${FSTINC})
endif()

add_definitions(-DKALDI_DOUBLEPRECISION=0)
if (UNIX)
	add_definitions(-DHAVE_POSIX_MEMALIGN)
	add_definitions(-DHAVE_EXECINFO_H=1)
	add_definitions(-DHAVE_CXXABI_H)
	add_definitions(-DHAVE_ATLAS)
else()
	add_definitions(-DHAVE_MKL)
endif()

if(msvc)
	set(cmake_cxx_flags "${cmake_cxx_flags} /mp")
endif()

if (WINDOWS)
	set_property(GLOBAL PROPERTY FIND_LIBRARY_USE_LIB64_PATHS ON)
endif()

#####################
### Add externals ###
#####################

#add_module(StcAsrAcoModelMap)

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
