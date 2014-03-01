##if (NOT DEFINED IPP_ENVIRONMENT_BITS)
##	set(IPP_ENVIRONMENT_BITS 32)
##endif()

## static libs
##if(NOT DEFINED IPP_USE_STATIC_LIBS)
##	set(IPP_USE_STATIC_LIBS TRUE)
##endif()
##
##


#
#
##		Begin functions and macrocs
##
function (_Ipp_set_suffixed )
	if (IPP_USE_STATIC_LIBS)
		set(Ipp_PATH_SUFFIXES lib)
	else(IPP_USE_STATIC_LIBS)
		if(UNIX)
			set (Ipp_PATH_SUFFIXES sharedlib)
		else(UNIX)
			set (Ipp_PATH_SUFFIXES stublib)
		endif(UNIX)
	endif()
	set (Ipp_PATH_SUFFIXES ${Ipp_PATH_SUFFIXES} PARENT_SCOPE)
	#mark_as_advanced(Ipp_PATH_SUFFIXES)
endfunction()

function(_ipp_find_library _name)
	find_library(${_name}
		NAMES ${ARGN}
		HINTS
		${IPP_ROOT}
		PATH_SUFFIXES ${Ipp_PATH_SUFFIXES}
	)
	mark_as_advanced(${_name})
endfunction()

function(_ipp_find_library_block _name)

	if(IPP_USE_STATIC_LIBS)

		_ipp_find_library(${_name}_EMERGED ${ARGN}emerged${IPP_BITS_POSTFIX})
		#_ipp_find_library(${_name}_MERGED_T ${ARGN}merged_t)
		_ipp_find_library(${_name}_MERGED ${ARGN}merged${IPP_BITS_POSTFIX}${IPP_THREADED_POSTFIX})

		list(APPEND ${_name} ${${_name}_EMERGED})
		list(APPEND  ${_name} ${${_name}_MERGED})

		#list(APPEND ${_name} ${${_name}_MERGED_T})

		set ( ${_name}  ${${_name}} PARENT_SCOPE)

	else(IPP_USE_STATIC_LIBS)

		_ipp_find_library(${_name} ${ARGN}${IPP_BITS_POSTFIX})
		#set ( ${_name}  ${${_name}} PARENT_SCOPE)

	endif(IPP_USE_STATIC_LIBS)

endfunction(_ipp_find_library_block _name)

#
# A convenience function for marking desired components
# as found or not
#
function(_Ipp_MARK_COMPONENTS_FOUND _yes_or_no)
	foreach(COMPONENT ${Ipp_FIND_COMPONENTS})
		string(TOUPPER ${COMPONENT} UPPERCOMPONENT)
		set(Ipp_${UPPERCOMPONENT}_FOUND ${_yes_or_no} CACHE INTERNAL "Whether the Intel IPP ${COMPONENT} library found" FORCE)
	endforeach()
endfunction()

#
# End function and macros
#
#-----------------------------------------------------------------



if (NOT DEFINED IPP_ENVIRONMENT_BITS)
	set(IPP_ENVIRONMENT_BITS 32)
endif()

# static libs
if(NOT DEFINED IPP_USE_STATIC_LIBS)
	set(IPP_USE_STATIC_LIBS TRUE)
endif()

# threaded static libs
if(NOT DEFINED IPP_USE_THREADED_STATIC_LIBS)
        set(IPP_USE_THREADED_STATIC_LIBS FALSE)
endif()

set(IPP_BITS_POSTFIX "")
if (IPP_ENVIRONMENT_BITS EQUAL 64)
        set (IPP_BITS_POSTFIX em64t)
endif()

set(IPP_THREADED_POSTFIX "")
if (IPP_USE_THREADED_STATIC_LIBS)
        set (IPP_THREADED_POSTFIX _t)
endif()
#_POSTFIX

# If IPP_ROOT was defined in the environment, use it.
if (NOT IPP${IPP_ENVIRONMENT_BITS}_ROOT AND NOT $ENV{IPP${IPP_ENVIRONMENT_BITS}_ROOT} STREQUAL "")
	set(IPP${IPP_ENVIRONMENT_BITS}_ROOT $ENV{IPP${IPP_ENVIRONMENT_BITS}_ROOT})
endif()

set(IPP_ROOT ${IPP${IPP_ENVIRONMENT_BITS}_ROOT})

message(STATUS "${IPP_ROOT}")

if(IPP_FIND_VERSION_EXACT)
	# The version may appear in a directory with or without the patch
	# level, even when the patch level is non-zero.
	set(_boost_TEST_VERSIONS
	"${IPP_FIND_VERSION_MAJOR}.${IPP_FIND_VERSION_MINOR}.${IPP_FIND_VERSION_PATCH}"
	"${IPP_FIND_VERSION_MAJOR}.${IPP_FIND_VERSION_MINOR}")
else()
	if (IPP_FIND_VERSION)
		message(STATUS "${IPP_FIND_VERSION}")
	else(IPP_FIND_VERSION)
		#message(STATUS "[ ${CMAKE_CURRENT_LIST_FILE}:${CMAKE_CURRENT_LIST_LINE} ] "
		# "boost ${IPP_MAJOR_VERSION}.${IPP_MINOR_VERSION}.${IPP_SUBMINOR_VERSION} "
		# "is already in the cache. To view debugging messages, please clear the cache.")
	endif(IPP_FIND_VERSION)
endif()

_Ipp_set_suffixed()

find_path(IPP_INCLUDE_DIR ipp.h
	HINTS
	${IPP_ROOT}/include
)
mark_as_advanced(IPP_INCLUDE_DIR)

#message(${IPP_THREADED_POSTFIX})
_ipp_find_library(IPP_CORE_LIBRARY
	# Windows:
	"ippcore${IPP_BITS_POSTFIX}l${IPP_THREADED_POSTFIX}"
	# Unix:
	"ippcore${IPP_BITS_POSTFIX}${IPP_THREADED_POSTFIX}"
)
mark_as_advanced ( IPP_CORE_LIBRARY  )


if (IPP_USE_THREADED_STATIC_LIBS)
	_ipp_find_library(IPP_I_OMP_LIBRARY
		# Windows:
		libiomp5md
		libiomp5mt
		# Unix:
		iomp5		
	)
	mark_as_advanced(IPP_I_OMP_LIBRARY)
endif(IPP_USE_THREADED_STATIC_LIBS)


foreach(COMPONENT ${IPP_FIND_COMPONENTS})
	string(TOLOWER ${COMPONENT} COMPONENT)
	_ipp_find_library_block(${COMPONENT}_LIBRARY ${COMPONENT} )

	set(IPP_COMPONENTS_LIBRARY ${IPP_COMPONENTS_LIBRARY} ${${COMPONENT}_LIBRARY}) 
endforeach()



#IPP_COMPONENTS_LIBRARY
#message (STATUS ${IPP_COMPONENTS_LIBRARY})
#message (STATUS ${IPP_CORE_LIBRARY})

include(FindPackageHandleStandardArgs)
if (IPP_USE_THREADED_STATIC_LIBS)
	FIND_PACKAGE_HANDLE_STANDARD_ARGS(IPP DEFAULT_MSG IPP_CORE_LIBRARY IPP_COMPONENTS_LIBRARY IPP_I_OMP_LIBRARY IPP_INCLUDE_DIR)
else(IPP_USE_THREADED_STATIC_LIBS)
	FIND_PACKAGE_HANDLE_STANDARD_ARGS(IPP DEFAULT_MSG IPP_CORE_LIBRARY IPP_COMPONENTS_LIBRARY IPP_INCLUDE_DIR)
endif(IPP_USE_THREADED_STATIC_LIBS)

if(IPP_FOUND)
	set(IPP_INCLUDE_DIRS ${IPP_INCLUDE_DIR})
	if(IPP_USE_THREADED_STATIC_LIBS)
		set(IPP_LIBRARIES ${IPP_COMPONENTS_LIBRARY} ${IPP_CORE_LIBRARY}  ${IPP_I_OMP_LIBRARY})
	else(IPP_USE_THREADED_STATIC_LIBS)
	         set(IPP_LIBRARIES ${IPP_COMPONENTS_LIBRARY} ${IPP_CORE_LIBRARY} )
	endif(IPP_USE_THREADED_STATIC_LIBS)
	set(IPP_LIBRARY_DIRS ${IPP_ROOT}/${Ipp_PATH_SUFFIXES} )
endif()
