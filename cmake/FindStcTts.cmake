function(_tts_find_library _name)
    if(MSVC)
        find_library(${_name}
            NAMES ${ARGN}
            HINTS
                ${STC_TTS_ROOT}
                $ENV{STC_TTS_ROOT}
                ${PROJECT_SOURCE_DIR}/externals/tts_sdk/${ARCHITECTURE}-${TOOLSET}
                "$ENV{PROGRAMFILES}/Speech Technology Center/TTS/Russian/Engine"
                "$ENV{PROGRAMFILES(x86)}/Speech Technology Center/TTS/Russian/Engine"
            PATH_SUFFIXES lib
        )
    else()
        find_library(${_name}
            NAMES ${ARGN}
            HINTS
                ${STC_TTS_ROOT}
                $ENV{STC_TTS_ROOT}
                ${PROJECT_SOURCE_DIR}/externals/tts_sdk/${ARCHITECTURE}-${TOOLSET}
                /usr
                /usr/local
            PATH_SUFFIXES lib
        )
    endif()
    mark_as_advanced(${_name})
endfunction()

if(MSVC)
    find_path(STC_TTS_INCLUDE_DIR TTS.h
        HINTS
            $ENV{STC_TTS_ROOT}/include
            ${TTS_ROOT}/include
            ${PROJECT_SOURCE_DIR}/externals/tts_sdk/${ARCHITECTURE}-${TOOLSET}/include
            "$ENV{PROGRAMFILES}/Speech Technology Center/TTS/Russian/Engine/include"
            "$ENV{PROGRAMFILES(x86)}/Speech Technology Center/TTS/Russian/Engine/include"
    )
else()
    find_path(STC_TTS_INCLUDE_DIR TTS.h
        HINTS
            $ENV{STC_TTS_ROOT}/include
            ${TTS_ROOT}/include
            ${PROJECT_SOURCE_DIR}/externals/tts_sdk/${ARCHITECTURE}-${TOOLSET}/include
            /usr/include
            /usr/local/include
    )
endif()
mark_as_advanced(STC_TTS_INCLUDE_DIR)

if(MSVC)
    _tts_find_library(STC_TTS_LIBRARY               TTS)
    _tts_find_library(STC_TTS_PARSER_TXT_LIBRARY    parser_txt)
else()
    _tts_find_library(STC_TTS_LIBRARY               stctts)
    _tts_find_library(STC_TTS_PARSER_TXT_LIBRARY    stc_parser_txt)
endif()

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(StcTts DEFAULT_MSG STC_TTS_LIBRARY STC_TTS_PARSER_TXT_LIBRARY STC_TTS_INCLUDE_DIR)

if(STCTTS_FOUND)
    set(STC_TTS_FOUND 1)
    set(STC_TTS_INCLUDE_DIRS ${STC_TTS_INCLUDE_DIR})
    set(STC_TTS_LIBRARIES ${STC_TTS_LIBRARY} ${STC_TTS_PARSER_TXT_LIBRARY})
endif()
