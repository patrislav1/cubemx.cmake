set(PYOCD_DIR "${CMAKE_CURRENT_LIST_DIR}")

function(vscode_debug PROJ_NAME)
    set(PROJ_ELF_PATH "${CMAKE_BINARY_DIR}/${PROJ_NAME}.elf")
    file(MAKE_DIRECTORY "${VSCODE_DIR}")
    configure_file(
        "${PYOCD_DIR}/vscode-debug.in"
        "${VSCODE_DIR}/launch.json"
        @ONLY
    )
endfunction()
