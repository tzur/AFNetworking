// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIFlashMenuViewModel.h"

#import <Camera/CAMFlashDevice.h>

#import "CUIFlashModeViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIFlashMenuViewModel ()

/// \c CAMFlashDevice that this object represents its flash modes.
@property (strong, readonly, nonatomic) id<CAMFlashDevice> flashDevice;

@end

@implementation CUIFlashMenuViewModel

@synthesize title = _title;
@synthesize iconURL = _iconURL;
@synthesize selected = _selected;
@synthesize hidden = _hidden;
@synthesize enabledSignal = _enabledSignal;
@synthesize enabled = _enabled;
@synthesize subitems = _subitems;

- (instancetype)initWithFlashDevice:(id<CAMFlashDevice>)flashDevice
                         flashModes:(NSArray<CUIFlashModeViewModel *> *)flashModes {
  LTParameterAssert(flashDevice, @"flashDevice is nil");
  LTParameterAssert(flashModes, @"flashModes is nil");
  if (self = [super init]) {
    _flashDevice = flashDevice;
    _subitems = flashModes;
    [self setup];
  }
  return self;
}

- (void)setup {
  _selected = NO;
  _hidden = NO;
  self.enabledSignal = RACObserve(self, flashDevice.hasFlash);
  RAC(self, enabled) = [RACObserve(self, enabledSignal) switchToLatest];
  @weakify(self);
  RAC(self, iconURL) = [RACObserve(self, flashDevice.currentFlashMode)
      map:^NSURL * _Nullable(NSNumber *flashMode) {
        @strongify(self)
        return [self flashModeViewModelForFlashMode:flashMode].iconURL;
      }];
  RAC(self, title) =  [RACObserve(self, flashDevice.currentFlashMode)
      map:^NSString * _Nullable(NSNumber *flashMode) {
        @strongify(self)
        return [self flashModeViewModelForFlashMode:flashMode].title;
      }];
}

- (nullable CUIFlashModeViewModel *)flashModeViewModelForFlashMode:(NSNumber *)flashMode {
  for (CUIFlashModeViewModel *mode in self.subitems) {
    if (flashMode.integerValue == mode.flashMode) {
      return mode;
    }
  }
  return nil;
}

#pragma mark -
#pragma mark CUIMenuItemViewModel
#pragma mark -

- (void)didTap {
  // Empty implementation for the protocol.
}

@end

NS_ASSUME_NONNULL_END
