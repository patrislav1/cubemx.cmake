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
function(pyocd_flash PROJ_NAME)
    add_custom_target(flash
        pyocd flash "${PROJ_NAME}.bin" ${PYOCD_OPT}
        DEPENDS ${PROJ_NAME}.bin
        COMMENT "Flashing ${PROJ_NAME} to target"
    )
endfunction()
