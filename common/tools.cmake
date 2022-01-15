include_guard(GLOBAL)

# AddContext -- a shorthand to append to CMAKE_MESSAGE_CONTEXT
#
macro(AddContext CONTEXT)
    list(APPEND CMAKE_MESSAGE_CONTEXT "${CONTEXT}")
endmacro()

# PopContext -- a shorthand to remove from CMAKE_MESSAGE_CONTEXT
#
# Note: this is only necessary in macros, because functions have their own scope
# and the original CMAKE_MESSAGE_CONTEXT is restored on function return.
#
macro(PopContext)
    list(POP_BACK CMAKE_MESSAGE_CONTEXT)
endmacro()

# AddFunctionContext -- add the current function name to the context
#
macro(AddFunctionContext)
    AddContext("${CMAKE_CURRENT_FUNCTION}")
endmacro()

# KySetAssertMessage -- set a message which is used from subsequent KyAssert
#
macro(KySetAssertMessage MESSAGE)
    set(KY_ASSERT_MESSAGE ": ${MESSAGE}")
endmacro()

# KyAssert -- assert a condition and exit with FATAL_ERROR if not true
#
# Note: an extra message can be provided by calling KySetAssertMessage first
#
function(KyAssert)
    AddFunctionContext()

    if(NOT (${ARGN}))
        message(FATAL_ERROR "assertion failed `${ARGN}` ${KY_ASSERT_MESSAGE}")
    endif()
endfunction()

# KyAssertSet -- a shorthand assertion that a variable is set
#
function(KyAssertSet VAR)
    AddFunctionContext()

    KyAssert(NOT ("-${VAR}-" STREQUAL "--"))
endfunction()

# SetInParent -- promote a variable from the current scope to the parent scope
#
macro(SetInParent KYDEP)
    set(${KYDEP}
        "${${KYDEP}}"
        PARENT_SCOPE)
endmacro()

# SetIfEmpty -- a useful shortcut to set variable defaults if unset
#
# Note: normally prints details on weather it used the default or if the
# variable was already set. Define SET_IF_EMPTY_SILENT to avoid output.
#
macro(SetIfEmpty NAME VALUE)
    if("-${${NAME}}-" STREQUAL "--")
        if(NOT SET_IF_EMPTY_SILENT)
            message(VERBOSE
                    "`${NAME}` is empty, using default value `${VALUE}`")
        endif()
        set(${NAME} "${VALUE}")
    else()
        if(NOT SET_IF_EMPTY_SILENT)
            message(VERBOSE "`${NAME}` overriden to `${${NAME}}`")
        endif()
    endif()
endmacro()

# IncludeGlob -- accepts a path glob, expands it, and includes each item
#
macro(IncludeGlob GLOB)
    file(GLOB IncludeGlob_RESULTS "${GLOB}")
    foreach(IncludeGlob_RESULT ${IncludeGlob_RESULTS})
        include(${IncludeGlob_RESULT})
    endforeach()
endmacro()

# ComputeHash -- this is how packages hashes are computed.
#
# The current algorithm hashes: - All parameters passed to KyDep -
# CMAKE_BUILD_TYPE - CMAKE_SYSTEM - CMAKE_SYSTEM_PROCESSOR
#
# TODO: conside if further elements need to be added, e.g. - Something about the
# compiler (e.g. ABI) - Version of the bootstrap repo? - Something else?
#
function(ComputeHash KYDEP)
    AddFunctionContext()

    set(_MANIFEST_LIST
        "#  MANIFEST[${KYDEP}]" #
        "----------" #
        "CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" #
        "CMAKE_SYSTEM=${CMAKE_SYSTEM}" #
        "CMAKE_SYSTEM_PROCESSOR=${CMAKE_SYSTEM_PROCESSOR}" #
        "----------" #
        ${ARGN} #
        "----------")
    list(JOIN _MANIFEST_LIST "\n#  " ${KYDEP}_MANIFEST)
    string(REPLACE "${ROOT_BINARY_DIR}" "..." ${KYDEP}_MANIFEST
                   "${${KYDEP}_MANIFEST}")
    string(SHA1 ${KYDEP}_HASH "${${KYDEP}_MANIFEST}")
    message(DEBUG "${${KYDEP}_MANIFEST}")

    SetInParent(${KYDEP}_MANIFEST)
    SetInParent(${KYDEP}_HASH)
endfunction()

# DefineVars -- defines package-specific variables needed by KyDep
#
# * ${KYDEP}_MANIFEST
# * ${KYDEP}_HASH
# * ${KYDEP}_DEPENDENCY
#
macro(DefineVars KYDEP)
    ComputeHash(${KYDEP} ${ARGN})
    set(_PATH "${ROOT_BINARY_DIR}/i/${KYDEP}.${${KYDEP}_HASH}")
    set(${KYDEP}_DEPENDENCY CMAKE_ARGS "-DCMAKE_PREFIX_PATH:PATH=${_PATH}"
                            DEPENDS ${KYDEP})
endmacro()
