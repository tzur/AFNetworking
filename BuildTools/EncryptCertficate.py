#!/usr/bin/env python

# Copyright (c) 2016 Lightricks. All rights reserved.
# Created by Daniel Lahyani.

import io
import json
import os
import sys
import time

from encryption import XorEncryptor
import Utils

def main(argv):
    if len(argv) != 5:
        print("Usage: %s <key> <certificate file name> <project prefix> <output directory>" %
              os.path.basename(argv[0]))
        sys.exit(-1)

    key, certificate_file_name, project_prefix, output_directory = argv[1:]
    encryptor = CertificateEncryptor(key, os.path.abspath(certificate_file_name), project_prefix)
    encryptor.write_to(output_directory)

def file_name_to_script_dir(file_name):
    """Converts base file name to a file name inside the script directory."""
    return os.path.join(os.path.dirname(sys.argv[0]), file_name)

def escape_string(s):
    """Escapes the given string and wraps it with quotes."""
    return json.dumps(s)

class CertificateEncryptor(object):
    """
    Encryptor used to encrypt certificate files and generate Objective-C source files that provides
    simple interface to decrypt and use the certificate data as a simple buffer.
    """
    # pylint: disable=too-many-instance-attributes

    H_TEMPLATE_FILE = "CertificateTemplate.h"
    M_TEMPLATE_FILE = "CertificateTemplate.mm"

    def __init__(self, key, certificate_file_name, project_prefix):
        """
        Initializes with an encryption key and a certificate file name. Project prefix will be used
        as a prefix for the name of the certificate data accessor.
        """
        self.__key = key
        self.__certificate_file_name = certificate_file_name
        self.__certificate_name = os.path.splitext(os.path.basename(certificate_file_name))[0]
        self.__project_prefix = project_prefix.upper()

        self.__buffer = None
        self.__getter_declaration = None
        self.__getter_implementation = None
        self.__capitalized_objc_name = None
        self.__filled_templates = None

        self.__process_certificate()

    def __process_certificate(self):
        # Encrypt certificate contents.
        encryptor = XorEncryptor.XorEncryptor(self.__key)
        encrypted_contents = encryptor.encrypt_contents(self.__certificate_contents())

        # Create C buffers.
        buffer_name = "%sBuffer" % self.__certificate_name
        self.__buffer = Utils.string_to_buffer(buffer_name, encrypted_contents)

        # Fill the .h and .m templates.
        self.__filled_templates = self.__fill_templates()

    def __certificate_contents(self):
        with io.open(self.__certificate_file_name, "rb") as certificate_file:
            return certificate_file.read()

    def __fill_templates(self):
        templates = {
            self.M_TEMPLATE_FILE: CertificateEncryptor.__read_template_file(
                file_name_to_script_dir(self.M_TEMPLATE_FILE)
            ),
            self.H_TEMPLATE_FILE: CertificateEncryptor.__read_template_file(
                file_name_to_script_dir(self.H_TEMPLATE_FILE)
            )
        }

        variables = {
            "ENCRYPTION_KEY": escape_string(self.__key),
            "CERTIFICATE_NAME": self.__certificate_name,
            "CERTIFICATE_BUFFER": self.__buffer,
            "PROJECT_PREFIX": self.__project_prefix,
            "YEAR": time.localtime().tm_year,
            "SCRIPT_NAME": os.path.basename(sys.argv[0])
        }

        for name in templates:
            for key, value in variables.items():
                templates[name] = templates[name].replace("@%s@" % key, str(value))

        return templates

    @staticmethod
    def __read_template_file(file_path):
        with io.open(file_path, "r", encoding="utf-8") as template_file:
            return template_file.read()

    def write_to(self, output_directory):
        try:
            os.makedirs(output_directory)
        except os.error:
            pass

        output_base_name = "%s%sCert" % (self.__project_prefix, self.__certificate_name)
        h_file_name = "%s.h" % (output_base_name)
        m_file_name = "%s.mm" % (output_base_name)
        with io.open(os.path.join(output_directory, h_file_name), "w", encoding="utf-8") as h_file:
            h_file.write(self.__filled_templates[self.H_TEMPLATE_FILE])
        with io.open(os.path.join(output_directory, m_file_name), "w", encoding="utf-8") as m_file:
            m_file.write(self.__filled_templates[self.M_TEMPLATE_FILE])


if __name__ == "__main__":
    main(sys.argv)
