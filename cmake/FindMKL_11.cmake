function(_mkl_find_library _name)
    if(MSVC)
		if (PROCESSOR_BITS STREQUAL "64") 
			find_library(${_name}
				NAMES ${ARGN}
				HINTS
					${MKL_ROOT}
					$ENV{MKL_ROOT}
				PATH_SUFFIXES lib/intel64/
			)
		else()
			find_library(${_name}
				NAMES ${ARGN}
				HINTS
					${MKL_ROOT}
					$ENV{MKL_ROOT}
				PATH_SUFFIXES lib/ia32
			)
		endif()
    else()
		if (PROCESSOR_BITS STREQUAL "64")
			find_library(${_name}
            NAMES ${ARGN}
            HINTS
                ${MKL_ROOT}
                $ENV{MKL_ROOT}
            PATH_SUFFIXES lib/intel64/
        )
		else()
		    find_library(${_name}
            NAMES ${ARGN}
            HINTS
                ${MKL_ROOT}
                $ENV{MKL_ROOT}
            PATH_SUFFIXES lib/ia32
        )
		endif()
    endif()
    mark_as_advanced(${_name})
endfunction()

find_path(MKL_INCLUDE_DIR mkl.h
    HINTS
        ${MKL_ROOT}/include
        $ENV{MKL_ROOT}/include
)
mark_as_advanced(MKL_INCLUDE_DIR)

_mkl_find_library(MKL_CORE_LIBRARY          libmkl_core.a  mkl_core)
_mkl_find_library(MKL_SEQUENTIAL_LIBRARY    libmkl_sequential.a mkl_sequential)
if	(PROCESSOR_BITS STREQUAL "64")
	_mkl_find_library(MKL_INTEL_LIBRARY         libmkl_intel_lp64.a mkl_intel_lp64)
else()
	_mkl_find_library(MKL_INTEL_LIBRARY         libmkl_intel.a mkl_intel mkl_intel_c)
endif()

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(MKL DEFAULT_MSG MKL_CORE_LIBRARY MKL_INTEL_LIBRARY MKL_SEQUENTIAL_LIBRARY MKL_INCLUDE_DIR)

if(MKL_FOUND)
    set(MKL_INCLUDE_DIRS ${MKL_INCLUDE_DIR})
    set(MKL_LIBRARIES ${MKL_INTEL_LIBRARY} ${MKL_SEQUENTIAL_LIBRARY} ${MKL_CORE_LIBRARY})
endif()
