include_guard(GLOBAL)

# CacheFetch -- attempt to load a package from various cache locations
#
#   - if cache is disabled (KYDEPS_CACHE=OFF)
#       *or*
#     if the packages is already installed under /i
#       -> do nothing
#
#   // if cache is enabled
#
#   - if a zip of the package is not found in /c (local miss)
#       - if a remote URL is set
#           -> try to download zip (remote hit/miss)
#
#   - if a zip of the package is found in /c (local or remote hit)
#       -> unpack it in /i
#
function(CacheFetch KYDEP)
    AddFunctionContext()

    set(_KEY "${KYDEP}.${${KYDEP}_HASH}")

    if(NOT KYDEPS_CACHE)
        AddContext("disabled")
    elseif(EXISTS "${ROOT_BINARY_DIR}/i/${_KEY}")
        AddContext("exists::skipped")
    else()
        if(EXISTS "${ROOT_BINARY_DIR}/c/${_KEY}.zip")
            AddContext("local::hit")
        elseif("-${${${KYDEP}_HASH}_URL}-" STREQUAL "--")
            AddContext("remote::miss")
        else()
            AddContext("remote::hit")

            file(
                DOWNLOAD "${${${KYDEP}_HASH}_URL}"
                "${ROOT_BINARY_DIR}/c/${_KEY}.zip"
                EXPECTED_HASH "SHA256=${${${KYDEP}_HASH}_SHA256}"
                STATUS _STATUS)

            list(GET _STATUS 0 _STATUS_CODE)

            if(NOT _STATUS_CODE EQUAL 0)
                file(REMOVE "${ROOT_BINARY_DIR}/c/${_KEY}.zip")
                KyAssert(FALSE)
            endif()
        endif()

        if(EXISTS "${ROOT_BINARY_DIR}/c/${_KEY}.zip")
            file(ARCHIVE_EXTRACT INPUT "${ROOT_BINARY_DIR}/c/${_KEY}.zip"
                    DESTINATION "${ROOT_BINARY_DIR}")
        endif()
    endif()

    message(STATUS "${_KEY}")
endfunction()

# CacheUpdate -- create local cache artifacts in /c from /i
#
# Note: also creates /c/cache.cmake manifest file
#
function(CacheUpdate KYDEP)
    AddFunctionContext()

    set(_KEY "${KYDEP}.${${KYDEP}_HASH}")

    if(KYDEPS_CACHE)
        if(EXISTS "${ROOT_BINARY_DIR}/c/${_KEY}.zip")
            AddContext("exists::skipped")
        else()
            AddContext("updated")

            # TODO(kamen): This seems to depend on the CWD of the main cmake!
            # Currently we assume that it is called from the `build` directory.
            # Roughly like `cmake .. -DCMAKE_BUILD_TYPE=...`
            #
            file(
                ARCHIVE_CREATE
                OUTPUT
                "${ROOT_BINARY_DIR}/c/${_KEY}.zip"
                PATHS
                "${ROOT_BINARY_DIR}/i/${_KEY}"
                FORMAT
                "zip")

            file(SHA256 "${ROOT_BINARY_DIR}/c/${_KEY}.zip" SHA256)

            file(
                WRITE "${ROOT_BINARY_DIR}/c/${_KEY}.cmake"
                "
${${KYDEP}_MANIFEST}
#
KyDepRegister(
    ${${KYDEP}_HASH}
    \${KYDEPS_CACHE_BUCKET}/${KYDEP}.${${KYDEP}_HASH}.zip
    ${SHA256})
                ")
        endif()
    else()
        AddContext("disabled")
    endif()

    message(STATUS "${_KEY}")
endfunction()
