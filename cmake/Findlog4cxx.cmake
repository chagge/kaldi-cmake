function(_log4cxx_find_library _name)
    find_library(${_name}
        NAMES ${ARGN}
        HINTS
            ${LOG4CXX_ROOT}
            $ENV{LOG4CXX_ROOT}
        PATH_SUFFIXES bin lib
    )
    mark_as_advanced(${_name})
endfunction()

find_path(LOG4CXX_INCLUDE_DIR log4cxx/log4cxx.h
    HINTS
        ${LOG4CXX_ROOT}/include
        $ENV{LOG4CXX_ROOT}/include
)
mark_as_advanced(LOG4CXX_INCLUDE_DIR)

_log4cxx_find_library(LOG4CXX_DEBUG_LIBRARY    log4cxxwD log4cxxD log4cxx)
_log4cxx_find_library(LOG4CXX_RELEASE_LIBRARY  log4cxxw log4cxx)

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(log4cxx DEFAULT_MSG LOG4CXX_DEBUG_LIBRARY LOG4CXX_RELEASE_LIBRARY LOG4CXX_INCLUDE_DIR)

if(LOG4CXX_FOUND)
    set(log4cxx_INCLUDE_DIRS ${LOG4CXX_INCLUDE_DIR})
    set(log4cxx_LIBRARIES debug ${LOG4CXX_DEBUG_LIBRARY} optimized ${LOG4CXX_RELEASE_LIBRARY})
endif()
