#!/usr/bin/env python2
# Copyright (c) 2017 Lightricks. All rights reserved.
# Created by Barak Weiss.

import argparse
import re
import subprocess
import sys
from distutils.version import LooseVersion
from subprocess import PIPE, STDOUT


def execute(command):
    """
    Shell executes the given command.
    Returns Tuple (status, stdout)
    """
    process = subprocess.Popen(command, stdout=PIPE, stderr=STDOUT, shell=True)
    stdout, _ = process.communicate()
    status = process.poll()
    return status, stdout


def get_all_devices():
    """
    Returns all devices connected to the system.
    """
    _, stdout = execute("instruments -s devices")

    # Typical output of the "instruments -s devices" command looks like this:
    # Known Devices:
    # BarakW-iMac [C1B7F7BB-6107-5CF4-A842-57A876726A1D]
    # LT iPhone +7 #041 (11.0) [79b734b475969a1407933bfe56b5c8e48443a557]
    # Video Team's iPod (10.3.3) [cf38a670139ccdb03a9196aac6feaba07abb1511]
    # LT iPadMini #002 (10.3.2) [1adf61b4f91a3b09dfb5776ca3e6dbd8c2c58c2d]
    # Apple TV (11.1) [F7DEE09A-2459-4EDD-8866-0AACF41BE865] (Simulator)
    # Apple Watch - 42mm (4.1) [A770C466-8D11-40B7-9EDE-282F2C2FFDD9] (Simulator)
    # iPad (5th generation) (10.3.1) [D699C0B3-5E85-4194-81CF-7FDA6EDEB9B0] (Simulator)
    # iPad Air (11.1) [98371DA3-2026-4F55-ADFE-187BDF6DB5D7] (Simulator)
    # iPhone 7 (11.1) + Apple Watch Series 2 - 38mm (4.1) [ECA63649-AD0C-410A-B9F7-0...] (Simulator)
    # iPhone 7 Plus (10.3.1) [3EFEBF14-B3ED-4D95-AAD6-89509156986A] (Simulator)
    # iPhone 7 Plus (11.1) + Apple Watch Series 2 - 42mm (4.1) [44E076F6-34BD-44E5-B...] (Simulator)
    device_regex = \
        r"(.*?) \(([\d\.]*)\) (\+ Apple Watch.*?\(([\d\.]*)\))?.*?\[(.*?)\]( \+)?( \(Simulator\))?"
    matches = re.finditer(device_regex, stdout.decode("utf-8"))

    devices = []
    for _, match in enumerate(matches):
        d = {
            "name": match.group(1),
            "ios_version": LooseVersion(match.group(2)),
            "watchos_version": LooseVersion(match.group(4)) if match.group(4) else None,
            "uuid": match.group(5),
            "is_simulator": match.group(7) is not None
        }
        devices.append(d)

    return devices


def query_devices(ios_major_version, include_simulators):
    """
    Queries for devices with ios_major_version. Includes simulators if include_simulators os True.
    """

    devices = get_all_devices()
    devices = [d for d in devices if include_simulators or not d["is_simulator"]]
    if ios_major_version:
        devices = [d for d in devices if d["ios_version"].version[0] == ios_major_version]
    return devices


def create_parser():
    parser = argparse.ArgumentParser(description="Query connected iOS devices and returns the ID "
                                                 "of the first device that satisfied the query")
    parser.add_argument("--ios-ver", type=int, help="Query for devices with the specified iOS"
                                                    "major version")
    parser.add_argument("--simulator", action="store_true", help="Include simulators in query")
    return parser

def main():
    args = create_parser().parse_args()
    result = query_devices(args.ios_ver, args.simulator)
    if not result:
        print("No connected devices matched given parameters")
        sys.exit(-1)

    print(result[0]["uuid"])

if __name__ == "__main__":
    main()
