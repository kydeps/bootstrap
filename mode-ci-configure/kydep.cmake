include(tools)
include(configure)

# AppendRequires -- adds a CI dependency for each item in ${ARGN} to ${YML}
# (provided in parent)
#
function(AppendRequires)
    set(DEPS "${ARGN}")
    list(TRANSFORM DEPS PREPEND "\n            - ")
    list(JOIN DEPS "" DEPS)
    string(APPEND YML "${DEPS}")
    SetInParent(YML)
endfunction()

# KyDep -- shim for KyDep macro when running in ci configuration context
#
macro(KyDep KYDEP)
    AddContext("KyDep::declare")
    Configure("${KYDEP}")
    DefineVars(${KYDEP} ${ARGN})

    cmake_parse_arguments("" "DEPENDS_DONE" "" "DEPENDS" ${ARGN})

    set(${KYDEP}_DEPENDENCY DEPENDS ${KYDEP} DEPENDS_DONE)

    list(APPEND KYDEPS "${KYDEP}")

    string(
        CONFIGURE
            "
      - ci/build-package:
          # ${KYDEP}.${${KYDEP}_HASH}
          name: ${KYDEP}
          package-name: ${KYDEP}
          requires:
            - start"
            YML)
    AppendRequires(${_DEPENDS})
    list(APPEND KYDEPS_YML "${YML}")

    message(STATUS "${KYDEP}")
    PopContext()
endmacro()

# KyDepRegister shim
macro(KyDepRegister)

endmacro()

# KyDeps -- generate the dynamic CircleCI config
#
macro(KyDeps)
    set(YML
        "
version: 2.1

orbs:
  ci: kydeps/ci@dev:alpha

workflows:
  distributed-build:
    jobs:
      - hold:
          type: approval
      - ci/build-status:
          name: start
          requires:
            - hold")

    foreach(KYDEP_YML ${KYDEPS_YML})
        string(APPEND YML "${KYDEP_YML}")
    endforeach()

    string(
        APPEND
        YML
        "
      - ci/build-upload:
          name: end
          context:
            - s3-upload
          requires:
            - start")
    AppendRequires(${KYDEPS})

    file(WRITE "${CMAKE_BINARY_DIR}/universe.yml" ${YML})
    message(
        STATUS
            "CI Universe Build Config generated at ${CMAKE_BINARY_DIR}/universe.yml"
    )
endmacro()
