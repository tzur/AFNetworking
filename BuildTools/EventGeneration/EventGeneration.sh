#!/bin/bash

# Copyright (c) 2017 Lightricks. All rights reserved.
# Created by Boris Talesnik.

# EventGeneration - A script to produce Objective-C event classes from json files.

build_tool_folder="$1"

shared_events_folder="$2"

if [[ "$INPUT_FILE_PATH" == *"AbstractEvents/"*Analytricks*.json ]]; then
  python "$build_tool_folder/EventGeneration/GenerateAnalytricksEvent.py" \
  "$INPUT_FILE_PATH" "$shared_events_folder" "$DERIVED_FILE_DIR/$arch" || exit $?
fi

if [[ "$INPUT_FILE_PATH" == *"ConcreteEvents/"*Analytricks*.json ]]; then
  python "$build_tool_folder/../BuildTools/EventGeneration/GenerateAnalytricksDataProvider.py" \
  "$INPUT_FILE_PATH" "$shared_events_folder" "$DERIVED_FILE_DIR/$arch" || exit $?
fi

if [[ "$INPUT_FILE_PATH" == *"Common/"*Analytricks*.json ]]; then
  python "$build_tool_folder/../BuildTools/EventGeneration/GenerateAnalytricksValueClass.py" \
  "$INPUT_FILE_PATH" "$DERIVED_FILE_DIR/$arch" || exit $?
fi

if [[ "$INPUT_FILE_PATH" == *"Event.json"* ]]; then
  python "$build_tool_folder/../BuildTools/EventGeneration/GenerateValueClass.py" \
  "$INPUT_FILE_PATH" "$DERIVED_FILE_DIR/$arch" || exit $?
fi
