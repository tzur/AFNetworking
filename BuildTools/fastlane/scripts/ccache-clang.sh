#!/bin/sh
# Copyright (c) 2017 Lightricks. All rights reserved.
# Created by Barak Weiss.

if type -p ccache >/dev/null 2>&1; then
  export CCACHE_CPP2=true
  export CCACHE_SLOPPINESS=pch_defines,time_macros,file_macro,include_file_mtime,include_file_ctime,\
file_stat_matches
  exec ccache clang "$@"
else
  exec clang "$@"
fi
