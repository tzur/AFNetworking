#!/usr/bin/env python

import binascii
import os
import sys

from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes
import lzfse


def main(argv):
    if len(argv) != 4:
        print("Usage: %s <hex key> <input file> <output file>" % os.path.basename(argv[0]))
        sys.exit(1)

    hex_key, input_file, output_file = argv[1:]
    process_file(hex_key, input_file, output_file)

def process_file(key, input_file, output_file):
    """Process the input_file and writes the compressed and encrypted output to output_file."""
    compressed = compress_file(input_file)
    encrypted = encrypt_data(key, compressed)
    open(output_file, "wb").write(encrypted)


def compress_file(filename):
    """Compresses the file using LZFSE."""
    return lzfse.compress(open(filename, "rb").read())


def encrypt_data(hex_key, data):
    """Encrypts the data using AES, block size 128, key size 256, PKCS7 message padding."""
    key = binascii.unhexlify(hex_key)
    assert len(key) == 16, "Key length must be 16, got: %d" % len(key)

    iv = get_random_bytes(AES.block_size)

    return iv + AES.new(key, AES.MODE_CBC, iv).encrypt(pkcs7(data))


def pkcs7(data):
    """Pads the data in PKCS7 to match AES block size."""
    remainder = AES.block_size - len(data) % AES.block_size
    return data + bytes(chr(remainder).encode("utf8")) * remainder


if __name__ == "__main__":
    main(sys.argv)
