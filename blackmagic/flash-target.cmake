set(BMP_DIR "${CMAKE_CURRENT_LIST_DIR}")

function(add_erase_and_reset)
    # Blackmagic probe implements a GDB server, so we have only GDB commands at our disposal.
    # There is no support for reset or mass erase, so we can only implement the flash function
    message(WARNING "erase / reset target not implemented for Blackmagic probe")
endfunction()

if("${BLACKMAGIC_GDB_PORT}" STREQUAL "")
    set(BLACKMAGIC_GDB_PORT "/dev/ttyBmpGdb")
endif()

#####################################
# Flash application to target       #
#####################################
function(flash_target PROJ_NAME FLASH_TARGET_NAME IMG_ADDR)
    # GDB cannot flash a .bin file, it needs the .elf one.
    add_custom_target(${FLASH_TARGET_NAME}
        arm-none-eabi-gdb 
        -ex "target extended-remote ${BLACKMAGIC_GDB_PORT}"
        -x "${BMP_DIR}/flash-seq.gdb"
        "${PROJ_NAME}.elf"
        DEPENDS ${PROJ_NAME}
        COMMENT "Flashing ${PROJ_NAME} to target"
    )
endfunction()
