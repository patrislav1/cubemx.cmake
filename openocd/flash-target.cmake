if(DEFINED OPENOCD_CFG)
    set(OPENOCD_CFG_OPT -f ${OPENOCD_CFG})
endif()

#####################################
# Reset chip                        #
#####################################
add_custom_target(reset
    openocd ${CMX_DEBUGGER_OPT} ${OPENOCD_CFG_OPT} -c "init" -c "reset" -c "exit"
    COMMENT "Resetting chip"
)

#####################################
# Mass erase chip                   #
#####################################
add_custom_target(erase
    openocd ${CMX_DEBUGGER_OPT} ${OPENOCD_CFG_OPT} -c "init" -c "halt" -c "stm32l4x mass_erase 0" -c "exit"
    COMMENT "Mass erasing chip"
)

#####################################
# Flash application to target       #
#####################################
function(flash_target PROJ_NAME FLASH_TARGET_NAME IMG_ADDR)
    add_custom_target(${FLASH_TARGET_NAME}
        openocd ${CMX_DEBUGGER_OPT} ${OPENOCD_CFG_OPT} -c "program ${PROJ_NAME}.bin reset exit ${IMG_ADDR}"
        DEPENDS ${PROJ_NAME}.bin
        COMMENT "Flashing ${PROJ_NAME} to target"
    )
endfunction()
