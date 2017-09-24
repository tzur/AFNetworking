// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

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

/// Defines a spec that is not going to run, by inheriting from \c NSObject and not from \c SPTSpec.
#define FakeSpecBegin(name) \
  @interface name##Spec : NSObject \
  @end \
  @implementation name##Spec \
    - (void)fake { \

#define FakeSpecEnd \
    } \
  @end

/// Defines specs that are valid only on simulator or device, accordingly.
#if !TARGET_OS_SIMULATOR && TARGET_OS_IPHONE
  #define DeviceSpecBegin(name) SpecBegin(name)
  #define DeviceSpecEnd SpecEnd
  #define SimulatorSpecBegin(name) FakeSpecBegin(name)
  #define SimulatorSpecEnd FakeSpecEnd
#elif TARGET_OS_SIMULATOR
  #define DeviceSpecBegin(name) FakeSpecBegin(name)
  #define DeviceSpecEnd FakeSpecEnd
  #define SimulatorSpecBegin(name) SpecBegin(name)
  #define SimulatorSpecEnd SpecEnd
#endif

/// Executes the given test if running on the simulator.
void sit(NSString *name, id block);

/// Executes the given test if running on the device.
void dit(NSString *name, id block);

/// Defines a context for executing tests if running on the simulator.
void scontext(NSString *name, id block);

/// Defines a context for executing tests if running on the device.
void dcontext(NSString *name, id block);

#define _LTTemporaryPath(...) \
  metamacro_if_eq(1, metamacro_argcount(__VA_ARGS__)) \
  (_LTTemporaryPath1(0, @""))(_LTTemporaryPath1(__VA_ARGS__))

#define _LTTemporaryPath1(unused, relativePath, ...) \
  [[NSTemporaryDirectory() \
    stringByAppendingPathComponent:[[@__FILE__ lastPathComponent] stringByDeletingPathExtension]] \
    stringByAppendingPathComponent:relativePath]

NS_ASSUME_NONNULL_END
