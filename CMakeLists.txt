cmake_minimum_required(VERSION 3.22)
project(
    kydeps_bootstrap
    VERSION 3.0
    HOMEPAGE_URL https://github.com/kydeps/bootstrap)

list(APPEND CMAKE_MODULE_PATH "${kydeps_bootstrap_SOURCE_DIR}/common")

include(tools)

set(CMAKE_MESSAGE_CONTEXT_SHOW ON)
SetInParent(CMAKE_MESSAGE_CONTEXT_SHOW)

include(configure)
Configure("")

AddContext("Cmake(${CMAKE_PROJECT_NAME})")

if(KYDEPS_CI_UNIVERSE_CONFIGURE)
    message(STATUS "MODE: CI Universe Configure")
    list(APPEND CMAKE_MODULE_PATH "${kydeps_bootstrap_SOURCE_DIR}/mode-ci-configure")
elseif(CMAKE_SOURCE_DIR STREQUAL kydeps_definitions_SOURCE_DIR AND NOT KYDEPS_CI_UNIVERSE_BUILD)
    message(STATUS "MODE: Build")
    list(APPEND CMAKE_MODULE_PATH "${kydeps_bootstrap_SOURCE_DIR}/mode-build")
else()
    message(STATUS "MODE: Configure")
    list(APPEND CMAKE_MODULE_PATH "${kydeps_bootstrap_SOURCE_DIR}/mode-configure")
endif()

include(kydep)

# TODO(kamen): figure out how we can put this in configure... 
#              currently fails if there is no parent scope!
SetInParent(CMAKE_MESSAGE_CONTEXT)
SetInParent(ROOT_BINARY_DIR)
SetInParent(KYDEPS_BUILD_TESTS)
SetInParent(KYDEPS_CACHE_REGISTRY)
SetInParent(KYDEPS_CACHE_BUCKET)

cmake_language(DEFER DIRECTORY ${kydeps_definitions_SOURCE_DIR} CALL KyDeps)
