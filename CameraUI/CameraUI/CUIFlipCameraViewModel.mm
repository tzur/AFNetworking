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
@synthesize subitems = _subitems;

- (instancetype)initWithFlipDevice:(id<CAMFlipDevice>)flipDevice
                             title:(nullable NSString *)title
                           iconURL:(nullable NSURL *)iconURL {
  LTParameterAssert(flipDevice, @"Given flipDevice is nil");
  if (self = [super init]) {
    _flipDevice = flipDevice;
    _title = title;
    _iconURL = iconURL;
    [self setup];
  }
  return self;
}

- (void)setup {
  _selected = NO;
  _hidden = NO;
  _subitems = nil;
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
