# cubemx.cmake

This is a collection of lightweight CMake and Python scripts that can build STM32 CubeMX projects with CMake and set up VSCode for editing/building/debugging.

It is a more lightweight / modular replacement of [ioc2cmake](https://github.com/patrislav1/ioc2cmake), taking advantage of VSCode CMake tools, avoiding the need to pass compiler flags / include paths etc directly to VSCode.

## Features

* Parses CubeMX .ioc project file
* Determines compile / link flags & linker script from project file
* Adds relevant CubeMX / CMSIS sources & include paths to CMake target
* Creates make targets `flash`, `erase`, `reset` using `pyocd`
* Creates VSCode `launch.json` for debugging with `pyocd`

## How to use

* Create a project with CubeMX
* Generate source code
* Copy the `cmake` folder to the project directory
* Create a `CMakeLists.txt` from the `CMakeLists-example.txt`

## How to build a project on the command line

```
mkdir build && cd build && cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/arm-gcc.cmake .. && make
```

## How to build a project in VSCode

* Make sure the CMake tools are installed.
* Point VSCode to the CMake toolchain file in the project directory:
```
mkdir -p .vscode && echo '[{ "name": "arm-gcc from CMake Toolchain", "toolchainFile": "${workspaceRoot}/cmake/arm-gcc.cmake" }]' > .vscode/cmake-kits.json
```
* Start VSCode and select the kit "arm-gcc from CMake Toolchain"
