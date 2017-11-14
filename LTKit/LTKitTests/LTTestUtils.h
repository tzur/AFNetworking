// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

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

NS_ASSUME_NONNULL_END
