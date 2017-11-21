// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SPXAlertViewModelBuilder.h"

#import "SPXAlertViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXAlertViewModelBuilder ()

/// Alert's title.
@property (strong, nonatomic, nullable) NSString *title;

/// Alert's message.
@property (strong, nonatomic, nullable) NSString *message;

/// Alert's buttons.
@property (strong, nonatomic, nullable) NSMutableArray<SPXAlertButtonViewModel *> *buttons;

/// Default alert button index, or \c nil if no default button.
@property (strong, nonatomic, nullable) NSNumber *defaultButtonIndex;

@end

@implementation SPXAlertViewModelBuilder

+ (instancetype)builder {
  return [[SPXAlertViewModelBuilder alloc] init];
}

- (SPXSetAlertTitleBlock)setTitle {
  return ^(NSString *title) {
    self.title = [title copy];
    return self;
  };
}

- (SPXSetAlertMessageBlock)setMessage {
  return ^(NSString * _Nullable message) {
    self.message = [message copy];
    return self;
  };
}

- (SPXAddAlertButtonBlock)addButton {
  return ^(NSString *title, LTVoidBlock action) {
    self.buttons = self.buttons ?: [NSMutableArray array];
    auto button = [[SPXAlertButtonViewModel alloc] initWithTitle:title action:action];
    [self.buttons addObject:button];
    return self;
  };
}

- (SPXAddAlertButtonBlock)addDefaultButton {
  return ^(NSString *title, LTVoidBlock action) {
    self.buttons = self.buttons ?: [NSMutableArray array];
    auto button = [[SPXAlertButtonViewModel alloc] initWithTitle:title action:action];
    [self.buttons addObject:button];
    self.defaultButtonIndex = @(self.buttons.count - 1);
    return self;
  };
}

- (SPXSetDefaultAlertButtonIndexBlock)setDefaultButtonIndex {
  return ^(NSUInteger defaultButtonIndex) {
    LTParameterAssert(defaultButtonIndex < self.buttons.count, @"Default button index must be "
                      "lower than the total number of buttons %lu, got %lu",
                      (unsigned long)self.buttons.count, (unsigned long)defaultButtonIndex);

    self.defaultButtonIndex = @(defaultButtonIndex);
    return self;
  };
}

- (SPXBuildAlertViewModelBlock)build {
  return ^{
    LTAssert(self.title, @"Alert title must be specified");
    LTAssert(self.buttons.count > 0, @"Alert must have at least one button");
    LTAssert(!self.defaultButtonIndex ||
             self.defaultButtonIndex.unsignedLongValue < self.buttons.count,
             @"Default button index (%@) must be lower than the total number of buttons (%lu)",
             self.defaultButtonIndex, (unsigned long)self.buttons.count);

    return [[SPXAlertViewModel alloc] initWithTitle:self.title message:self.message
                                            buttons:self.buttons
                                 defaultButtonIndex:self.defaultButtonIndex];
  };
}

@end

NS_ASSUME_NONNULL_END
