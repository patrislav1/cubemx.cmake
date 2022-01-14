function(vscode_debug PROJ_NAME)
    set(PROJ_ELF_PATH "${CMAKE_BINARY_DIR}/${PROJ_NAME}.elf")
    file(MAKE_DIRECTORY "${VSCODE_DIR}")
    configure_file(
        "${BMP_DIR}/vscode-debug.in"
        "${VSCODE_DIR}/launch.json"
        @ONLY
    )
endfunction()
