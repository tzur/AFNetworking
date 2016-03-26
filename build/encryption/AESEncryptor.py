# Copyright (c) 2012 Lightricks. All rights reserved.
# Created by Yaron Inger.

import Crypto.Cipher.AES
import PKCS7Encoder
import argparse


class AESEncryptorException(Exception):
    pass


class AESEncryptor(object):
    """Encrypts data using AES, block size 128, key size 256, PKCS7 message padding."""

    def __init__(self, key):
        if len(key) != 32:
            raise AESEncryptorException("Key size must be 32")

        self.key = key
        self.encoder = PKCS7Encoder.PKCS7Encoder()

    def encrypt_file(self, input_file_name):
        """Encrypts a given file, returns cipher text."""
        try:
            input_text = file(input_file_name, "rb").read()
        except IOError:
            raise AESEncryptorException("Cannot open input file: %s" % input_file_name)

        return self.encrypt_contents(input_text)

    def encrypt_contents(self, input_text):
        """Encrypts a given input text, returns cipher text."""
        padded_text = self.encoder.encode(input_text)

        # Recreate encryptor to reset IV.
        encryptor = Crypto.Cipher.AES.new(self.key, Crypto.Cipher.AES.MODE_CBC, '\x00' * 16)
        return encryptor.encrypt(padded_text)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="AES Encryptor")
    parser.add_argument("--infile", type=str, required=True, help="path of input file to encrypt")
    parser.add_argument("--outfile", type=str, required=True, help="path of encrypted output file")
    parser.add_argument('--key', type=str, required=True, help="key used for encryption")

    args = parser.parse_args()

    aes_encryptor = AESEncryptor(args.key)
    cipher_text = aes_encryptor.encrypt_file(args.infile)
    file(args.outfile, "wb").write(cipher_text)
