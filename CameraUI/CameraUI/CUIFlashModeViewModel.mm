// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIFlashModeViewModel.h"

#import <Camera/CAMFlashDevice.h>

NS_ASSUME_NONNULL_BEGIN

@interface CUIFlashModeViewModel ()

/// \c CAMFlashDevice that this object represents one of its flash modes.
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
    [self setup];
  }
  return self;
}

- (void)setup {
  _hidden = NO;
  _enabled = YES;
  RAC(self, selected, @NO) = [RACObserve(self, flashDevice.currentFlashMode)
      map:(id)^NSNumber *(NSNumber *flashMode) {
        return @(flashMode.integerValue == self.flashMode);
      }];
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
