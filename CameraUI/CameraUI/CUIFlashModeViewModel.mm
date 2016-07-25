// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIFlashModeViewModel.h"

#import <Camera/CAMFlashDevice.h>

NS_ASSUME_NONNULL_BEGIN

@interface CUIFlashModeViewModel ()

/// \c CAMFlashDevice that this obejct represnts one of its flash modes.
@property (strong, readonly, nonatomic) id<CAMFlashDevice> flashDevice;

@end

@implementation CUIFlashModeViewModel

@synthesize title = _title;
@synthesize iconURL = _iconURL;
@synthesize selected = _selected;
@synthesize hidden = _hidden;
@synthesize enabled = _enabled;
@synthesize subitems = _subitems;

- (instancetype)initWithFlashDevice:(id<CAMFlashDevice>)flashDevice
                          flashMode:(AVCaptureFlashMode)flashMode
                              title:(nullable NSString *)title
                            iconURL:(nullable NSURL *)iconURL {
  LTParameterAssert(flashDevice, @"flashDevice is nil");
  if (self = [super init]) {
    _flashDevice = flashDevice;
    _flashMode = flashMode;
    _title = title;
    _iconURL = iconURL;
    _hidden = NO;
    _enabled = YES;

    RAC(self, selected, @NO) = [RACObserve(self, flashDevice.currentFlashMode)
        map:^NSNumber *(NSNumber *currentFlashMode) {
          return @(currentFlashMode.integerValue == flashMode);
        }];
  }
  return self;
}

#pragma mark -
#pragma mark CUIMenuItemViewModel
#pragma mark -

- (void)didTap {
  if (self.flashMode != self.flashDevice.currentFlashMode) {
    [[self.flashDevice setFlashMode:self.flashMode] subscribeCompleted:^{}];
  }
}

@end

NS_ASSUME_NONNULL_END
