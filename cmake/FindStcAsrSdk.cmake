# Модуль для поиска установленного в системе ASR SDK.
# Пример использования
#=====================
#
#find_package(StcAsrSdk)
#if(STC_ASR_SDK_FOUND)
#	message("-- STC_ASR_SDK_INCLUDE_DIRS: ${STC_ASR_SDK_INCLUDE_DIRS}")
#	message("-- STC_ASR_SDK_LIBRARY_DIRS: ${STC_ASR_SDK_LIBRARY_DIRS}")
#	message("-- STC_ASR_SDK_LIBRARIES: ${STC_ASR_SDK_LIBRARIES}")
#	message("-- STC_ASR_SDK_BINS: ${STC_ASR_SDK_BINS}")
#else()
#    message("-- StcAsrSdk not found!")
#endif()
#
# Если ASR SDK будет найден, то переменная
# STC_ASR_SDK_FOUND == 1
# STC_ASR_SDK_INCLUDE_DIRS == маршрут к файлам заголовка.
# STC_ASR_SDK_LIBRARY_DIRS == маршрут к интерфейсным библиотекам
# STC_ASR_SDK_LIBRARIES == полный маршрут к библиотеке StcAsrSdk.lib, включающий имя файла.
# STC_ASR_SDK_BINS == полный маршрут к библиотеке StcAsrSdk.dll, включающий имя файла.
#
# При поиске модуль использует переменную окружения ASR_SDK_ROOT.
# Модуль протестирован только под Windows!

function(_asr_find_library _name)
    if(MSVC)
        find_library(${_name}
            NAMES ${ARGN}
            HINTS
                ${ASR_SDK_ROOT}
                $ENV{ASR_SDK_ROOT}
                ${PROJECT_SOURCE_DIR}/externals/asr_sdk/${ARCHITECTURE}-${TOOLSET}
                "$ENV{PROGRAMFILES}/Speech Technology Center/AsrEngine"
                "$ENV{PROGRAMFILES(x86)}/Speech Technology Center/AsrEngine"
				"$ENV{ProgramW6432}/Speech Technology Center/AsrEngine"
            PATH_SUFFIXES lib
        )
    else()
        find_library(${_name}
            NAMES ${ARGN}
            HINTS
                ${ASR_SDK_ROOT}
                $ENV{ASR_SDK_ROOT}
                ${PROJECT_SOURCE_DIR}/externals/asr_sdk/${ARCHITECTURE}-${TOOLSET}
                /usr
                /usr/local
            PATH_SUFFIXES lib
        )
    endif()
    message("${_name}=${${_name}}")
    mark_as_advanced(${_name})
endfunction()

function(_asr_find_shared _name)
    if(MSVC)
        find_file(${_name}
            NAMES ${ARGN}
            HINTS
                ${ASR_SDK_ROOT}
                $ENV{ASR_SDK_ROOT}
                ${PROJECT_SOURCE_DIR}/externals/asr_sdk/${ARCHITECTURE}-${TOOLSET}
                "$ENV{PROGRAMFILES}/Speech Technology Center/AsrEngine"
                "$ENV{PROGRAMFILES(x86)}/Speech Technology Center/AsrEngine"
		"$ENV{ProgramW6432}/Speech Technology Center/AsrEngine"
            PATH_SUFFIXES bin
        )
    else()
        find_file(${_name}
            NAMES ${ARGN}
            HINTS
                ${ASR_SDK_ROOT}
                $ENV{ASR_SDK_ROOT}
                ${PROJECT_SOURCE_DIR}/externals/asr_sdk/${ARCHITECTURE}-${TOOLSET}/bin
                /usr/lib
                /usr/local/lib
        )
    endif()
    message("${_name}=${${_name}}")
    mark_as_advanced(${_name})
endfunction()


if(MSVC)
    find_path(STC_ASR_INCLUDE_DIR stc/asr/SDK/ASRSDKFactory.h 
        HINTS
            $ENV{ASR_SDK_ROOT}/include
            ${ASR_SDK_ROOT}/include
            ${PROJECT_SOURCE_DIR}/externals/asr_sdk/${ARCHITECTURE}-${TOOLSET}/include
            "$ENV{PROGRAMFILES}/Speech Technology Center/AsrEngine/include"
            "$ENV{PROGRAMFILES(x86)}/Speech Technology Center/AsrEngine/include"
			"$ENV{ProgramW6432}/Speech Technology Center/AsrEngine/include"
    )

    find_path(STC_ASR_LIB_DIR StcAsrSdk.lib 
        HINTS
            $ENV{ASR_SDK_ROOT}/lib
            ${ASR_SDK_ROOT}/lib
            ${PROJECT_SOURCE_DIR}/externals/asr_sdk/${ARCHITECTURE}-${TOOLSET}/lib
            "$ENV{PROGRAMFILES}/Speech Technology Center/AsrEngine/lib"
            "$ENV{PROGRAMFILES(x86)}/Speech Technology Center/AsrEngine/lib"
			"$ENV{ProgramW6432}/Speech Technology Center/AsrEngine/lib"
    )

	# try find for debug component
	if (${STC_ASR_LIB_DIR} STREQUAL STC_ASR_LIB_DIR-NOTFOUND)
    	find_path(STC_ASR_LIB_DIR StcAsrSdkD.lib 
    	    HINTS
    	        $ENV{ASR_SDK_ROOT}/lib
    	        ${ASR_SDK_ROOT}/lib
    	        ${PROJECT_SOURCE_DIR}/externals/asr_sdk/${ARCHITECTURE}-${TOOLSET}/lib
    	        "$ENV{PROGRAMFILES}/Speech Technology Center/AsrEngine/lib"
    	        "$ENV{PROGRAMFILES(x86)}/Speech Technology Center/AsrEngine/lib"
				"$ENV{ProgramW6432}/Speech Technology Center/AsrEngine/lib"
	    )
	endif()
else()
    find_path(STC_ASR_INCLUDE_DIR stc/asr/SDK/ASRSDKFactory.h
        HINTS
            $ENV{ASR_SDK_ROOT}/include
            ${ASR_SDK_ROOT}/include
            ${PROJECT_SOURCE_DIR}/externals/asr_sdk/${ARCHITECTURE}-${TOOLSET}/include
            /usr/include
            /usr/local/include
    )

    find_path(STC_ASR_LIB_DIR libStcAsrSdk.so
        HINTS
            $ENV{ASR_SDK_ROOT}/lib
            ${ASR_SDK_ROOT}/lib
            ${PROJECT_SOURCE_DIR}/externals/asr_sdk/${ARCHITECTURE}-${TOOLSET}/lib
            /usr/lib
            /usr/local/lib
    )

	# try find for debug component
	if (${STC_ASR_LIB_DIR} STREQUAL STC_ASR_LIB_DIR-NOTFOUND)
	    find_path(STC_ASR_LIB_DIR libStcAsrSdkD.so
	        HINTS
	            $ENV{ASR_SDK_ROOT}/lib
	            ${ASR_SDK_ROOT}/lib
	            ${PROJECT_SOURCE_DIR}/externals/asr_sdk/${ARCHITECTURE}-${TOOLSET}/lib
	            /usr/lib
	            /usr/local/lib
	    )
	endif()

endif()

message("STC_ASR_INCLUDE_DIR = " ${STC_ASR_INCLUDE_DIR})
message("STC_ASR_LIB_DIR = " ${STC_ASR_LIB_DIR})

mark_as_advanced(STC_ASR_INCLUDE_DIR)
mark_as_advanced(STC_ASR_LIB_DIR)

_asr_find_library(STC_ASR_LIBRARY_R StcAsrSdk)
_asr_find_library(STC_ASR_LIBRARY_D StcAsrSdkD)

if (STC_ASR_LIBRARY_R AND STC_ASR_LIBRARY_D)
	set(STC_ASR_LIBRARY optimized ${STC_ASR_LIBRARY_R} debug ${STC_ASR_LIBRARY_D})
elseif (STC_ASR_LIBRARY_R AND NOT STC_ASR_LIBRARY_D)
	set(STC_ASR_LIBRARY ${STC_ASR_LIBRARY_R})
elseif (STC_ASR_LIBRARY_D AND NOT STC_ASR_LIBRARY_R)
	set(STC_ASR_LIBRARY ${STC_ASR_LIBRARY_D})
else ()
	set(STC_ASR_LIBRARY STC_ASR_LIBRARY-NOTFOUND)
endif ()

message("STC_ASR_LIBRARY=" ${STC_ASR_LIBRARY})

if(MSVC)
    _asr_find_shared(STC_ASR_BIN_R StcAsrSdk.dll)
    _asr_find_shared(STC_ASR_BIN_D StcAsrSdkD.dll)
else()
    _asr_find_shared(STC_ASR_BIN_R libStcAsrSdk.so)
    _asr_find_shared(STC_ASR_BIN_D libStcAsrSdkD.so)
endif()

if (STC_ASR_BIN_R)
	set(STC_ASR_BIN ${STC_ASR_BIN_R})
elseif (STC_ASR_BIN_D)
	set(STC_ASR_BIN ${STC_ASR_BIN_D})
else ()
	set(STC_ASR_BIN STC_ASR_BIN-NOTFOUND)
endif()

message("STC_ASR_BIN=" ${STC_ASR_BIN})

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(StcAsrSdk DEFAULT_MSG STC_ASR_LIBRARY STC_ASR_INCLUDE_DIR STC_ASR_BIN STC_ASR_LIB_DIR)

if(STCASRSDK_FOUND)
    set(STC_ASR_SDK_FOUND 1)
    set(STC_ASR_SDK_INCLUDE_DIRS ${STC_ASR_INCLUDE_DIR})
    set(STC_ASR_SDK_LIBRARY_DIRS ${STC_ASR_LIB_DIR})
    set(STC_ASR_SDK_LIBRARIES ${STC_ASR_LIBRARY})
    set(STC_ASR_SDK_BINS ${STC_ASR_BIN})
endif()


