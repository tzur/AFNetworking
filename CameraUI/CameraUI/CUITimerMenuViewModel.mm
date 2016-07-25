// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CUITimerMenuViewModel.h"

#import "CUITimerModeViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUITimerMenuViewModel ()

/// Timer container whose interval is controlled by this object.
@property (readonly, nonatomic) id<CUITimerContainer> timerContainer;

@end

@implementation CUITimerMenuViewModel

@synthesize title = _title;
@synthesize iconURL = _iconURL;
@synthesize selected = _selected;
@synthesize hidden = _hidden;
@synthesize enabled = _enabled;
@synthesize subitems = _subitems;

- (instancetype)initWithTimerContainer:(id<CUITimerContainer>)timerContainer
                            timerModes:(NSArray<CUITimerModeViewModel *> *)timerModes {
  LTParameterAssert(timerContainer);
  LTParameterAssert(timerModes);
  if (self = [super init]) {
    _timerContainer  = timerContainer;
    _subitems = timerModes;
    _selected = NO;
    _hidden = NO;
    _enabled = YES;
    [self setup];
  }
  return self;
}

- (void)setup {
  @weakify(self);
  RAC(self, iconURL) = [RACObserve(self, timerContainer.interval)
      map:^NSURL * _Nullable(NSNumber *delay) {
        @strongify(self);
        return [self timerModeViewModelForDelay:delay.doubleValue].iconURL;
      }];
  RAC(self, title) = [RACObserve(self, timerContainer.interval)
      map:^NSString * _Nullable(NSNumber *delay) {
        @strongify(self);
        return [self timerModeViewModelForDelay:delay.doubleValue].title;
      }];
}

- (nullable CUITimerModeViewModel *)timerModeViewModelForDelay:(NSTimeInterval)delay {
  return [self.subitems.rac_sequence
      filter:^BOOL(CUITimerModeViewModel *mode) {
        return std::abs(mode.interval - delay) < mode.precision;
      }].head;
}

- (void)didTap {
  // Empty implementation for the protocol.
}

@end

NS_ASSUME_NONNULL_END
