#####################################
# Reset chip                        #
#####################################
add_custom_target(reset
    st-flash reset
    COMMENT "Resetting chip"
)

#####################################
# Mass erase chip                   #
#####################################
add_custom_target(erase
    st-flash erase
    COMMENT "Mass erasing chip"
)

#####################################
# Flash application to target       #
#####################################
function(flash_target PROJ_NAME FLASH_TARGET_NAME IMG_ADDR)
    add_custom_target(${FLASH_TARGET_NAME}
        st-flash write ${PROJ_NAME}.bin ${IMG_ADDR}
        DEPENDS ${PROJ_NAME}.bin
        COMMENT "Flashing ${PROJ_NAME} to target"
    )
endfunction()
