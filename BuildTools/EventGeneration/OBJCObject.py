# Copyright (c) 2017 Lightricks. All rights reserved.
# Created by Boris Talesnik.

import os
import json
import re

JSON_NUMBER_TO_OBJC_TYPES = {
    "number": "NSNumber *",
    "boolean": "BOOL",
    "integer": "NSUInteger"
}

UUID_REGEX = "^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$"
DATE_TIME_FORMAT = "date-time"

JSON_KEY_DESCRIPTION = "description"
JSON_KEY_TYPE = "type"
JSON_KEY_PROPERTIES = "properties"
JSON_KEY_FORMAT = "format"
JSON_KEY_PATTERS = "pattern"
JSON_KEY_ITEMS = "items"
JSON_KEY_ADDITIONAL_PROPERTIES = "additionalProperties"
JSON_KEY_REQUIRED = "required"


class OBJCParseException(Exception):
    pass


class OBJCProperty(object):
    def __init__(self, objc_name, objc_type, description, json_name, nullable=False):
        self.__objc_name = objc_name
        self.__objc_type = objc_type
        self.__description = description
        self.__json_name = json_name
        self.__nullable = nullable

    @property
    def objc_name(self):
        return self.__objc_name

    @property
    def json_name(self):
        return self.__json_name

    @property
    def objc_type(self):
        return self.__objc_type

    @property
    def description(self):
        return self.__description

    @property
    def nullable(self):
        return self.__nullable


class OBJCObject(object):
    def __init__(self, filename):
        self.__basedir = os.path.dirname(filename)
        self.__basename = os.path.basename(filename)
        with open(filename) as schema_file:
            self.__schema = json.load(schema_file)

        self.__properties, self.__custom_object_properties = \
            OBJCObject.__parse_properties(self.__schema, self.__basedir)

    @property
    def description(self):
        return self.__schema[JSON_KEY_DESCRIPTION] + "."

    @property
    def properties(self):
        return self.__properties

    @property
    def custom_object_properties(self):
        return self.__custom_object_properties

    @staticmethod
    def __parse_properties(schema, schema_base_dir):
        if "allOf" in schema:
            return OBJCObject.__parse_composition_object_property(schema["allOf"], schema_base_dir)
        return OBJCObject.__parse_foundations_type_properties(schema), {}

    @staticmethod
    def __parse_foundations_type_properties(json_obj):
        if JSON_KEY_PROPERTIES not in json_obj or JSON_KEY_REQUIRED not in json_obj:
            return []

        required_properties = json_obj[JSON_KEY_REQUIRED]
        properties = json_obj[JSON_KEY_PROPERTIES]
        return [OBJCObject.__parse_objc_property(properties[key], key) for key
                in required_properties]

    @staticmethod
    def __parse_composition_object_property(all_of_array, schema_base_dir):
        properties = []
        custom_properties = {}
        for json_object in all_of_array:
            if "$ref" in json_object:
                filename = os.path.realpath(os.path.join(schema_base_dir, json_object["$ref"]))
                raw_property_name = os.path.splitext(os.path.basename(filename))[0]
                custom_properties[filename] = \
                    (OBJCObject.__parse_property_name(raw_property_name), OBJCObject(filename))
            else:
                properties += OBJCObject.__parse_foundations_type_properties(json_object)
        return properties, custom_properties

    @staticmethod
    def __parse_objc_property(json_property, property_name):
        objc_name = OBJCObject.__parse_property_name(property_name)
        objc_type, nullable = OBJCObject.__parse_objc_property_type(json_property)
        description = json_property[JSON_KEY_DESCRIPTION] + "."

        return OBJCProperty(objc_name, objc_type, description, property_name, nullable)

    @staticmethod
    def __parse_objc_property_type(json_property):
        json_type, nullable = OBJCObject.__extract_property_type(json_property)
        if json_type == "string":
            objc_type = OBJCObject.__parse_string_property_type(json_property)
        elif json_type == "array":
            objc_type = OBJCObject.__parse_array_property_type(json_property)
        elif json_type == "object":
            objc_type = OBJCObject.__parse_object_property_type(json_property)
        else:
            objc_type = OBJCObject.parse_number_property_type(json_type, nullable)

        return objc_type, nullable

    @staticmethod
    def __parse_property_name(name):
        objc_name = re.sub("(?!^)_([a-zA-Z0-9])", lambda m: m.group(1).upper(), name)
        objc_name = re.sub("^(\\d+)", lambda m: "", objc_name)
        objc_name = re.sub("(?!^)[.]([a-z]+)", lambda m: "", objc_name)
        return re.sub("Id", "ID", objc_name)

    @staticmethod
    def __extract_property_type(json_property):
        nullable = False
        property_type = json_property[JSON_KEY_TYPE]
        if isinstance(property_type, list):
            for key in property_type:
                if key == "null":
                    nullable = True
                else:
                    json_type = key
        else:
            json_type = property_type

        return json_type, nullable

    @staticmethod
    def __parse_string_property_type(json_property):
        if JSON_KEY_FORMAT in json_property and json_property[JSON_KEY_FORMAT] == DATE_TIME_FORMAT:
            return "NSDate *"
        if JSON_KEY_PATTERS in json_property and json_property[JSON_KEY_PATTERS] == UUID_REGEX:
            return "NSUUID *"

        return "NSString *"

    @staticmethod
    def __parse_array_property_type(json_property):
        if JSON_KEY_ITEMS in json_property:
            objc_type, _ = OBJCObject.__parse_objc_property_type(json_property[JSON_KEY_ITEMS])
            return "NSArray<{}> *".format(objc_type)

        return "NSArray *"

    @staticmethod
    def __parse_object_property_type(json_property):
        if JSON_KEY_ADDITIONAL_PROPERTIES in json_property:
            objc_type, _ = \
                OBJCObject.__parse_objc_property_type(json_property[JSON_KEY_ADDITIONAL_PROPERTIES])
            return "NSDictionary<NSString *, {}> *".format(objc_type)

        return "NSDictionary<NSString *, id> *"

    @staticmethod
    def parse_number_property_type(json_type, nullable):
        if nullable:
            return "NSNumber *"
        return JSON_NUMBER_TO_OBJC_TYPES[json_type]

    def objc_class_name(self, capitalized=False):
        """Converts file name to Objective-C name, such as /usr/bin/foo_bar.json to FooBar."""
        variable_name = os.path.splitext(self.__basename)[0]
        variable_name = re.sub("[_]([a-zA-Z])", lambda m: m.group(1).upper(), variable_name)
        variable_name = re.sub("([_](\\d+))|([.]([a-zA-Z]+))", lambda m: "", variable_name)
        variable_name = re.sub("Id", "ID", variable_name)
        if not capitalized:
            return variable_name
        return re.sub("^([a-z])", lambda x: x.group(1).upper(), variable_name)
