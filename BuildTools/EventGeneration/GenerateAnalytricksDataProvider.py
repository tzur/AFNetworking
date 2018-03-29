# Copyright (c) 2017 Lightricks. All rights reserved.
# Created by Boris Talesnik.

import io
import os
import sys
import time
import re

from OBJCObject import OBJCObject
from OBJCObject import OBJCParseException
import ClassGenerator

RC_FAILED_PROCESSING = 1

def main(argv):
    if len(argv) != 4:
        print("Usage: %s <event file name> <shared events folder> "
              "<output directory>" % os.path.basename(argv[0]))
        sys.exit()

    filename, shared_folder, output_directory = argv[1:]

    try:
        generator = AnalytricksRawEventGenerator(filename, os.path.realpath(shared_folder))
        generator.write_to(output_directory)
    except OBJCParseException:
        sys.exit(RC_FAILED_PROCESSING)

def file_name_to_script_dir(file_name):
    """Converts base file name to a file name inside the script directory."""
    return os.path.join(os.path.dirname(sys.argv[0]), file_name)


class AnalytricksRawEventGenerator(object):
    H_TEMPLATE_FILE = "AnalytricksDataProviderTemplate.h.template"
    M_TEMPLATE_FILE = "AnalytricksDataProviderTemplate.mm.template"

    def __init__(self, event_file_name, shared_events_folder):
        """Initializes with an encryption key and a plaintext shader source file name."""
        self.__event_file_name = event_file_name
        self.__basename = os.path.basename(event_file_name)
        self.__shared_events_folder = shared_events_folder
        self.__event = None
        self.__initializer_declarations = None
        self.__initializer_implementations = None
        self.__filled_templates = None

        self.__process_event()

    @property
    def analytricks_base_objc_name(self):
        key = list(self.__event.custom_object_properties)[0]
        custom_property = self.__event.custom_object_properties[key]
        objc_object = custom_property[1]
        return objc_object.objc_class_name(True)

    @property
    def base_file_import(self):
        schema_file_path = list(self.__event.custom_object_properties)[0]
        schema_base = os.path.splitext(os.path.basename(schema_file_path))[0]
        if self.__shared_events_folder in schema_file_path \
                and self.__shared_events_folder not in os.path.realpath(self.__event_file_name):
            import_file = "<Intelligence/{}.h>"
        else:
            import_file = "\"{}.h\""
        return import_file.format(schema_base)

    @property
    def event_name(self):
        ANALYTRICS = "Analytricks"
        start_index = self.objc_file_name.index(ANALYTRICS) + len(ANALYTRICS)
        stripped_name = self.objc_file_name[start_index:]
        stripped_name = re.sub("(.)([A-Z][a-z]+)", r"\1_\2", stripped_name)
        return re.sub("([a-z0-9])([A-Z])", r"\1_\2", stripped_name).lower()

    @property
    def properties_declarations(self):
        return ClassGenerator.generate_property_declarations(self.__event.properties)

    @property
    def json_assignments(self):
        return ClassGenerator\
            .generate_object_properties_dictionary_assignments(self.__event.properties)

    @property
    def objc_file_name(self):
        return os.path.splitext(self.__basename)[0]

    def __process_event(self):
        # Load event json and pre-process it.
        self.__event = OBJCObject(self.__event_file_name)

        # Generates declaration and implementation for initializers.
        self.__initializer_declarations, self.__initializer_implementations = \
            AnalytricksRawEventGenerator.__generate_initializers(self.__event.properties)

        # Create .h and .m templates.
        self.__filled_templates = self.__fill_templates()

    def __fill_templates(self):
        templates = {
            self.M_TEMPLATE_FILE: AnalytricksRawEventGenerator.__read_template_file(
                file_name_to_script_dir(self.M_TEMPLATE_FILE)
            ),
            self.H_TEMPLATE_FILE: AnalytricksRawEventGenerator.__read_template_file(
                file_name_to_script_dir(self.H_TEMPLATE_FILE)
            )
        }

        variables = {
            "EVENT_OBJC_NAME": self.__event.objc_class_name(capitalized=True),
            "EVENT_DOC": ClassGenerator.generate_indented_doc(self.__event.description),
            "YEAR": time.localtime().tm_year,
            "SCRIPT_NAME": os.path.basename(sys.argv[0]),
            "INITIALIZER_DECLARATIONS": "\n\n".join(self.__initializer_declarations),
            "INITIALIZER_IMPLEMENTATIONS": "\n\n".join(self.__initializer_implementations),
            "PROPERTIES_DECLARATION": "\n\n".join(self.properties_declarations),
            "ANALYTRICKS_BASE_FILE": self.base_file_import,
            "EVENT_NAME": self.event_name,
            "EVENT_FILE_NAME": self.objc_file_name,
            "ANALYTRICKS_BASE_OBJC_NAME": self.analytricks_base_objc_name,
            "JSON_ASSIGNMENTS": ",\n    ".join(self.json_assignments),
            "JSON_FILE_NAME": self.__basename
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

    def write_to(self, output_dir):
        try:
            os.makedirs(output_dir)
        except os.error:
            pass

        h_file_path = self.objc_file_name + ".h"
        m_file_path = self.objc_file_name + ".mm"
        with io.open(os.path.join(output_dir, h_file_path), "w", encoding="utf-8") as h_file:
            h_file.write(self.__filled_templates[self.H_TEMPLATE_FILE])
        with io.open(os.path.join(output_dir, m_file_path), "w", encoding="utf-8") as m_file:
            m_file.write(self.__filled_templates[self.M_TEMPLATE_FILE])


if __name__ == "__main__":
    main(sys.argv)
