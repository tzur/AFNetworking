// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIFlashMenuViewModel.h"

#import <Camera/CAMFlashDevice.h>

#import "CUIFlashModeViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIFlashMenuViewModel ()

/// \c CAMFlashDevice that this obejct represnts its flash modes.
@property (strong, readonly, nonatomic) id<CAMFlashDevice> flashDevice;

@end

@implementation CUIFlashMenuViewModel

@synthesize title = _title;
@synthesize iconURL = _iconURL;
@synthesize selected = _selected;
@synthesize hidden = _hidden;
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
  RAC(self, enabled) = RACObserve(self, flashDevice.hasFlash);
  @weakify(self);
  RAC(self, iconURL) = [RACSignal
      combineLatest:@[
        RACObserve(self, flashDevice.currentFlashMode),
        RACObserve(self, enabled)
      ]
      reduce:(id)^NSURL *(NSNumber *flashMode, NSNumber *enabled){
        @strongify(self);
        return enabled.boolValue ? [self flashModeViewModelForFlashMode:flashMode].iconURL : nil;
      }];
  RAC(self, title) = [RACSignal
      combineLatest:@[
        RACObserve(self, flashDevice.currentFlashMode),
        RACObserve(self, enabled)
      ]
      reduce:(id)^NSString *(NSNumber *flashMode, NSNumber *enabled){
        @strongify(self);
        return enabled.boolValue ? [self flashModeViewModelForFlashMode:flashMode].title : nil;
      }];
}

- (CUIFlashModeViewModel *)flashModeViewModelForFlashMode:(NSNumber *)flashMode {
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
