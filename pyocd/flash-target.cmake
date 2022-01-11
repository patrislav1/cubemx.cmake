set(PYOCD_OPT "-t${CMX_MCUNAME}")

#####################################
# Reset chip                        #
#####################################
add_custom_target(reset
    pyocd reset ${PYOCD_OPT}
    COMMENT "Resetting chip"
)

#####################################
# Mass erase chip                   #
#####################################
add_custom_target(erase
    pyocd erase --chip ${PYOCD_OPT}
    COMMENT "Mass erasing chip"
)

#####################################
# Flash application to target       #
#####################################
function(flash_target PROJ_NAME FLASH_TARGET_NAME IMG_ADDR)
    add_custom_target(${FLASH_TARGET_NAME}
        pyocd flash "${PROJ_NAME}.bin" -a ${IMG_ADDR} ${PYOCD_OPT}
        DEPENDS ${PROJ_NAME}.bin
        COMMENT "Flashing ${PROJ_NAME} to target"
    )
endfunction()
