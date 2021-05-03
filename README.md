# cubemx.cmake

This is a collection of lightweight CMake and Python scripts that can build STM32 CubeMX projects with CMake and set up VSCode for editing/building/debugging.

It is a more lightweight / modular replacement of [ioc2cmake](https://github.com/patrislav1/ioc2cmake), taking advantage of VSCode CMake tools, avoiding the need to pass compiler flags / include paths etc directly to VSCode.

## Features

* Parses CubeMX .ioc project file
* Determines compile / link flags & linker script from project file
* Adds relevant CubeMX / CMSIS sources & include paths to CMake target
* Supports flash/debug tools: [stlink](https://github.com/stlink-org/stlink), [pyocd](https://github.com/pyocd/pyOCD), [openocd](https://github.com/ntfreak/openocd)
* Creates make targets `flash`, `erase`, `reset`
* Creates VSCode `launch.json` for debugging

## How to use

* Create a project with CubeMX
* Generate source code. (Select "Project->Toolchain/IDE: Makefile" and "Code Generator->Copy only necessary library files")
* Copy the `cmake` folder to the project directory
* Create a `CMakeLists.txt` from the `CMakeLists-example.txt`
* Make sure `arm-none-eabi-gcc` is in the PATH

## How to build a project on the command line

```
mkdir build && cd build && cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/arm-gcc.cmake .. && make
```

## How to build a project in VSCode

* Make sure the "CMake Tools" extension is installed.
* Point VSCode to the CMake toolchain file in the project directory:
```
mkdir -p .vscode && echo '[{ "name": "arm-gcc from CMake Toolchain", "toolchainFile": "${workspaceRoot}/cmake/arm-gcc.cmake" }]' > .vscode/cmake-kits.json
```
* Start VSCode and select the kit "arm-gcc from CMake Toolchain"

## Caveats

* The list of CubeMX source files is determined by globbing at CMake configuration stage. If it changes (by re-generating the sources with added peripherals, for example) then the CubeMX configuration has to be invoked again (in VSCode: Ctrl-Shift-P & "CMake: Configure" or "Developer: Reload Window")

* Only the sources in `Core` and `Drivers` are added automatically. If there are additional generated sources (e.g. Middlewares), they have to be added manually, for instance:
```
target_include_directories(example_target PRIVATE
    "USB_HOST/App"
    "USB_HOST/Target"
    "Middlewares/ST/STM32_USB_Host_Library/Core/Inc"
    "Middlewares/ST/STM32_USB_Host_Library/Class/CDC/Inc"
)
file(GLOB_RECURSE MIDDLEWARE_SRC
    "USB_HOST/*.c"
    "Middlewares/*.c"
)
target_sources(example_target PRIVATE ${MIDDLEWARE_SRC})
```

* Other user-specific source files (e.g. a dedicated application folder separate from the CubeMX sources) can be added the same way as above

* For most STM32 chips, `pyocd` must be updated with a device pack to recognize the chip, e.g.
```
pyocd pack -i stm32f407vgtx
```

* The current `arm-none-eabi-gdb` from [developer.arm.com](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) is still linked against `libncurses5`, which may not be installed on a recent Linux distribution. (On Ubuntu, install it with `sudo apt install libncurses5`)

## Tested with following chips / boards

* STM32F407VGT (STM32F407G-DISC1)
* STM32L496ZGT (NUCLEO-L496ZG)
* STM32L433RCT (NUCLEO-L433RC-P)
* STM32F767ZIT (NUCLEO-F767ZI)
* STM32H743ZIT (NUCLEO-H743ZI)
