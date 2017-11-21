// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SPXAlertViewModel.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark SPXAlertButtonViewModel
#pragma mark -

@implementation SPXAlertButtonViewModel

@synthesize title = _title;
@synthesize action = _action;

- (instancetype)initWithTitle:(NSString *)title action:(LTVoidBlock)action {
  LTParameterAssert(action, @"Action block must not be nil");

  if (self = [super init]) {
    _title = [title copy];
    _action = [action copy];
  }
  return self;
}

@end

#pragma mark -
#pragma mark SPXAlertViewModel
#pragma mark -

@implementation SPXAlertViewModel

@synthesize title = _title;
@synthesize message = _message;
@synthesize buttons = _buttons;
@synthesize defaultButtonIndex = _defaultButtonIndex;

- (instancetype)initWithTitle:(NSString *)title message:(nullable NSString *)message
                      buttons:(NSArray<SPXAlertButtonViewModel *> *)buttons
           defaultButtonIndex:(nullable NSNumber *)defaultButtonIndex {
  LTParameterAssert(buttons.count > 0, @"Alert must have at least one button");
  LTParameterAssert(!defaultButtonIndex || defaultButtonIndex.unsignedLongValue < buttons.count,
           @"Default button index (%@) must be lower than the number of buttons (%lu)",
           defaultButtonIndex, (unsigned long)buttons.count);

  if (self = [super init]) {
    _title = [title copy];
    _message = [message copy];
    _buttons = [buttons copy];
    _defaultButtonIndex = defaultButtonIndex;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
