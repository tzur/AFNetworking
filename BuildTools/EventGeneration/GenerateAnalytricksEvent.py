# Copyright (c) 2017 Lightricks. All rights reserved.
# Created by Boris Talesnik.

import io
import os
import sys
import time

from OBJCObject import OBJCObject
from OBJCObject import OBJCProperty
from OBJCObject import OBJCParseException

import ClassGenerator

RC_FAILED_PROCESSING = 1

def main(argv):
    if len(argv) != 4:
        print("Usage: %s <event file name> <shared events folder> <output directory>" %
              os.path.basename(argv[0]))
        sys.exit()

    filename, shared_folder, output_directory = argv[1:]

    try:
        generator = AnalytricksEventGenerator(filename, shared_folder)
        generator.write_to(output_directory)
    except OBJCParseException:
        sys.exit(RC_FAILED_PROCESSING)

def file_name_to_script_dir(file_name):
    """Converts base file name to a file name inside the script directory."""
    return os.path.join(os.path.dirname(sys.argv[0]), file_name)


class AnalytricksEventGenerator(object):
    H_TEMPLATE_FILE = "AnalytricksEventTemplate.h.template"
    M_TEMPLATE_FILE = "AnalytricksEventTemplate.mm.template"

    def __init__(self, event_file_name, shared_events_folder):
        """Initializes with an encryption key and a plaintext shader source file name."""
        self.__event_file_name = event_file_name
        self.__basename = os.path.basename(event_file_name)
        self.__shared_events_folder = shared_events_folder
        self.__event = None
        self.__initializer_declarations = None
        self.__initializer_implementations = None

        self.__process_event()

    @property
    def custom_type_properties(self):
        properties = []
        for schema_file_path, custom_property in self.__event.custom_object_properties.items():
            if os.path.basename(schema_file_path) == "base.intelligence.json":
                continue
            property_name = custom_property[0]
            objc_object = custom_property[1]
            property_class = objc_object.objc_class_name(True) + " *"
            properties.append(OBJCProperty(property_name, property_class, objc_object.description,
                                           False))

        properties.sort(key=lambda x: x.objc_name)

        return properties

    @property
    def json_providers(self):
        return ["self." + objc_property.objc_name for objc_property in self.custom_type_properties]

    @property
    def custom_type_properties_imports(self):
        imports = []
        for schema_file_path in self.__event.custom_object_properties:
            if os.path.basename(schema_file_path) == "base.intelligence.json":
                continue
            schema_base = os.path.splitext(os.path.basename(schema_file_path))[0]
            if self.__shared_events_folder in schema_file_path \
                    and self.__shared_events_folder not in os.path.realpath(self.__event_file_name):
                import_file = "#import <Intelligence/{}.h>"
            else:
                import_file = "#import \"{}.h\""
            imports.append(import_file.format(schema_base))
        return imports

    @property
    def objc_file_name(self):
        return os.path.splitext(self.__basename)[0]

    @property
    def properties_declarations(self):
        return ClassGenerator.generate_property_declarations(self.all_properties)

    @property
    def all_properties(self):
        return self.custom_type_properties + self.__event.properties

    @property
    def class_forward_declaration(self):
        return ClassGenerator.generate_class_forward_declaration_string(self.custom_type_properties)

    @property
    def initializer_arguments(self):
        return ClassGenerator.generate_method_argument_strings(self.all_properties)

    @property
    def properties_assignment(self):
        return ["    _{0} = {0};".format(objc_property.objc_name) for objc_property
                in self.all_properties]

    @property
    def json_assignments(self):
        return ClassGenerator\
            .generate_object_properties_dictionary_assignments(self.__event.properties)

    def __process_event(self):
        # Load event json and pre-process it.
        self.__event = OBJCObject(self.__event_file_name)

        # Create .h and .m templates.
        self.__filled_templates = self.__fill_templates()

    def __fill_templates(self):
        templates = {
            self.M_TEMPLATE_FILE: AnalytricksEventGenerator.__read_template_file(
                file_name_to_script_dir(self.M_TEMPLATE_FILE)
            ),
            self.H_TEMPLATE_FILE: AnalytricksEventGenerator.__read_template_file(
                file_name_to_script_dir(self.H_TEMPLATE_FILE)
            )
        }

        variables = {
            "EVENT_OBJC_NAME": self.__event.objc_class_name(capitalized=True),
            "EVENT_DOC": ClassGenerator.generate_indented_doc(self.__event.description),
            "YEAR": time.localtime().tm_year,
            "SCRIPT_NAME": os.path.basename(sys.argv[0]),
            "PROPERTIES_DECLARATION": "\n\n".join(self.properties_declarations),
            "ANALYTRICKS_FILE_IMPORT":
                AnalytricksEventGenerator.__analytricks_protocol_import_file(),
            "CUSTOM_CLASS_DECLARATION": "" if self.class_forward_declaration == ""
            else "\n" + self.class_forward_declaration + "\n",
            "EVENT_FILE_NAME": self.objc_file_name,
            "INITIALIZER_ARGUMENTS": " ".join(self.initializer_arguments),
            "PROPERTIES_ASSIGNMENT": "\n".join(self.properties_assignment),
            "JSON_PROVIDERS": " ,".join(self.json_providers),
            "JSON_ASSIGNMENTS": ",\n    ".join(self.json_assignments),
            "JSON_SERIALIZABLE_IMPORTS": "\n".join(self.custom_type_properties_imports),
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

    def write_to(self, output_directory):
        try:
            os.makedirs(output_directory)
        except os.error:
            pass

        h_file_path = self.objc_file_name + ".h"
        m_file_path = self.objc_file_name + ".mm"
        with io.open(os.path.join(output_directory, h_file_path), "w", encoding="utf-8") as h_file:
            h_file.write(self.__filled_templates[self.H_TEMPLATE_FILE])
        with io.open(os.path.join(output_directory, m_file_path), "w", encoding="utf-8") as m_file:
            m_file.write(self.__filled_templates[self.M_TEMPLATE_FILE])

    @staticmethod
    def __analytricks_protocol_import_file():
        return "<Intelligence/INTAnalytricksEvent.h>"


if __name__ == "__main__":
    main(sys.argv)
