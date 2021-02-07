#!/usr/bin/python3

import argparse
import os
import sys

def loadIOC(filename):
    conf = {}
    with open(filename) as f:
        while True:
            line = f.readline().strip()
            if not line:
                break
            if line[0] == '#':
                continue
            vals = line.split('=', 2)
            if len(vals) < 2:
                continue
            conf[vals[0]] = vals[1]
    return conf


def getCore(mcuName):
    coreTable = {
        "STM32F0": "cortex-m0",
        "STM32F1": "cortex-m3",
        "STM32F2": "cortex-m3",
        "STM32F3": "cortex-m4",
        "STM32F4": "cortex-m4",
        "STM32F7": "cortex-m7",
        "STM32H7": "cortex-m7",
        "STM32L0": "cortex-m0",
        "STM32L1": "cortex-m3",
        "STM32L4": "cortex-m4",
    }
    for key, value in coreTable.items():
        if mcuName.startswith(key):
            return value


def getFpu(mcuName):
    # TODO in case of m7 core, check if it has single or double precision fpu
    fpuTable = {
        "cortex-m0": None,
        "cortex-m3": None,
        "cortex-m4": "fpv4-sp-d16",
        "cortex-m7": "fpv5-d16"
    }
    for key, value in fpuTable.items():
        if getCore(mcuName) == key:
            return value

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Minimalist CubeMX .ioc project parser")
    parser.add_argument("iocFile", help="CubeMX .ioc project file")
    parser.add_argument("key", nargs="?", default=None, help="Dump value of key")
    parser.add_argument("-d", "--dump", action="store_true", help="Dump all parsed values")
    args = parser.parse_args()

    iocConf = loadIOC(args.iocFile)

    mcuFamily = iocConf["Mcu.Family"]

    core = getCore(mcuFamily)
    fpu = getFpu(mcuFamily)
    mcuFlags = [
        f"-mcpu={core}",
        f"-mfpu={fpu}",
        "-mthumb",
        "-mfloat-abi=hard" if fpu is not None else "-mfloat-abi=soft"
    ]

    mcuLine = iocConf["Mcu.UserName"][0:9] + "xx"
    cdefs = [
        "USE_FULL_LL_DRIVER",
        f"HSE_VALUE={iocConf['RCC.HSE_VALUE']}",
        f"HSI_VALUE={iocConf['RCC.HSI_VALUE']}",
        f"LSI_VALUE={iocConf['RCC.LSI_VALUE']}",
        mcuLine
    ]

    cmakeConf = {
        "mcuname": iocConf["Mcu.UserName"],
        "mcufamily": mcuFamily + "xx",
        "mculine": mcuLine,
        "core": core,
        "fpu": fpu,
        "mcuflags": ";".join(mcuFlags),
        "startupfile": "startup_" + mcuLine.lower() + ".s",
        "cdefs": ";".join([f"-D{cdef}" for cdef in cdefs]),
        "prjname": iocConf["ProjectManager.ProjectName"]
    }

    if args.key:
        if args.key not in cmakeConf:
            print(f"{args.key} not in CMake config", file=sys.stderr)
            sys.exit(-1)
        print(cmakeConf[args.key])

    if args.dump:
        for k, v in cmakeConf.items():
            print(f"{k}: {v}")
