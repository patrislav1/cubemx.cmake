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
function(flash_target PROJ_NAME)
    add_custom_target(flash
        st-flash write ${PROJ_NAME}.bin 0x08000000
        DEPENDS ${PROJ_NAME}.bin
        COMMENT "Flashing ${PROJ_NAME} to target"
    )
endfunction()
