# Copyright (c) 2017 Lightricks. All rights reserved.
# Created by Boris Talesnik.

import io
import os
import sys
import time

from OBJCObject import OBJCObject
from OBJCObject import OBJCParseException
import ClassGenerator

RC_FAILED_PROCESSING = 1

def main(argv):
    if len(argv) != 3:
        print("Usage: %s <event file name> <output directory> " %
              os.path.basename(argv[0]))
        sys.exit()

    filename, output_dir = argv[1:3]

    try:
        generator = ValueClassGenerator(filename)
        generator.write_to(output_dir)
    except OBJCParseException:
        sys.exit(RC_FAILED_PROCESSING)

def file_name_to_script_dir(file_name):
    """Converts base file name to a file name inside the script directory."""
    return os.path.join(os.path.dirname(sys.argv[0]), file_name)


class ValueClassGenerator(object):
    # pylint: disable=too-many-instance-attributes

    H_TEMPLATE_FILE = "ValueClassTemplate.h.template"
    M_TEMPLATE_FILE = "ValueClassTemplate.mm.template"

    def __init__(self, event_file_name, excluded_properties=None):
        """Initializes with an encryption key and a plaintext shader source file name."""
        self.__event_file_name = event_file_name
        self.__basename = os.path.basename(event_file_name)
        self.__excluded_properties = excluded_properties
        self.__event = None
        self.__initializer_declarations = None
        self.__initializer_implementations = None
        self.__properties_declarations = None
        self.__objc_file_name = None
        self.__json_assignments = None
        self.__filled_templates = None

        self.__process_event()

    @property
    def properties(self):
        if self.__excluded_properties is None:
            return self.__event.properties

        return [prop for prop in self.__event.properties
                if prop.json_name not in self.__excluded_properties]


    def __process_event(self):
        # Load event json and pre-process it.
        self.__event = OBJCObject(self.__event_file_name)

        self.__objc_file_name = os.path.splitext(self.__basename)[0]


        # Generates declaration and implementation for initializers.
        self.__initializer_declarations, self.__initializer_implementations = \
            ValueClassGenerator.__generate_initializers(self.properties)

        self.__properties_declarations = \
            ClassGenerator.generate_property_declarations(self.properties)

        self.__json_assignments = ClassGenerator.generate_object_properties_dictionary_assignments(
            self.properties)

        # Create .h and .m templates.
        self.__filled_templates = self.__fill_templates()

    def __fill_templates(self):
        templates = {
            self.M_TEMPLATE_FILE: ValueClassGenerator.__read_template_file(
                file_name_to_script_dir(self.M_TEMPLATE_FILE)
            ),
            self.H_TEMPLATE_FILE: ValueClassGenerator.__read_template_file(
                file_name_to_script_dir(self.H_TEMPLATE_FILE)
            )
        }

        self.__initializer_declarations, self.__initializer_implementations = \
            ValueClassGenerator.__generate_initializers(self.properties)

        initializer_declarations = ValueClassGenerator\
            .__add_newlines_to_string("\n\n".join(self.__initializer_declarations))

        properties_declaration = ValueClassGenerator\
            .__add_newlines_to_string("\n\n".join(self.__properties_declarations))

        initializer_implementations = ValueClassGenerator\
            .__add_newlines_to_string("\n\n".join(self.__initializer_implementations))
        variables = {
            "CLASS_OBJC_NAME": self.__event.objc_class_name(capitalized=True),
            "CLASS_DOC": ClassGenerator.generate_indented_doc(self.__event.description),
            "YEAR": time.localtime().tm_year,
            "SCRIPT_NAME": os.path.basename(sys.argv[0]),
            "INITIALIZER_DECLARATIONS": initializer_declarations,
            "PROPERTIES_DECLARATION": properties_declaration,
            "CLASS_HEADER_FILE_NAME": self.__objc_file_name,
            "INITIALIZER_IMPLEMENTATIONS": initializer_implementations,
            "JSON_SERIALIZABLE_PROTOCOL_HEADER":
                ValueClassGenerator.__json_provider_protocol_import_file(),
            "JSON_FILE_NAME": self.__basename,
            "JSON_ASSIGNMENTS": ",\n    ".join(self.__json_assignments)
        }

        for name in templates:
            for key, value in variables.items():
                templates[name] = templates[name].replace("@%s@" % key, str(value))

        return templates

    @staticmethod
    def __read_template_file(file_path):
        with io.open(file_path, "r", encoding="utf-8") as template_file:
            return template_file.read()

    @staticmethod
    def __add_newlines_to_string(string):
        return "\n" + string + "\n" if string else string

    @staticmethod
    def __generate_initializers(objc_properties):
        if not objc_properties:
            return [], []

        declarations = [
            ClassGenerator.generate_method_declaration_string("init", [], "instancetype",
                                                              "NS_UNAVAILABLE"),
            ClassGenerator.generate_value_initializer_declaration_string(objc_properties)
        ]
        implementations = \
            [ClassGenerator.generate_value_initializer_implementation_string(objc_properties)]

        return declarations, implementations

    @staticmethod
    def __json_provider_protocol_import_file():
        return "<Intelligence/INTJSONSerializable.h>"

    def write_to(self, output_directory):
        try:
            os.makedirs(output_directory)
        except os.error:
            pass

        h_file_path = self.__objc_file_name + ".h"
        m_file_path = self.__objc_file_name + ".mm"
        with io.open(os.path.join(output_directory, h_file_path), "w", encoding="utf-8") as h_file:
            h_file.write(self.__filled_templates[self.H_TEMPLATE_FILE])
        with io.open(os.path.join(output_directory, m_file_path), "w", encoding="utf-8") as m_file:
            m_file.write(self.__filled_templates[self.M_TEMPLATE_FILE])


if __name__ == "__main__":
    main(sys.argv)
