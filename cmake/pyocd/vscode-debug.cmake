set(VSCODE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/.vscode")
set(PYOCD_DIR "${CMAKE_CURRENT_LIST_DIR}")

function(vscode_debug PROJ_NAME)
    set(PROJ_ELF_PATH "${CMAKE_BINARY_DIR}/${PROJ_NAME}.elf")
    # pyocd-wrapper necessary b/c of Cortex-Debug issues
    set(PYOCD_WRAPPER "${PYOCD_DIR}/pyocd-wrapper.py")
    file(MAKE_DIRECTORY "${VSCODE_DIR}")
    configure_file(
        "${PYOCD_DIR}/vscode-pyocd-dbg.in"
        "${VSCODE_DIR}/launch.json"
        @ONLY
    )
endfunction()
