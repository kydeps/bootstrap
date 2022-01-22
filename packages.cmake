function(init)
    set(ROOT_DIR
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/common"
        PARENT_SCOPE)
endfunction()

init()

list(APPEND CMAKE_MODULE_PATH "${ROOT_DIR}")
include(tools)

KyAssertSet(KYDEPS_CACHE_REGISTRY_DIR)

file(REAL_PATH "${KYDEPS_CACHE_REGISTRY_DIR}" DIR)
message(STATUS "using DIR=${DIR}")

# NOTE: *.*.cmake is to avoid including packages.cmake from previous run
file(GLOB _PATHS "${DIR}/*.*.cmake")

foreach(_PATH ${_PATHS})
    message(STATUS "found ${_PATH}")
endforeach()

file(
    ARCHIVE_CREATE
    OUTPUT
    "${DIR}/packages.zip"
    FORMAT
    "zip"
    PATHS
    ${_PATHS}
    VERBOSE)

file(SHA256 "${DIR}/packages.zip" _HASH)

file(
    WRITE "${DIR}/packages.cmake"
    "
include(FetchContent)
FetchContent_Declare(packages
    URL \${KYDEPS_CACHE_BUCKET}/packages.zip
    URL_HASH SHA256=${_HASH}
)
FetchContent_MakeAvailable(packages)
set(KYDEPS_CACHE_REGISTRY_DIR \"\${packages_SOURCE_DIR}\")
")
