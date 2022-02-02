include(ExternalProject)
include(tools)
include(configure)

# KyDep -- main implementation of KyDep macro
#
# This is a shim around ExternalProject_Add with some enchancements Note: if the
# package is already installed under /i, this is a noop
#
macro(KyDep KYDEP)
    Configure("${KYDEP}")
    AddContext("KyDep::build")

    DefineVars(${KYDEP} ${ARGN})
    set(_KEY "${KYDEP}.${${KYDEP}_HASH}")

    file(
        GLOB I_CONTENTS
        LIST_DIRECTORIES ON
        "${KYDEPS_BINARY_DIR}/i/${_KEY}/*")

    if(NOT "-${I_CONTENTS}-" STREQUAL "--")
        AddContext("exists::noop")
        add_custom_target(${KYDEP} COMMENT "noop")
    elseif(NOT KYDEPS_BUILD)
        AddContext("disabled")
    else()
        AddContext("building")
        set(_DIR "${kydeps_definitions_BINARY_DIR}/${_KEY}")
        ExternalProject_Add(
            ${KYDEP}
            PREFIX "${_DIR}"
            INSTALL_DIR "${KYDEPS_BINARY_DIR}/i/${_KEY}"
            BINARY_DIR "${_DIR}/b"
            SOURCE_DIR "${_DIR}/s"
            STAMP_DIR "${_DIR}/ts"
            TMP_DIR "${_DIR}/tmp"
            LOG_DIR "${_DIR}/log"
            CMAKE_ARGS
                "-DKYDEPS_BINARY_DIR=${KYDEPS_BINARY_DIR}" #
                "-DKYDEPS_DEFINITIONS_GIT_REPOSITORY=${KYDEPS_DEFINITIONS_GIT_REPOSITORY}" #
                "-DKYDEPS_DEFINITIONS_GIT_TAG=${KYDEPS_DEFINITIONS_GIT_TAG}" #
                "-DCMAKE_MSVC_RUNTIME_LIBRARY=${CMAKE_MSVC_RUNTIME_LIBRARY}" #
                "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" #
                "-DCMAKE_INSTALL_PREFIX:PATH=${KYDEPS_BINARY_DIR}/i/${_KEY}" #
                "-DCMAKE_MESSAGE_CONTEXT_SHOW=ON" #
                "-DCMAKE_MESSAGE_CONTEXT=CMake(${KYDEP})" #
                "-DCMAKE_INSTALL_MESSAGE=NEVER" #
                ${ARGN})

    endif()

    message(STATUS "${_KEY}")
    PopContext()
    PopContext()
endmacro()

# KyDepRegister shim
macro(KyDepRegister)
endmacro()

# KyDeps shim
macro(KyDeps)
endmacro()