include_guard(GLOBAL)

# Configure -- set configuration variables important for KyDeps
#
macro(Configure KYDEP)
    AddContext("Configure")
    get_property(
        SET_IF_EMPTY_SILENT GLOBAL
        PROPERTY CONFIGURE_SILENCER
        SET)

    SetIfEmpty(CMAKE_BUILD_TYPE Debug)

    SetIfEmpty(KYDEPS_BUILD ON)

    SetIfEmpty(KYDEPS_CACHE ON)

    SetIfEmpty(KYDEPS_BUILD_TESTS OFF)

    SetIfEmpty(KYDEPS_LOG_LEVEL DEBUG)

    SetIfEmpty(KYDEPS_TARGETS all)

    SetIfEmpty(ROOT_BINARY_DIR "${CMAKE_BINARY_DIR}")

    SetIfEmpty(KYDEPS_CI_UNIVERSE_CONFIGURE OFF)

    SetIfEmpty(KYDEPS_CACHE_BUCKET "file://${KYDEPS_CACHE_DIR}")

    # TODO(kamen): document the below carefully
    SetIfEmpty(KYDEPS_BUILD_ONE_ENABLED OFF)
    if(KYDEPS_BUILD_ONE_ENABLED AND NOT KYDEPS_CI_UNIVERSE_CONFIGURE)
        KySetAssertMessage(
            "
    KYDEPS_BUILD_ONE_ENABLED is ON, *therefore*
    KYDEP_TARGERS should be initialized to a single target!
            ")
        list(LENGTH KYDEPS_TARGETS COUNT_TARGETS)
        KyAssert(
            NOT
            KYDEPS_TARGETS
            STREQUAL
            "all"
            AND
            COUNT_TARGETS
            EQUAL
            1)
        set(KYDEP_CACHE ON)
        if("${KYDEP}" STREQUAL "${KYDEPS_TARGETS}")
            set(KYDEPS_BUILD ON)
        else()
            set(KYDEPS_BUILD OFF)
        endif()
    endif()

    set_property(GLOBAL PROPERTY CONFIGURE_SILENCER ON)
    PopContext()
endmacro()
