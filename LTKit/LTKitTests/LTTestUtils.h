// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Returns an absolute path to the given file name. The path depends on the specific spec currently
/// running, so there's no concern for files overwriting each other. If no argument is given, the
/// directory itself is returned.
#define LTTemporaryPath(...) _LTTemporaryPath(0, ##__VA_ARGS__)

/// Returns \c YES if the given \c relativePath to the spec temporary base directory exists.
#define LTFileExistsInTemporaryPath(relativePath) \
  [[NSFileManager defaultManager] fileExistsAtPath:LTTemporaryPath(relativePath)]

/// Creates the temporary directory specific to the currently running spec. If the file already
/// exists, the call has no effect.
#define LTCreateTemporaryDirectory() \
  [[NSFileManager defaultManager] createDirectoryAtPath:LTTemporaryPath() \
                            withIntermediateDirectories:YES \
                                             attributes:nil error:nil]

/// Executes the given test if running on the simulator.
void sit(NSString *name, id block);

/// Executes the given test if running on the device.
void dit(NSString *name, id block);

/// Returns \c YES if currently running application tests (and not logic tests).
BOOL LTRunningApplicationTests();

#define _LTTemporaryPath(...) \
  metamacro_if_eq(1, metamacro_argcount(__VA_ARGS__)) \
  (_LTTemporaryPath1(0, @""))(_LTTemporaryPath1(__VA_ARGS__))

#define _LTTemporaryPath1(unused, relativePath, ...) \
  [[NSTemporaryDirectory() \
    stringByAppendingPathComponent:[[@__FILE__ lastPathComponent] stringByDeletingPathExtension]] \
    stringByAppendingPathComponent:relativePath]
