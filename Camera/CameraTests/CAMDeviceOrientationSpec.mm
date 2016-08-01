// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CAMDeviceOrientation.h"

#import <CoreMotion/CoreMotion.h>

static const NSTimeInterval kTimeInterval = 1.234;
static const CMAcceleration kGravityPortrait = {.x = 0, .y = -1};
static const CMAcceleration kGravityPortraitUpsideDown = {.x = 0, .y = 1};
static const CMAcceleration kGravityLandscapeLeft = {.x = 1, .y = 0};
static const CMAcceleration kGravityLandscapeRight = {.x = -1, .y = 0};
static const CMAcceleration kGravityFlat = {.x = 0, .y = 0.05, .z = 1};
static NSError * const kError = [NSError lt_errorWithCode:1];

/// Fake object for \c CMMotionManager that exposes methods for sending \c CMDeviceMotion
/// and \c NSError objects as updates to the \c CMDeviceMotionHandler.
@interface CAMFakeMotionManager : CMMotionManager
- (void)updateDeviceMotion:(CMDeviceMotion *)motion;
- (void)sendError:(NSError *)error;
@property (readwrite, nonatomic, getter=isDeviceMotionAvailable) BOOL deviceMotionAvailable;
@property (nonatomic) NSInteger startDeviceMotionUpdatesCallsCount;
@property (nonatomic) NSInteger stopDeviceMotionUpdatesCallsCount;
@property (copy, readonly, nonatomic) CMDeviceMotionHandler handler;
@end

@implementation CAMFakeMotionManager
@synthesize deviceMotionAvailable = _deviceMotionAvailable;
- (void)startDeviceMotionUpdatesToQueue:(NSOperationQueue * __unused)queue
                            withHandler:(CMDeviceMotionHandler)handler {
  _handler = handler;
  ++self.startDeviceMotionUpdatesCallsCount;
}
- (void)updateDeviceMotion:(CMDeviceMotion *)motion {
  self.handler(motion, nil);
}
- (void)sendError:(NSError *)error {
  self.handler(nil, error);
}
- (void)stopDeviceMotionUpdates {
  ++self.stopDeviceMotionUpdatesCallsCount;
}
@end

/// Fake object for \c CAMFakeDeviceMotion that redefines the \c gravity property as \c readwrite.
@interface CAMFakeDeviceMotion : CMDeviceMotion
@property (readwrite, nonatomic) CMAcceleration gravity;
@end

@implementation CAMFakeDeviceMotion
@synthesize gravity = _gravity;
@end

SpecBegin(CAMDeviceOrientation)

__block CAMFakeMotionManager *manager;
__block CAMFakeDeviceMotion *motion;
__block CAMDeviceOrientation *orientation;
__block RACSignal *signal;

beforeEach(^{
  manager = [[CAMFakeMotionManager alloc] init];
  LTBindObjectToClass(manager, [CMMotionManager class]);
  motion = [[CAMFakeDeviceMotion alloc] init];
  manager.deviceMotionAvailable = YES;
  orientation = [[CAMDeviceOrientation alloc] init];
  signal = [orientation deviceOrientationWithRefreshInterval:kTimeInterval];
});

context(@"signal disposal", ^{
  it(@"should stop core motion", ^{
    expect(manager.startDeviceMotionUpdatesCallsCount).to.equal(0);
    [[signal subscribeCompleted:^{}] dispose];
    expect(manager.stopDeviceMotionUpdatesCallsCount).to.equal(1);
  });
});

context(@"signal subscription", ^{
  it(@"should start core motion", ^{
    expect(manager.startDeviceMotionUpdatesCallsCount).to.equal(0);
    LLSignalTestRecorder * __unused recorder = [signal testRecorder];
    expect(manager.startDeviceMotionUpdatesCallsCount).to.equal(1);
  });

  it(@"should set the refresh interval", ^{
    expect(manager.deviceMotionUpdateInterval).toNot.equal(kTimeInterval);
    LLSignalTestRecorder * __unused recorder = [signal testRecorder];
    expect(manager.deviceMotionUpdateInterval).to.equal(kTimeInterval);
  });

  it(@"should send error if the device motion is not available", ^{
    manager.deviceMotionAvailable = NO;
    LLSignalTestRecorder *recorder = [signal testRecorder];

    expect(recorder).to.sendError([NSError lt_errorWithCode:CAMErrorCodeDeviceMotionUnavailable]);
  });
});

context(@"signal", ^{
  it(@"should send error if the CMMotionManager sends an error for device motion update", ^{
    LLSignalTestRecorder *recorder = [signal testRecorder];
    [manager sendError:kError];

    expect(recorder).to.sendError([NSError lt_errorWithCode:CAMErrorCodeDeviceMotionUpdateError
                                            underlyingError:kError]);
  });
  
  it(@"should complete when the CAMDeviceOrientation object is deallocated", ^{
    RACSignal *signal;
    LLSignalTestRecorder *recorder;
    @autoreleasepool {
      CAMDeviceOrientation *orientation = [[CAMDeviceOrientation alloc] init];
      signal = [orientation deviceOrientationWithRefreshInterval:kTimeInterval];
      recorder = [signal testRecorder];
    }

    expect(recorder).to.complete();
  });

  it(@"should send UIInterfaceOrientationPortrait when the device is in portrait state", ^{
    LLSignalTestRecorder *recorder = [signal testRecorder];
    motion.gravity = kGravityPortrait;
    [manager updateDeviceMotion:motion];

    expect(recorder).to.sendValues(@[@(UIInterfaceOrientationPortrait)]);
  });

  it(@"should send UIInterfaceOrientationPortraitUpsideDown when the device is upside down", ^{
    LLSignalTestRecorder *recorder = [signal testRecorder];
    motion.gravity = kGravityPortraitUpsideDown;
    [manager updateDeviceMotion:motion];

    expect(recorder).to.sendValues(@[@(UIInterfaceOrientationPortraitUpsideDown)]);
  });

  it(@"should send UIInterfaceOrientationLandscapeLeft when the device is in left landscape state", ^{
    LLSignalTestRecorder *recorder = [signal testRecorder];
    motion.gravity = kGravityLandscapeLeft;
    [manager updateDeviceMotion:motion];

    expect(recorder).to.sendValues(@[@(UIInterfaceOrientationLandscapeLeft)]);
  });

  it(@"should send UIInterfaceOrientationLandscapeRight when the device is in right landscape state",
     ^{
    LLSignalTestRecorder *recorder = [signal testRecorder];
    motion.gravity = kGravityLandscapeRight;
    [manager updateDeviceMotion:motion];

    expect(recorder).to.sendValues(@[@(UIInterfaceOrientationLandscapeRight)]);
  });

  it(@"should not send the orientation when the orientation doesn't change", ^{
    LLSignalTestRecorder *recorder = [signal testRecorder];
    motion.gravity = kGravityPortrait;
    [manager updateDeviceMotion:motion];
    [manager updateDeviceMotion:motion];
    [manager updateDeviceMotion:motion];

    expect(recorder).to.sendValues(@[@(UIInterfaceOrientationPortrait)]);
  });

  it(@"should send the orientation when the orientation changes", ^{
    LLSignalTestRecorder *recorder = [signal testRecorder];
    motion.gravity = kGravityPortrait;
    [manager updateDeviceMotion:motion];
    motion.gravity = kGravityPortraitUpsideDown;
    [manager updateDeviceMotion:motion];
    motion.gravity = kGravityLandscapeLeft;
    [manager updateDeviceMotion:motion];
    motion.gravity = kGravityLandscapeRight;
    [manager updateDeviceMotion:motion];

    expect(recorder).to.sendValues(@[
      @(UIInterfaceOrientationPortrait),
      @(UIInterfaceOrientationPortraitUpsideDown),
      @(UIInterfaceOrientationLandscapeLeft),
      @(UIInterfaceOrientationLandscapeRight)
    ]);
  });

  it(@"should not send the orientation when the orientation is flat", ^{
    LLSignalTestRecorder *recorder = [signal testRecorder];
    motion.gravity = kGravityPortrait;
    [manager updateDeviceMotion:motion];
    motion.gravity = kGravityFlat;
    [manager updateDeviceMotion:motion];
    motion.gravity = kGravityLandscapeLeft;
    [manager updateDeviceMotion:motion];

    expect(recorder).to.sendValues(@[
      @(UIInterfaceOrientationPortrait),
      @(UIInterfaceOrientationLandscapeLeft)
    ]);
  });
});

SpecEnd
