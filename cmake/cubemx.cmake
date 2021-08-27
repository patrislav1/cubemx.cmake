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
        RESULT_VARIABLE RET_CODE
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(${RET_CODE})
        message(FATAL_ERROR "cubemx-cmake.py failed - aborting")
    endif()
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
cmx_get(srcpath CMX_SRCPATH)

set(CMX_INC
    "${CMAKE_CURRENT_SOURCE_DIR}/${CMX_SRCPATH}/Inc"
    "${CMAKE_CURRENT_SOURCE_DIR}/Drivers/CMSIS/Include"
    "${CMAKE_CURRENT_SOURCE_DIR}/Drivers/CMSIS/Device/ST/${CMX_MCUFAM}/Include"
    "${CMAKE_CURRENT_SOURCE_DIR}/Drivers/${CMX_MCUFAM}_HAL_Driver/Inc"
)

file(GLOB_RECURSE CMX_SRC
    "${CMAKE_CURRENT_SOURCE_DIR}/Drivers/${CMX_MCUFAM}_HAL_Driver/Src/*.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/${CMX_SRCPATH}/Src/*.c"
)

enable_language(ASM)

# Check if the "Makefile" startupfile is in the source tree
cmx_get(startupfile_makefile CMX_STARTUPFILE)
file(GLOB_RECURSE STARTUPFILE_PATH ${CMAKE_CURRENT_SOURCE_DIR} ${CMX_STARTUPFILE})
if("${STARTUPFILE_PATH}" STREQUAL "")
    # If not, look for the "STM32CubeIDE" startupfile
    cmx_get(startupfile_stm32cubeide CMX_STARTUPFILE)
    file(GLOB_RECURSE STARTUPFILE_PATH ${CMAKE_CURRENT_SOURCE_DIR} ${CMX_STARTUPFILE})
endif()
message("Using startup file: ${STARTUPFILE_PATH}")

list(APPEND CMX_SRC
    "${STARTUPFILE_PATH}"
)

# Check if the "Makefile" linkerscript is in the source tree
set(LINKERSCRIPT "${CMX_MCUNAME}_FLASH.ld")
file(GLOB_RECURSE CMX_LDFILE ${CMAKE_CURRENT_SOURCE_DIR} ${LINKERSCRIPT})
if("${CMX_LDFILE}" STREQUAL "")
    # If not, look for the "STM32CubeIDE" linkerscript
    string(REPLACE "x" "X" LINKERSCRIPT ${LINKERSCRIPT})
    file(GLOB_RECURSE CMX_LDFILE ${CMAKE_CURRENT_SOURCE_DIR} ${LINKERSCRIPT})
endif()
message("Using linkerscript: ${CMX_LDFILE}")

set(CMAKE_EXECUTABLE_SUFFIX ".elf")

########################################
# Set up flashing & debugging          #
########################################

if(NOT DEFINED CMX_DEBUGGER)
    set(CMX_DEBUGGER "stlink")
endif()
include(${CMAKE_CURRENT_LIST_DIR}/${CMX_DEBUGGER}/flash-target.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/${CMX_DEBUGGER}/vscode-debug.cmake)

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
    target_link_options(${PROJ_NAME} PRIVATE -Xlinker --print-memory-usage)

    mcu_image_utils(${PROJ_NAME})
    flash_target(${PROJ_NAME})
    vscode_debug(${PROJ_NAME})
endfunction()
