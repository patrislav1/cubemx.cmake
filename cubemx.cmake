include(${CMAKE_CURRENT_LIST_DIR}/mcu-img-utils.cmake)
set(VSCODE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/.vscode")
set(CUBEMXCMK_DIR "${CMAKE_CURRENT_LIST_DIR}")

#####################################
# Setup CubeMX .ioc parser          #
#####################################

find_package(Python3 COMPONENTS Interpreter)
if(NOT Python3_FOUND)
    message(FATAL_ERROR "Need Python3")
endif()

set(CMX_CMAKE "${CMAKE_CURRENT_LIST_DIR}/cubemx-cmake.py")

enable_language(ASM)
set(CMAKE_EXECUTABLE_SUFFIX ".elf")

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

function(add_default_sources)
    set(CMX_INC
        "${CMAKE_CURRENT_SOURCE_DIR}/${CMX_SRCPATH}/Inc"
        "${CMAKE_CURRENT_SOURCE_DIR}/Drivers/CMSIS/Include"
        "${CMAKE_CURRENT_SOURCE_DIR}/Drivers/CMSIS/Device/ST/${CMX_MCUFAM}/Include"
        "${CMAKE_CURRENT_SOURCE_DIR}/Drivers/${CMX_MCUFAM}_HAL_Driver/Inc"
        PARENT_SCOPE
    )

    file(GLOB_RECURSE CMX_SRC
        "${CMAKE_CURRENT_SOURCE_DIR}/Drivers/${CMX_MCUFAM}_HAL_Driver/Src/*.c"
        "${CMAKE_CURRENT_SOURCE_DIR}/${CMX_SRCPATH}/Src/*.c"
        PARENT_SCOPE
    )
    set(CMX_SRC ${CMX_SRC} PARENT_SCOPE)
endfunction()

function(add_startup)
    if ("${CMX_STARTUP}" STREQUAL "")
        # Check if the "Makefile" startupfile is in the source tree
        cmx_get(startupfile_makefile CMX_STARTUPFILE)
        file(GLOB_RECURSE CMX_STARTUP ${CMAKE_CURRENT_SOURCE_DIR} ${CMX_STARTUPFILE})
        if("${CMX_STARTUP}" STREQUAL "")
            # If not, look for the "STM32CubeIDE" startupfile
            cmx_get(startupfile_stm32cubeide CMX_STARTUPFILE)
            file(GLOB_RECURSE CMX_STARTUP ${CMAKE_CURRENT_SOURCE_DIR} ${CMX_STARTUPFILE})
            if("${CMX_STARTUP}" STREQUAL "")
                message(FATAL_ERROR "CubeMX startup file not found!")
            endif()
        endif()
    endif()

    message("Using startup file: ${CMX_STARTUP}")
    list(APPEND CMX_SRC
        "${CMX_STARTUP}"
    )
    set(CMX_SRC ${CMX_SRC} PARENT_SCOPE)
endfunction()

function(add_ldscript)
    if ("${CMX_LDSCRIPT}" STREQUAL "")
        # Check if the "Makefile" linkerscript is in the source tree
        set(LINKERSCRIPT "${CMX_MCUNAME}_FLASH.ld")
        file(GLOB_RECURSE CMX_LDSCRIPT ${CMAKE_CURRENT_SOURCE_DIR} ${LINKERSCRIPT})
        if("${CMX_LDSCRIPT}" STREQUAL "")
            # If not, look for the "STM32CubeIDE" linkerscript
            string(REPLACE "x" "X" LINKERSCRIPT ${LINKERSCRIPT})
            file(GLOB_RECURSE CMX_LDSCRIPT ${CMAKE_CURRENT_SOURCE_DIR} ${LINKERSCRIPT})
            if("${CMX_LDSCRIPT}" STREQUAL "")
                message(FATAL_ERROR "CubeMX linkerscript not found!")
            endif()
        endif()
    endif()
    message("Using linkerscript: ${CMX_LDSCRIPT}")
    set(CMX_LDSCRIPT ${CMX_LDSCRIPT} PARENT_SCOPE)
endfunction()

function(cubemx_target)
    set(ONE_VAL_ARGS TARGET IOC STARTUP LDSCRIPT)
    cmake_parse_arguments(CMX "" "${ONE_VAL_ARGS}" "" ${ARGN})

    ########################################
    # Determine MCU & source/include paths #
    ########################################

    cmx_get(mcuname CMX_MCUNAME)
    cmx_get(mcufamily CMX_MCUFAM)
    cmx_get(srcpath CMX_SRCPATH)

    add_default_sources()
    add_startup()
    add_ldscript()

    ########################################
    # Set up flashing & debugging          #
    ########################################

    if(NOT DEFINED CMX_DEBUGGER)
        set(CMX_DEBUGGER "stlink")
    endif()
    include(${CUBEMXCMK_DIR}/${CMX_DEBUGGER}/flash-target.cmake)
    include(${CUBEMXCMK_DIR}/${CMX_DEBUGGER}/vscode-debug.cmake)

    ########################################
    # Set up compiler / linker options     #
    ########################################

    cmx_get(mcuflags CMX_MCUFLAGS)
    cmx_get(cdefs CMX_CDEFS)

    target_compile_options(${CMX_TARGET} PRIVATE ${CMX_MCUFLAGS})
    target_compile_options(${CMX_TARGET} PRIVATE -ffunction-sections -fdata-sections)
    target_compile_definitions(${CMX_TARGET} PRIVATE ${CMX_CDEFS})
    target_link_options(${CMX_TARGET} PUBLIC ${CMX_MCUFLAGS})
    target_link_options(${CMX_TARGET} PRIVATE "-T${CMX_LDSCRIPT}")
    target_link_options(${CMX_TARGET} PRIVATE
        -Wl,--gc-sections
        --specs=nano.specs
    )
    target_link_libraries(${CMX_TARGET} c m nosys)
    target_sources(${CMX_TARGET} PRIVATE ${CMX_SRC})
    target_include_directories(${CMX_TARGET} PRIVATE ${CMX_INC})
    target_link_options(${CMX_TARGET} PRIVATE -Xlinker --print-memory-usage)

    mcu_image_utils(${CMX_TARGET})
    flash_target(${CMX_TARGET})
    vscode_debug(${CMX_TARGET})
endfunction()
