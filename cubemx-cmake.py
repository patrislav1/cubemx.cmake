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
        "STM32G0": "cortex-m0plus",
        "STM32G4": "cortex-m4",
        "STM32H7": "cortex-m7",
        "STM32L0": "cortex-m0",
        "STM32L1": "cortex-m3",
        "STM32L4": "cortex-m4",  # L4+ included
        "STM32L5": "cortex-m33",
        "STM32U5": "cortex-m33",
        "STM32WL": "cortex-m4",  # Assume we build for app. processor (M4),
        "STM32WB": "cortex-m4",  # not for the radio coprocessor (M0)
    }
    for key, value in coreTable.items():
        if mcuName.startswith(key):
            return value


def getFpu(mcuName):
    # TODO in case of m7 core, check if it has single or double precision fpu
    fpuTable = {
        "cortex-m0": None,
        "cortex-m0plus": None,
        "cortex-m3": None,
        "cortex-m4": "fpv4-sp-d16",
        "cortex-m33": "fpv5-sp-d16",
        "cortex-m7": "fpv5-d16"
    }
    return fpuTable[getCore(mcuName)]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Minimalist CubeMX .ioc project parser")
    parser.add_argument("iocFile", help="CubeMX .ioc project file")
    parser.add_argument("key", nargs="?", default=None,
                        help="Dump value of key")
    parser.add_argument("-d", "--dump", action="store_true",
                        help="Dump all parsed values")
    args = parser.parse_args()

    try:
        iocConf = loadIOC(args.iocFile)
    except FileNotFoundError as e:
        print(f"Couldn't load IOC file: {e}", file=sys.stderr)
        sys.exit(-1)

    mcuFamily = iocConf["Mcu.Family"]

    core = getCore(mcuFamily)
    fpu = getFpu(mcuFamily)
    mcuFlags = [
        f"-mcpu={core}",
        "-mthumb",
        "-mfloat-abi=hard" if fpu is not None else "-mfloat-abi=soft"
    ]
    if fpu is not None:
        mcuFlags += [f"-mfpu={fpu}"]

    mcuLine = iocConf["Mcu.UserName"][0:9] + "xx"
    cdefs = [mcuLine]
    for key in "HSE", "HSI", "LSI":
        iocKey = 'RCC.' + key + '_VALUE'
        if iocKey in iocConf:
            cdefs.append(f"{key}_VALUE={iocConf[iocKey]}")

    cmakeConf = {
        "mcuname": iocConf["Mcu.UserName"],
        "mcufamily": mcuFamily + "xx",
        "mculine": mcuLine,
        "core": core,
        "fpu": fpu,
        "mcuflags": ";".join(mcuFlags),
        "startupfile_makefile": "startup_" + mcuLine.lower() + ".s",
        "startupfile_stm32cubeide": "startup_" + iocConf["Mcu.UserName"].lower() + ".s",
        "cdefs": ";".join([f"-D{cdef}" for cdef in cdefs]),
        "srcpath": os.path.dirname(iocConf["ProjectManager.MainLocation"]),
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
