# Copyright (c) 2012 Lightricks. All rights reserved.
# Created by Yaron Inger.

import os
import re


class ShaderParseException(Exception):
    pass


class Shader(object):
    def __init__(self, filename):
        self.__basedir = os.path.dirname(filename)
        self.__basename = os.path.basename(filename)
        self._contents = file(filename, "rb").read()
        self.__strip_comments()

    def __strip_comments(self):
        """Removes comments, empty lines and trailing spaces in code."""
        code_without_comments = re.sub("//.*", "", self.contents)
        self.contents = "".join(
            [line.strip() for line in code_without_comments.split("\n") if len(line.strip())])

    @property
    def contents(self):
        """Returns the contents of this shader after processing."""
        return self._contents

    @contents.setter
    def contents(self, value):
        self._contents = value

    @property
    def uniforms(self):
        after_uniform = re.findall(r"uniform\s+(.*?);", self.contents, re.M)
        return [uniform.split()[-1].strip() for uniform in after_uniform]

    @property
    def attributes(self):
        after_attribute = re.findall(r"attribute\s+(.*?);", self.contents, re.M)
        return [attr.split()[-1].strip() for attr in after_attribute]

    def objc_file_name(self, capitalized=False):
        """Converts file name to Objective-C name, such as /usr/bin/FooBar.txt to fooBarTxt."""
        variable_name = re.sub("\\.(\\w)", lambda x: x.group(1).upper(), self.__basename)
        if capitalized:
            return variable_name
        return re.sub("^([A-Z][a-z])", lambda x: x.group(1).lower(), variable_name)
