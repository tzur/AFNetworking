# Copyright (c) 2016 Lightricks. All rights reserved.
# Created by Barak Weiss.

"""
Creates new dictionary language .strings files containing translated strings from previously
translated .strings files. If a string was not previously translated, it will be indicated in the
output dictionary file.
"""

import io
import glob
import os
import shutil
import sys
import traceback

def str_to_dict(key_value_str):
    """
    Converts a key value string to a key-value dictionary.

    :param key_value_str: key-value string pair spearated by a = character.
    For example the string '"Albums" = "Albumis;"' will convert to "Albums ": " Albumis;".
    """
    localized_dict = {}
    for line in key_value_str.splitlines():
        fields = line.split("=")
        if len(fields) == 2:
            localized_dict[fields[0]] = fields[1]

    return localized_dict


def write_localization_line(base_localization_line, existing_localization_dict, out_localized_file):
    """
    Writes `base_localization_line` into `out_localized_file`. If the key in the localization line
    is not in `existing_localization_dict` a comment saying that the translation is missing is added
    to end of line. Any non key-value line is copied to `out_localized_file`.

    :param base_localization_line: Localization line from the base file.
    :param existing_localization_dict: Dictionary mapping the original text to its localized
    translation.
    :param out_localized_file: Output file.
    """
    fields = base_localization_line.split("=")
    if len(fields) == 2:
        key, non_localized_value = fields
        if key in existing_localization_dict:
            out_localized_file.write(key + "=" + existing_localization_dict[key] + "\n")
        else:
            out_localized_file.write(key + "=" + non_localized_value +
                                     " /* MISSING TRANSLATION */\n")
    else:
        out_localized_file.write(base_localization_line + "\n")

def localization_dict_from_file(language_path, localized_file_name):
    localized_file_path = os.path.join(language_path, localized_file_name)
    print("Processing " + localized_file_path)
    with io.open(localized_file_path, encoding="utf-8") as source_localized_file:
        localization_dict = str_to_dict(source_localized_file.read())

    return localization_dict

def create_localized_language_for_path(language_path, localized_file_name,
                                       base_localization_file_contents, out_dir):
    """
    Creates a new file out_dir\\language_dir_name\\localized_file_name, which contains all the keys
    (base-language strings) from base_localization_file_contents and values (localized strings) from
    language_path\\localized_file_name strings file.
    Keys that exist in base_localization_file_contents and do not have a translation in the
    localized file, will have a comment stating there's a missing translation for this string.

    :param language_path: Path to the source localization files.
    :param localized_file_name: Name of the output file to write, and the localized file to read.
    :param base_localization_file_contents: Contents of .strings file with the base localization.
    :param out_dir: Output directory to write the file to (inside language_directory).
    """
    language_dir_name = os.path.basename(language_path)
    existing_localization_dict = localization_dict_from_file(language_path, localized_file_name)
    out_language_dir = os.path.join(out_dir, language_dir_name)
    if not os.path.exists(out_language_dir):
        os.makedirs(out_language_dir)
    with io.open(os.path.join(out_language_dir, localized_file_name), "w+",
                 encoding="utf-8") as out_localized_file:
        for base_localization_line in base_localization_file_contents.splitlines():
            write_localization_line(base_localization_line, existing_localization_dict,
                                    out_localized_file)

        out_localized_file.flush()

def create_localization_file_for_each_language(localization_folders_path, base_dir, out_dir):
    """
    Loops over all localization folders (extension ".lproj"). For each folder, updates all the
    .strings files under base_dir with the contents of the file with the same name in the base
    localization folder.
    """
    base_file_paths = os.path.join(base_dir, "*.strings")
    for language_path in glob.glob(localization_folders_path + "/*.lproj"):
        language_dir_name = os.path.basename(language_path)
        if language_dir_name == "Base.lproj" or language_dir_name == "en.lproj":
            continue
        for base_file_path in glob.glob(base_file_paths):
            base_file_name = os.path.basename(base_file_path)
            with io.open(base_file_path, "r", encoding="utf-8") as base_localization_file:
                create_localized_language_for_path(language_path, base_file_name,
                                                   base_localization_file.read(), out_dir)

            shutil.copy(base_file_path, os.path.join(out_dir, "en.lproj"))

def log_exception(exception, filepath):
    print("error: exception in {}: {} message: {}".format(os.path.basename(filepath),
                                                          exception.__doc__,
                                                          exception.message))
    traceback.print_exc(exception)

def main(argv):
    """
    :param argv: should contain:
    project_root_path - Path to the code files that need to be localized.
    base_dir - Directory that contains the base localization file.
    out_dir - Output directory to write the localization files to.
    """
    if len(argv) != 4:
        print("Usage: python " + argv[0] + " project_root_path base_dir out_dir")
        exit()

    project_root_path, base_dir, out_dir = argv[1:4]

    localization_folders_path = os.path.join(project_root_path, base_dir)
    base_dir = os.path.join(base_dir, "Base.lproj")

    if not os.path.exists(os.path.join(out_dir, "en.lproj")):
        os.makedirs(os.path.join(out_dir, "en.lproj"))

    create_localization_file_for_each_language(
        localization_folders_path=localization_folders_path,
        base_dir=base_dir,
        out_dir=out_dir
    )

if __name__ == "__main__":
    try:
        main(sys.argv)
    except Exception as ex:
        log_exception(exception=ex, filepath=__file__)
