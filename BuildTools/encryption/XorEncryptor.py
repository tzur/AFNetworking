# Copyright (c) 2013 Lightricks. All rights reserved.
# Created by Yaron Inger.

import argparse


class XorEncryptorException(Exception):
    pass


class XorEncryptor(object):
    """Encrypts data using a rolling xor key."""

    def __init__(self, key):
        self.key = key

    def encrypt_file(self, input_file_name):
        """Encrypts a given file, returns cipher text."""
        try:
            input_text = open(input_file_name, "rb").read()
        except IOError:
            raise XorEncryptorException("Cannot open input file: %s" % input_file_name)

        return self.encrypt_contents(input_text)

    def encrypt_contents(self, input_text):
        """Encrypts a given input text, returns cipher text."""
        encrypted_text = []
        key_index = 0
        key_length = len(self.key)

        for byte in bytearray(list(input_text)):
            encrypted_text.append(chr(byte ^ ord(self.key[key_index])))
            key_index = (key_index + 1) % key_length

        return "".join(encrypted_text)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Xor Encryptor")
    parser.add_argument("--infile", type=str, required=True, help="path of input file to encrypt")
    parser.add_argument("--outfile", type=str, required=True, help="path of encrypted output file")
    parser.add_argument("--key", type=str, required=True, help="key used for encryption")

    args = parser.parse_args()

    encryptor = XorEncryptor(args.key)
    cipherText = encryptor.encrypt_file(args.infile)
    open(args.outfile, "wb").write(cipherText)
