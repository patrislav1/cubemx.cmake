#!/usr/bin/env python3

from pyocd.__main__ import PyOCDTool
import sys

# Workaround wrapper for these cortex-debug issues:
# https://github.com/Marus/cortex-debug/issues/351
# https://github.com/Marus/cortex-debug/issues/322
#
# Add 'gdbserver' arg and remove '--persist'

args = ['gdbserver'] + [arg for arg in sys.argv[1:] if arg != '--persist']

sys.exit(PyOCDTool().run(args=args))
