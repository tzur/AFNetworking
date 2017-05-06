# Copyright (c) 2017 Lightricks. All rights reserved.
# Created by Boris Talesnik.

import re

from textwrap import TextWrapper
from OBJCObject import OBJCProperty


def upper_first(string):
    return string[0].upper() + string[1:] if string else string


def generate_object_properties_dictionary_assignments(objc_properties):
    """Generates argument strings as used in objective-c"""
    return ["@\"{0}\": {1}".format(objc_property.json_name,
                                   generate_to_json_transformation(objc_property, "self"))
            for objc_property in objc_properties]


def generate_to_json_transformation(objc_property, object_owner):
    """{0} is the owner of an object, {1} is the object name"""
    foundations_to_json_transforms = {
        "NSNumber *": "{0}{1}",
        "NSUInteger": "@({0}{1})",
        "BOOL": "@({0}{1})",
        "NSDate *": "[[NSDateFormatter lt_UTCDateFormatter] stringFromDate:{0}{1}]",
        "NSUUID *": "[{0}{1} UUIDString]",
        "NSString *": "{0}{1}",
        "NSArray *": "{0}{1}",
    }

    if "NSArray<" in objc_property.objc_type:
        inner_class = re.sub(r'^(\w*<)|(>\s\*)$', "", objc_property.objc_type)
        inner_objc_property = OBJCProperty("object", inner_class, "", "object")
        transform = "[{0}{1} " + "lt_map:^({} object)".format(inner_class) + "{{return " + \
                    generate_to_json_transformation(inner_objc_property, "") + ";}}]"
    elif objc_property.objc_type not in foundations_to_json_transforms:
        transform = "[{0}{1} json]"
    else:
        transform = foundations_to_json_transforms[objc_property.objc_type]

    object_owner_string = object_owner + ("." if object_owner else "")

    return transform.format(object_owner_string, objc_property.objc_name) + \
           (' ?: [NSNull null]' if objc_property.nullable else "")


def generate_method_declaration_string(method_prefix, arguments, return_type, declaration_flag,
                                       doc=None):
    argument_strings = generate_method_argument_strings(arguments)
    declaration_parts = [generate_indented_method_name(method_prefix, argument_strings,
                                                       return_type, declaration_flag + ";")]
    if doc is not None:
        declaration_parts.insert(0, generate_indented_doc(doc))
    return "\n".join(declaration_parts)


def generate_method_argument_strings(objc_properties):
    """Generates argument strings as used in objective-c"""
    return [generate_method_argument_string(objc_property.objc_name, objc_property.objc_type,
                                            objc_property.nullable)
            for objc_property in objc_properties]


def generate_method_argument_string(name, argument_type, nullable=False):
    """Generates argument strings as used in objective-c"""
    return "{0}:({1}){0}".format(name, merge_nullable_type(argument_type, nullable))


def merge_nullable_type(objc_type, nullable):
    return ("nullable " if nullable else "") + objc_type


def generate_value_initializer_declaration_string(objc_properties):
    return generate_method_declaration_string("initWith", objc_properties, "instancetype",
                                              "NS_DESIGNATED_INITIALIZER",
                                              "Initializes with the given arguments.")


def generate_indented_doc(doc):
    text_wrapper = TextWrapper(100, break_long_words=False)
    text_wrapper.subsequent_indent = "/// "
    text_wrapper.initial_indent = "/// "

    lines = text_wrapper.wrap(doc)
    return "\n".join(lines)


def generate_value_initializer_implementation_string(objc_properties):
    body = generate_value_initializer_body_string(objc_properties)
    return generate_method_implementation_string("initWith", objc_properties, "instancetype", body)


def generate_value_initializer_body_string(objc_properties):
    assignments = ["    _{0} = {0};".format(objc_property.objc_name)
                   for objc_property in objc_properties]
    return "\n".join(["  if (self = [super init]) {"] + assignments + ["  }", "  return self;"])


def generate_method_implementation_string(method_prefix, arguments, return_type, body):
    argument_strings = generate_method_argument_strings(arguments)
    method_name = generate_indented_method_name(method_prefix, argument_strings, return_type, "{")
    return "\n".join([method_name, body, "}"])


def generate_indented_method_name(method_prefix, argument_strings, return_type, suffix):
    return_string = re.sub("\\s\\(", "_(", "- ({}){}".format(return_type, method_prefix))
    connected_arguments = [re.sub("\\s\\*", "_*", argument) for argument in argument_strings]
    arguments_string = upper_first(" ".join(connected_arguments))

    full_name = return_string + arguments_string + " " + suffix
    text_wrapper = TextWrapper(100, break_long_words=False)
    text_wrapper.subsequent_indent = "    "
    wrapped = text_wrapper.wrap(full_name)

    return "\n".join(wrapped).replace("_(", " (").replace("_*", " *")


def generate_property_declarations(objc_properties):
    properties = []
    for objc_property in objc_properties:
        property_types = generate_property_arguments_string(True, True, False,
                                                            objc_property.nullable)

        property_declaration = "@property {} {} {};".format(property_types, objc_property.objc_type,
                                                            objc_property.objc_name)
        property_declaration = "\n".join([
            generate_indented_doc(objc_property.description),
            re.sub(r'\*\s', "*", property_declaration)
        ])
        properties.append(property_declaration)

    return properties


def generate_property_arguments_string(readonly=True, strong=True, atomic=False, nullable=False):
    types = []
    if readonly:
        types.append("readonly")
    elif strong:
        types.append("strong")

    types.append("atomic" if atomic else "nonatomic")
    if nullable:
        types.append("nullable")

    return "({})".format(", ".join(types))


def generate_class_forward_declaration_string(objc_properties):
    if not objc_properties:
        return ""

    classes = [re.sub(r'\s\*', "", objc_property.objc_type) for objc_property in objc_properties]

    return "@class {};".format(" ,".join(classes))
