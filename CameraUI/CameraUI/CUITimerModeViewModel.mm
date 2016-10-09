// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CUITimerModeViewModel.h"

#import <Camera/CAMTimerContainer.h>

NS_ASSUME_NONNULL_BEGIN

@interface CUITimerModeViewModel ()

/// Timer container whose interval is controlled by this object.
@property (readonly, nonatomic) id<CAMTimerContainer> timerContainer;

@end

@implementation CUITimerModeViewModel

@synthesize title = _title;
@synthesize iconURL = _iconURL;
@synthesize selected = _selected;
@synthesize hidden = _hidden;
@synthesize enabledSignal = _enabledSignal;
@synthesize enabled = _enabled;
@synthesize subitems = _subitems;

+ (instancetype)viewModelWithTimerContainer:(id<CAMTimerContainer>)timerContainer
                                   interval:(NSTimeInterval)interval
                                  precision:(NSTimeInterval)precision
                                      title:(nullable NSString *)title
                                    iconURL:(nullable NSURL *)iconURL {
  return [[CUITimerModeViewModel alloc] initWithTimerContainer:timerContainer
                                                      interval:interval precision:precision
                                                         title:title iconURL:iconURL];
}

- (instancetype)initWithTimerContainer:(id<CAMTimerContainer>)timerContainer
                              interval:(NSTimeInterval)interval
                             precision:(NSTimeInterval)precision
                                 title:(nullable NSString *)title
                               iconURL:(nullable NSURL *)iconURL {
  LTParameterAssert(timerContainer);
  LTParameterAssert(interval >= 0, @"interval must be non-negative");
  LTParameterAssert(precision > 0, @"precision must be positive");
  if (self = [super init]) {
    _timerContainer = timerContainer;
    _interval = interval;
    _precision = precision;
    _title = title;
    _iconURL = iconURL;
    _hidden = NO;
    _enabledSignal = [RACSignal return:@YES];
    RAC(self, enabled) = [RACObserve(self, enabledSignal) switchToLatest];;
    [self setup];
  }
  return self;
}

- (void)setup {
  @weakify(self);
  RAC(self, selected, @NO) = [RACObserve(self, timerContainer.interval)
      map:^NSNumber *(NSNumber *containerInterval) {
        @strongify(self);
        return @(std::abs(containerInterval.doubleValue - self.interval) < self.precision);
      }];
}

- (void)didTap {
  self.timerContainer.interval = self.interval;
}

@end

NS_ASSUME_NONNULL_END
