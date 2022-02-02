include(tools)
include(cache)
include(configure)

# KyDep -- shim for KyDep macro when running in main project context
#
macro(KyDep KYDEP)
    AddContext("KyDep::declare")
    Configure("${KYDEP}")
    DefineVars(${KYDEP} ${ARGN})
    IncludeGlob("${KYDEPS_CACHE_REGISTRY_DIR}/${KYDEP}.${${KYDEP}_HASH}.cmake")
    CacheFetch(${KYDEP})
    list(APPEND KYDEPS "${KYDEP}")
    PopContext()
endmacro()

# KyDepRegister -- used by generated `cache.cmake` from CacheUpdate
#
function(KyDepRegister)
    AddFunctionContext()
    Configure("")

    list(LENGTH ARGN _COUNT)
    KyAssert(_COUNT EQUAL 3)

    list(GET ARGN 0 _HASH)
    list(GET ARGN 1 ${_HASH}_URL)
    list(GET ARGN 2 ${_HASH}_SHA256)

    message(STATUS "+ ${${_HASH}_URL}")

    SetInParent(${_HASH}_URL)
    SetInParent(${_HASH}_SHA256)
endfunction()

# builds dependencies (if necessary) updates ${CMAKE_PREFIX_PATH} with their
# locations
#
macro(KyDeps)
    AddContext("KyDep::finalize")
    Configure("")

    if(KYDEPS_CACHE AND "-${KYDEPS_CACHE_BUCKET}-" STREQUAL "--")
        message(
            WARNING
                "
    KYDEPS_CACHE is ON
        *but*
    KYDEPS_CACHE_BUCKET is not defined...
        *therefore*
    - remote cache is disabled
    - no packages will be fetched from outside your build
                ")
    endif()

    set(CMD
        "${CMAKE_COMMAND}" #
        "--log-level ${KYDEPS_LOG_LEVEL}" #
        "-S ${kydeps_definitions_SOURCE_DIR}" #
        "-B ${kydeps_definitions_BINARY_DIR}" #
        "-D KYDEPS_DEFINITIONS_GIT_REPOSITORY=${KYDEPS_DEFINITIONS_GIT_REPOSITORY}" #
        "-D KYDEPS_DEFINITIONS_GIT_TAG=${KYDEPS_DEFINITIONS_GIT_TAG}" #
        "-D KYDEPS_BINARY_DIR=${KYDEPS_BINARY_DIR}" #
        "-D KYDEPS_BUILD=${KYDEPS_BUILD}" #
        "-D KYDEPS_BUILD_ONE_ENABLED=${KYDEPS_BUILD_ONE_ENABLED}" #
        "-D CMAKE_MSVC_RUNTIME_LIBRARY=${CMAKE_MSVC_RUNTIME_LIBRARY}" #
        "-D CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" #
        "-G ${CMAKE_GENERATOR}")
    message(STATUS "${CMD}")

    message(STATUS "${KYDEPS_CXX_FLAGS}")
    # TODO(kamen): platform dependency on sed below...
    #
    execute_process(
        COMMAND_ERROR_IS_FATAL ANY
        COMMAND
            ${CMD}
            "-D CMAKE_MODULE_PATH=${kydeps_bootstrap_SOURCE_DIR}/common;${kydeps_bootstrap_SOURCE_DIR}/mode-build" #
            "-D KYDEPS_TARGETS=${KYDEPS_TARGETS}" #
        COMMAND "sed" "-u" "s_^_\t(KyDeps::Config) _")
    execute_process(
        COMMAND_ERROR_IS_FATAL ANY
        COMMAND
            ${CMAKE_COMMAND} #
            "-E" "env" "CXXFLAGS=${KYDEPS_CXX_FLAGS}"
            "CFLAGS=${KYDEPS_CXX_FLAGS}" #
            ${CMAKE_COMMAND} #
            --build ${kydeps_definitions_BINARY_DIR} #
            --config ${CMAKE_BUILD_TYPE} #
            --target ${KYDEPS_TARGETS} #
        COMMAND "sed" "-u" "s_^_\t(KyDeps::Build) _")

    file(MAKE_DIRECTORY "${KYDEPS_BINARY_DIR}/i")
    file(MAKE_DIRECTORY "${KYDEPS_BINARY_DIR}/c")

    foreach(KYDEP ${KYDEPS})
        set(_KEY "${KYDEP}.${${KYDEP}_HASH}")
        list(APPEND CMAKE_PREFIX_PATH "${KYDEPS_BINARY_DIR}/i/${_KEY}")
    endforeach()

    if (KYDEPS_TARGETS STREQUAL "all")
        set(KYDEPS_TARGETS ${KYDEPS})
    endif()

    foreach(KYDEP ${KYDEPS_TARGETS})
        set(_KEY "${KYDEP}.${${KYDEP}_HASH}")
        file(
            GLOB I_CONTENTS
            LIST_DIRECTORIES ON
            "${KYDEPS_BINARY_DIR}/i/${_KEY}/*")
        if("-${I_CONTENTS}-" STREQUAL "--")
            # TODO(kamen): make the below error message better if it happens
            message(FATAL_ERROR "${_KEY} has no installed files :(")
        else()
            CacheUpdate(${KYDEP})
        endif()
    endforeach()

    SetInParent(CMAKE_PREFIX_PATH)
    SetInParent(KYDEPS)

    PopContext()
endmacro()
