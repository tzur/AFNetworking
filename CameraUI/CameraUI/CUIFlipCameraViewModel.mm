// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIFlipCameraViewModel.h"

#import <Camera/CAMDevicePreset.h>
#import <Camera/CAMFlipDevice.h>

NS_ASSUME_NONNULL_BEGIN

@interface CUIFlipCameraViewModel ()

/// \c CAMFlipDevice that this object tuggles between its cameras.
@property (readonly, nonatomic) id<CAMFlipDevice> flipDevice;

@end

@implementation CUIFlipCameraViewModel

@synthesize title = _title;
@synthesize iconURL = _iconURL;
@synthesize selected = _selected;
@synthesize hidden = _hidden;
@synthesize enabledSignal = _enabledSignal;
@synthesize enabled = _enabled;
@synthesize subitems = _subitems;

- (instancetype)initWithFlipDevice:(id<CAMFlipDevice>)flipDevice
                             title:(nullable NSString *)title
                           iconURL:(nullable NSURL *)iconURL {
  LTParameterAssert(flipDevice, @"Given flipDevice is nil");
  if (self = [super init]) {
    _flipDevice = flipDevice;
    _selected = NO;
    _hidden = NO;
    _subitems = nil;
    self.enabledSignal = RACObserve(self, flipDevice.canChangeCamera);
    RAC(self, enabled) = [RACObserve(self, enabledSignal) switchToLatest];
    RAC(self, title) = [RACObserve(self, enabled) map:^NSString *(NSNumber *enabled) {
      return enabled.boolValue ? title : nil;
    }];
    RAC(self, iconURL) = [RACObserve(self, enabled) map:^NSURL *(NSNumber *enabled) {
      return enabled.boolValue ? iconURL : nil;
    }];
  }
  return self;
}

- (void)didTap {
  if (!self.flipDevice.canChangeCamera) {
    return;
  }
  [[self.flipDevice setCamera:[self nextCamera]] subscribeCompleted:^{}];
}

- (CAMDeviceCamera *)nextCamera {
  switch (self.flipDevice.activeCamera.value) {
    case CAMDeviceCameraBack:
      return $(CAMDeviceCameraFront);
    case CAMDeviceCameraFront:
      return $(CAMDeviceCameraBack);
  }
}

@end

NS_ASSUME_NONNULL_END
