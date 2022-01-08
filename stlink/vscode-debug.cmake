set(STLINK_DIR "${CMAKE_CURRENT_LIST_DIR}")

foreach(opt IN LISTS CMX_DEBUGGER_OPT)
    string(APPEND STLINK_OPT \"${opt}\",)
endforeach()

function(vscode_debug PROJ_NAME)
    set(PROJ_ELF_PATH "${CMAKE_BINARY_DIR}/${PROJ_NAME}.elf")
    file(MAKE_DIRECTORY "${VSCODE_DIR}")
    configure_file(
        "${STLINK_DIR}/vscode-debug.in"
        "${VSCODE_DIR}/launch.json"
        @ONLY
    )
endfunction()
