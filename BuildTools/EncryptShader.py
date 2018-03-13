#!/usr/bin/env python

# Copyright (c) 2012 Lightricks. All rights reserved.
# Created by Yaron Inger.

import io
import json
import os
import sys
import time

from encryption import XorEncryptor
from Shader import Shader
from Shader import ShaderParseException
import Utils

RC_FAILED_PROCESSING = 1

def main(argv):
    if len(argv) != 4:
        print("Usage: %s <key> <shader file name> <output directory>" %
              os.path.basename(argv[0]))
        sys.exit()

    key, shader_file_name, output_directory = argv[1:]

    try:
        encryptor = ShaderEncryptor(key, shader_file_name)
        encryptor.write_to(output_directory)
    except ShaderParseException:
        sys.exit(RC_FAILED_PROCESSING)

def file_name_to_script_dir(file_name):
    """Converts base file name to a file name inside the script directory."""
    return os.path.join(os.path.dirname(sys.argv[0]), file_name)

def escape_string(s):
    """Escapes the given string and wraps it with quotes."""
    return json.dumps(s)

class ShaderEncryptor(object):
    # pylint: disable=too-many-instance-attributes

    H_TEMPLATE_FILE = "ShaderTemplate.h"
    M_TEMPLATE_FILE = "ShaderTemplate.m"

    CATEGORY_BASE_CLASS_NAME = "LTShaderStorage"

    def __init__(self, key, shader_file_name):
        """Initializes with an encryption key and a plaintext shader source file name."""
        self.__key = key
        self.__shader_file_name = shader_file_name

        self.__shader = None
        self.__buffer = None
        self.__getter_declaration = None
        self.__getter_implementation = None
        self.__capitalized_objc_name = None
        self.__filled_templates = None
        self.__uniforms_declarations = None
        self.__uniforms_implementations = None
        self.__attributes_declarations = None
        self.__attributes_implementations = None

        self.__process_shader()

    def __process_shader(self):
        encryptor = XorEncryptor.XorEncryptor(self.__key)

        # Load shader and pre-process it.
        self.__shader = Shader(self.__shader_file_name)

        # Prepare template values.
        encrypted_contents = encryptor.encrypt_contents(self.__shader.contents.encode("utf-8"))

        # Create C buffers.
        self.__capitalized_objc_name = self.__shader.objc_file_name(capitalized=True)
        self.__buffer = Utils.string_to_buffer(self.__capitalized_objc_name, encrypted_contents)

        # Generates declaration and implementation for source getter.
        self.__getter_declaration, self.__getter_implementation = \
            ShaderEncryptor.__generate_source_getter(self.__capitalized_objc_name)

        # Generates declaration and implementation for attributes and uniforms getters.
        self.__uniforms_declarations, self.__uniforms_implementations = \
            self.__generate_uniforms_getters()
        self.__attributes_declarations, self.__attributes_implementations = \
            self.__generate_attributes_getters()

        # Create .h and .m templates.
        self.__filled_templates = self.__fill_templates()

    def __fill_templates(self):
        templates = {
            self.M_TEMPLATE_FILE: ShaderEncryptor.__read_template_file__(
                file_name_to_script_dir(self.M_TEMPLATE_FILE)
            ),
            self.H_TEMPLATE_FILE: ShaderEncryptor.__read_template_file__(
                file_name_to_script_dir(self.H_TEMPLATE_FILE)
            )
        }

        variables = {
            "CONTAINER_CLASS_NAME": ShaderEncryptor.CATEGORY_BASE_CLASS_NAME,
            "SHADER_OBJC_NAME": self.__capitalized_objc_name,
            "YEAR": time.localtime().tm_year,
            "SCRIPT_NAME": os.path.basename(sys.argv[0]),
            "IMPORT_FILE": self.__import_file(),
            "BUFFER": self.__buffer,
            "GETTER_DECLARATION": self.__getter_declaration,
            "GETTER_IMPLEMENTATION": self.__getter_implementation,
            "ATTRIBUTES_DECLARATION": "\n".join(self.__attributes_declarations),
            "ATTRIBUTES_IMPLEMENTATION": "\n\n".join(self.__attributes_implementations),
            "UNIFORMS_DECLARATION": "\n".join(self.__uniforms_declarations),
            "UNIFORMS_IMPLEMENTATION": "\n\n".join(self.__uniforms_implementations)
        }

        for name in templates:
            for key, value in variables.items():
                templates[name] = templates[name].replace("@%s@" % key, str(value))

        return templates

    @staticmethod
    def __read_template_file__(file_path):
        with io.open(file_path, "r", encoding="utf-8") as template_file:
            return template_file.read()

    def __generate_uniforms_getters(self):
        return ShaderEncryptor.__generate_variables_getters(self.__shader.uniforms)

    def __generate_attributes_getters(self):
        return ShaderEncryptor.__generate_variables_getters(self.__shader.attributes)

    @staticmethod
    def __generate_variables_getters(variables):
        declarations = []
        implementations = []

        for variable in variables:
            declaration, implementation =\
                ShaderEncryptor.__generate_variable_getter(variable, variable)
            declarations.append(declaration)
            implementations.append(implementation)

        return declarations, implementations

    @staticmethod
    def __generate_source_getter(buffer_name):
        """Generates declaration and implementation of getter for the shader's source."""
        implementation = ["+ (NSString *)source {",
                          ("  return [LTShaderStorage shaderWithBuffer:(void *)k%s\n" +
                           "                                  ofLength:sizeof(k%s) / " +
                           "sizeof(unsigned char)];")
                          % (buffer_name, buffer_name), "}"]

        declaration = "+ (NSString *)source;"

        return declaration, "\n".join(implementation)

    @staticmethod
    def __generate_variable_getter(method_name, value):
        """Generates declaration and implementation of getters for uniforms and attributes."""
        implementation = ["+ (NSString *)%s {" % method_name,
                          "  return @%s;" % escape_string(value),
                          "}"]

        declaration = "+ (NSString *)%s;" % method_name

        return declaration, "\n".join(implementation)

    @staticmethod
    def __import_file():
        if os.environ["PROJECT_NAME"].startswith("LTEngine"):
            return "\"LTShaderStorage.h\""
        return "<LTEngine/LTShaderStorage.h>"

    def write_to(self, output_directory):
        try:
            os.makedirs(output_directory)
        except os.error:
            pass

        print(output_directory)

        h_file_path = "%s+%s.h" % (self.CATEGORY_BASE_CLASS_NAME, self.__capitalized_objc_name)
        m_file_path = "%s+%s.m" % (self.CATEGORY_BASE_CLASS_NAME, self.__capitalized_objc_name)
        with io.open(os.path.join(output_directory, h_file_path), "w", encoding="utf-8") as h_file:
            h_file.write(self.__filled_templates[self.H_TEMPLATE_FILE])
        with io.open(os.path.join(output_directory, m_file_path), "w", encoding="utf-8") as m_file:
            m_file.write(self.__filled_templates[self.M_TEMPLATE_FILE])


if __name__ == "__main__":
    main(sys.argv)
