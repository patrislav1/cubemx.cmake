include(${CMAKE_CURRENT_LIST_DIR}/mcu-img-utils.cmake)

#####################################
# Setup CubeMX .ioc parser          #
#####################################

find_package(Python3 COMPONENTS Interpreter)

if(NOT Python3_FOUND)
    message(FATAL_ERROR "Need Python3")
endif()

set(CMX_CMAKE "${CMAKE_CURRENT_LIST_DIR}/cubemx-cmake.py")

function(cmx_get KEY_NAME VAR_NAME)
    execute_process(COMMAND
        ${Python3_EXECUTABLE}
        ${CMX_CMAKE} ${CMX_IOC} ${KEY_NAME}
        OUTPUT_VARIABLE KEY_VAL
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(${VAR_NAME} ${KEY_VAL} PARENT_SCOPE)
endfunction()

##################################################
# Get CubeMX project name (convenience function) #
##################################################

cmx_get(prjname CMX_PROJ)

########################################
# Determine MCU & source/include paths #
########################################

cmx_get(mcuname CMX_MCUNAME)
cmx_get(mcufamily CMX_MCUFAM)

set(CMX_INC
    "${CMAKE_CURRENT_SOURCE_DIR}/Core/Inc"
    "${CMAKE_CURRENT_SOURCE_DIR}/Drivers/CMSIS/Include"
    "${CMAKE_CURRENT_SOURCE_DIR}/Drivers/CMSIS/Device/ST/${CMX_MCUFAM}/Include"
    "${CMAKE_CURRENT_SOURCE_DIR}/Drivers/${CMX_MCUFAM}_HAL_Driver/Inc"
)

file(GLOB_RECURSE CMX_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/Drivers/${CMX_MCUFAM}_HAL_Driver/Src/*.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/Core/Src/*.c"
)

enable_language(ASM)
cmx_get(startupfile CMX_STARTUPFILE)

list(APPEND CMX_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/${CMX_STARTUPFILE}"
)

set(CMX_LDFILE
    "${CMAKE_CURRENT_SOURCE_DIR}/${CMX_MCUNAME}_FLASH.ld"
)

set(CMAKE_EXECUTABLE_SUFFIX ".elf")

########################################
# Set up flashing & debugging          #
########################################

include(${CMAKE_CURRENT_LIST_DIR}/pyocd/pyocd.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/pyocd/vscode-debug.cmake)

########################################
# Set up compiler / linker options     #
########################################

cmx_get(mcuflags CMX_MCUFLAGS)
cmx_get(cdefs CMX_CDEFS)

function(cubemx_target PROJ_NAME)
    target_compile_options(${PROJ_NAME} PRIVATE ${CMX_MCUFLAGS})
    target_compile_options(${PROJ_NAME} PRIVATE -ffunction-sections -fdata-sections)
    target_compile_definitions(${PROJ_NAME} PRIVATE ${CMX_CDEFS})
    target_link_options(${PROJ_NAME} PUBLIC ${CMX_MCUFLAGS})
    target_link_options(${PROJ_NAME} PRIVATE "-T${CMX_LDFILE}")
    target_link_options(${PROJ_NAME} PRIVATE
        -Wl,--gc-sections
        --specs=nano.specs
    )
    target_link_libraries(${PROJ_NAME} c m nosys)
    target_sources(${PROJ_NAME} PRIVATE ${CMX_SRC})
    target_include_directories(${PROJ_NAME} PRIVATE ${CMX_INC})

    mcu_image_utils(${PROJ_NAME})
    pyocd_flash(${PROJ_NAME})
    vscode_debug(${PROJ_NAME})
endfunction()
