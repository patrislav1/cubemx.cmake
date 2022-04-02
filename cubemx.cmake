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

define_property(TARGET PROPERTY TARGET_FILE_BIN
    BRIEF_DOCS "Name of the raw image file"
    FULL_DOCS "This property gives the name of the generated .bin file containing a raw memory image of the linked executable file."
)
define_property(TARGET PROPERTY TARGET_FILE_ELF
    BRIEF_DOCS "Name of the executable file"
    FULL_DOCS "This property gives the name of the generated .elf file containing the compiled executable. This is identical to the TARGET_FILE property."
)
define_property(TARGET PROPERTY TARGET_FILE_LST
    BRIEF_DOCS "Name of the listing file"
    FULL_DOCS "This property gives the name of the generated .lst file containing the mixed source/assembly output for the executable."
)
define_property(TARGET PROPERTY TARGET_FILE_MAP
    BRIEF_DOCS "Name of the symbol map file"
    FULL_DOCS "This property gives the name of the generated .map file containing the mapping of input objects and where they were placed by the linker."
)
define_property(TARGET PROPERTY SOURCE_FILE_STARTUP
    BRIEF_DOCS "Name of the startup code file"
    FULL_DOCS "This property gives the name of the startup code file used to boot the MCU."
)
define_property(TARGET PROPERTY SOURCE_FILE_LDSCRIPT
    BRIEF_DOCS "Name of the linker script file"
    FULL_DOCS "This property gives the name of the linker script file used to place generated code in the final executable image."
)

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
        "${CMX_CUBEMX_CORE_DIR}/${CMX_COREPATH}/Inc"
        "${CMX_CUBEMX_LIB_DIR}/Drivers/CMSIS/Include"
        "${CMX_CUBEMX_LIB_DIR}/Drivers/CMSIS/Device/ST/${CMX_MCUFAM}/Include"
        "${CMX_CUBEMX_LIB_DIR}/Drivers/${CMX_MCUFAM}_HAL_Driver/Inc"
        PARENT_SCOPE
    )

    file(GLOB_RECURSE CMX_SRC
        "${CMX_CUBEMX_CORE_DIR}/${CMX_COREPATH}/Src/*.c"
        "${CMX_CUBEMX_LIB_DIR}/Drivers/${CMX_MCUFAM}_HAL_Driver/Src/*.c"
        PARENT_SCOPE
    )
    set(CMX_SRC ${CMX_SRC} PARENT_SCOPE)
endfunction()

function(add_startup)
    if("${CMX_STARTUP}" STREQUAL "")
        # Check if the "Makefile" startupfile is in the source tree
        cmx_get(startupfile_makefile CMX_STARTUPFILE)
        file(GLOB_RECURSE CMX_STARTUP "${CMX_CUBEMX_CORE_DIR}/${CMX_STARTUPFILE}")
        if("${CMX_STARTUP}" STREQUAL "")
            # If not, look for the "STM32CubeIDE" startupfile
            cmx_get(startupfile_stm32cubeide CMX_STARTUPFILE)
            file(GLOB_RECURSE CMX_STARTUP "${CMX_CUBEMX_CORE_DIR}/${CMX_STARTUPFILE}")
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
    set(CMX_STARTUP ${CMX_STARTUP} PARENT_SCOPE)
endfunction()

function(add_ldscript)
    if("${CMX_LDSCRIPT}" STREQUAL "")
        # Check if the "Makefile" linkerscript is in the source tree
        set(LINKERSCRIPT "${CMX_MCUNAME}_FLASH.ld")
        file(GLOB_RECURSE CMX_LDSCRIPT "${CMX_CUBEMX_CORE_DIR}/${LINKERSCRIPT}")
        if("${CMX_LDSCRIPT}" STREQUAL "")
            # If not, look for the "STM32CubeIDE" linkerscript
            string(REPLACE "x" "X" LINKERSCRIPT ${LINKERSCRIPT})
            file(GLOB_RECURSE CMX_LDSCRIPT "${CMX_CUBEMX_CORE_DIR}/${LINKERSCRIPT}")
            if("${CMX_LDSCRIPT}" STREQUAL "")
                message(FATAL_ERROR "CubeMX linkerscript not found!")
            endif()
        endif()
    endif()

    message("Using linkerscript: ${CMX_LDSCRIPT}")
    set(CMX_LDSCRIPT ${CMX_LDSCRIPT} PARENT_SCOPE)
endfunction()

function(cubemx_target)
    set(ONE_VAL_ARGS
        TARGET
        IOC
        CUBEMX_SOURCE_DIR
        CUBEMX_CORE_DIR
        CUBEMX_LIB_DIR
        STARTUP
        LDSCRIPT
        FLASH_TARGET_NAME
        IMG_ADDR
        ELF2BIN_OPT
        ELF2LST_OPT
    )
    cmake_parse_arguments(CMX "" "${ONE_VAL_ARGS}" "" ${ARGN})

    if("${CMX_TARGET}" STREQUAL "")
        set(CMX_TARGET ${ARGV0})
    endif()

    ########################################
    # Set default values                   #
    ########################################

    if("${CMX_FLASH_TARGET_NAME}" STREQUAL "")
        set(CMX_FLASH_TARGET_NAME flash)
    endif()
    if("${CMX_IMG_ADDR}" STREQUAL "")
        set(CMX_IMG_ADDR 0x08000000)
    endif()
    if("${CMX_CUBEMX_SOURCE_DIR}" STREQUAL "")
        set(CMX_CUBEMX_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()
    if("${CMX_CUBEMX_CORE_DIR}" STREQUAL "")
        set(CMX_CUBEMX_CORE_DIR "${CMX_CUBEMX_SOURCE_DIR}")
    endif()
    if("${CMX_CUBEMX_LIB_DIR}" STREQUAL "")
        set(CMX_CUBEMX_LIB_DIR "${CMX_CUBEMX_SOURCE_DIR}")
    endif()

    ########################################
    # Determine MCU & source/include paths #
    ########################################

    cmx_get(mcuname CMX_MCUNAME)
    cmx_get(mcufamily CMX_MCUFAM)
    cmx_get(corepath CMX_COREPATH)

    add_default_sources()
    add_startup()
    add_ldscript()
    set_property(TARGET ${CMX_TARGET} PROPERTY SOURCE_FILE_STARTUP "${CMX_STARTUP}")
    set_property(TARGET ${CMX_TARGET} PROPERTY SOURCE_FILE_LDSCRIPT "${CMX_LDSCRIPT}")

    ########################################
    # Set up flashing & debugging          #
    ########################################

    if(NOT DEFINED CMX_DEBUGGER)
        set(CMX_DEBUGGER "stlink")
    endif()
    include(${CUBEMXCMK_DIR}/${CMX_DEBUGGER}/flash-target.cmake)
    include(${CUBEMXCMK_DIR}/${CMX_DEBUGGER}/vscode-debug.cmake)
    if(NOT TARGET erase AND NOT TARGET reset)
        # erase and reset targets can only be defined once
        add_erase_and_reset()
    endif()

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

    set_property(TARGET ${CMX_TARGET} PROPERTY TARGET_FILE_ELF "${CMX_TARGET}.elf")

    mcu_image_utils(${CMX_TARGET} "${CMX_ELF2BIN_OPT}" "${CMX_ELF2LST_OPT}")
    flash_target(${CMX_TARGET} ${CMX_FLASH_TARGET_NAME} ${CMX_IMG_ADDR})
    vscode_debug(${CMX_TARGET})
endfunction()
