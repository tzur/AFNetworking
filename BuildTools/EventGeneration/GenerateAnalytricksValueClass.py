# Copyright (c) 2017 Lightricks. All rights reserved.
# Created by Boris Talesnik.

import os
import sys

from OBJCObject import OBJCParseException
from GenerateValueClass import ValueClassGenerator


RC_FAILED_PROCESSING = 1


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print ("Usage: %s <event file name> <output directory> " %
               os.path.basename(sys.argv[0]))
        sys.exit()

    event_file_name, output_directory = sys.argv[1:]

    try:
        generator = ValueClassGenerator(event_file_name, ["event"])
        generator.write_to(output_directory)
    except OBJCParseException:
        sys.exit(RC_FAILED_PROCESSING)
