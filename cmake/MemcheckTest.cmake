find_program(VALGRIND_EXECUTABLE NAMES valgrind PATHS $ENV{PATH} )

macro (ADD_MEMCHECK_TEST name command arg1)
    if(NOT MEMCHECK_TEST_ENABLED OR VALGRIND_EXECUTABLE-NOTFOUND)
        add_test (${name} ${command} ${arg1})
    else()
        add_test (${name} ${VALGRIND_EXECUTABLE} --run-libc-freeres=no --leak-check=full ${command} ${arg1})
        set_tests_properties (${name}
            PROPERTIES
            PASS_REGULAR_EXPRESSION "ERROR SUMMARY: 0 errors"
        )
    endif()
endmacro (ADD_MEMCHECK_TEST)
