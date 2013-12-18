#!/usr/bin/python

# Copyright (c) 2012 Lightricks. All rights reserved.
# Created by Yaron Inger.

import os
import re
import sys
import time

import XorEncryptor

HEX_ITEMS_PER_LINE = 16

H_TEMPLATE_FILE = "ShaderTemplate.h"
M_TEMPLATE_FILE = "ShaderTemplate.m"

CATEGORY_BASE_CLASS_NAME = "LTShaderStorage"


def string_to_buffer(variable_name, s):
    """Converts a Python string to C buffer declaration."""
    lines = ["static const unsigned char k%s[] = {" % variable_name]

    # Group characters such that each group will appear in a line of source code.
    grouped_chars = [s[i:i + HEX_ITEMS_PER_LINE] for i in xrange(0, len(s), HEX_ITEMS_PER_LINE)]

    # Create lines of code.
    for group in grouped_chars:
        lines.append("  %s," % ", ".join([hex(ord(c)) for c in group]))

    # Remove last ',' from the last line.
    lines[-1] = lines[-1][:-1]

    lines.append("};")

    return "\n".join(lines)


def strip_comments(code):
    """Removes comments, empty lines and trailing spaces in code."""
    code_without_comments = re.sub("//.*", "", code)
    return "\n".join(
        [line.strip() for line in code_without_comments.split("\n") if len(line.strip())])


def file_name_to_script_dir(file_name):
    """Converts base file name to a file name inside the script directory."""
    return os.path.join(os.path.dirname(sys.argv[0]), file_name)


def file_name_to_objc_name(name, capitalized=False):
    """Converts file name to Objective-C name, such as /usr/local/bin/FooBar.txt to fooBarTxt."""
    variable_name = re.sub("\\.(\\w)", lambda x: x.group(1).upper(), os.path.basename(name))
    if capitalized:
        return variable_name
    return re.sub("^([A-Z][a-z])", lambda x: x.group(1).lower(), variable_name)


def fill_templates(buffer, shader_objc_name, getters_declaration, getters_implementation):
    templates = {
        M_TEMPLATE_FILE: file(file_name_to_script_dir(M_TEMPLATE_FILE), "rb").read(),
        H_TEMPLATE_FILE: file(file_name_to_script_dir(H_TEMPLATE_FILE), "rb").read()
    }

    variables = {
        "CONTAINER_CLASS_NAME": CATEGORY_BASE_CLASS_NAME,
        "SHADER_OBJC_NAME": shader_objc_name,
        "YEAR": time.localtime().tm_year,
        "SCRIPT_NAME": os.path.basename(sys.argv[0]),
        "BUFFER": buffer,
        "GETTER_DECLARATION": getters_declaration,
        "GETTER_IMPLEMENTATION": getters_implementation
    }

    for name in templates.iterkeys():
        for key, value in variables.iteritems():
            templates[name] = templates[name].replace("@%s@" % key, str(value))

    return templates


def generate_getter(method_name, buffer_name):
    """Generates declaration of implementation of getters for files' data."""
    implementation = ["+ (NSString *)%s {" % method_name,
                      ("  return [[self class] shaderWithBuffer:(void *)k%s\n" +
                       "                               ofLength:sizeof(k%s) / " +
                       "sizeof(unsigned char)];")
                      % (buffer_name, buffer_name), "}"]

    declaration = "+ (NSString *)%s;" % method_name

    return declaration, "\n".join(implementation)


def save_output(output_directory, shader_objc_name, filled_templates):
    try:
        os.makedirs(output_directory)
    except os.error:
        pass

    h_file_path = "%s+%s.h" % (CATEGORY_BASE_CLASS_NAME, shader_objc_name)
    m_file_path = "%s+%s.m" % (CATEGORY_BASE_CLASS_NAME, shader_objc_name)
    file(os.path.join(output_directory, h_file_path), "wb").write(filled_templates[H_TEMPLATE_FILE])
    file(os.path.join(output_directory, m_file_path), "wb").write(filled_templates[M_TEMPLATE_FILE])


def process_shader(key, shader_file_name, output_directory):
    encryptor = XorEncryptor.XorEncryptor(key)

    # Strip comments from shader.
    contents = strip_comments(file(shader_file_name, "rb").read())

    # Prepare template values.
    encrypted_contents = encryptor.encrypt_contents(contents)

    # Create C buffers.
    lower_objc_name = file_name_to_objc_name(shader_file_name, capitalized=False)
    capitalized_objc_name = file_name_to_objc_name(shader_file_name, capitalized=True)
    buffer = string_to_buffer(capitalized_objc_name, encrypted_contents)

    # Generates getters for declaration and implementation.
    getter_declaration, getter_implementation = generate_getter(lower_objc_name,
                                                                capitalized_objc_name)

    # Create .h and .m templates.
    filled_templates = fill_templates(buffer, capitalized_objc_name, getter_declaration,
                                      getter_implementation)

    save_output(output_directory, capitalized_objc_name, filled_templates)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print ("Usage: %s <key> <shader file name> <output directory>" %
               os.path.basename(sys.argv[0]))
        sys.exit()

    process_shader(*sys.argv[1:])
