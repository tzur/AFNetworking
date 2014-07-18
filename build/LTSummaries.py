# Copyright (c) 2014 Lightricks. All rights reserved.
# Created by Amit Goldstein.

# Add descriptive summaries for the lldb debug area for GLKVectors and LTBoundedTypes.
# To automatically load this file, create a file named ~/.lldbinit with the following line:
# command script import <path of this file>/LTSummaries.py

import lldb
import struct


def GLKVector3_Summary(value, unused):
  return '(%s, %s, %s)' % (value.GetChildMemberWithName('x').value, 
    value.GetChildMemberWithName('y').value, value.GetChildMemberWithName('z').value)


def GLKVector4_Summary(value, unused):
  # Due to a probable bug, the struct alignment of GLKVector4 is ignored, so we have to realign it
  # ourselves, read the memory and return it.
  address = value.address_of
  alignedAddress = align_to(address.load_addr, 16)
  process = lldb.debugger.GetSelectedTarget().GetProcess()
  error = lldb.SBError()
  data = process.ReadMemory(alignedAddress, 16, error)
  if not error.Success():
    return 'Error reading memory: %s' % error

  float_data = struct.unpack('f' * 4, data)
  return float_data


def align_to(address, alignment):
  if not address % alignment:
    return address
  else:
    return address + alignment - address % alignment


def LTBoundedValue_Summary(value, unused):
  return value.GetChildMemberWithName('_value').value


def LTBoundedVector_Summary(value, unused):
  return value.GetChildMemberWithName('_value').summary


def __lldb_init_module(debugger, dictionary):
  debugger.HandleCommand('type summary add GLKVector3 -F LTSummaries.GLKVector3_Summary')
  debugger.HandleCommand('type summary add GLKVector4 -F LTSummaries.GLKVector4_Summary')
  debugger.HandleCommand('type summary add LTBoundedCGFloat -F LTSummaries.LTBoundedValue_Summary')
  debugger.HandleCommand('type summary add LTBoundedDouble -F LTSummaries.LTBoundedValue_Summary')
  debugger.HandleCommand('type summary add LTBoundedInteger -F LTSummaries.LTBoundedValue_Summary')
  debugger.HandleCommand('type summary add LTBoundedUInteger -F \
    LTSummaries.LTBoundedValue_Summary')
  debugger.HandleCommand('type summary add LTBoundedGLKVector3 -F \
    LTSummaries.LTBoundedVector_Summary')
  debugger.HandleCommand('type summary add LTBoundedGLKVector4 -F \
    LTSummaries.LTBoundedVector_Summary')
