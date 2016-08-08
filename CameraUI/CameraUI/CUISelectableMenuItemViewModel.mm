// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUISelectableMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUISelectableMenuItemViewModel

@synthesize iconURL = _iconURL;
@synthesize title = _title;
@synthesize hidden = _hidden;
@synthesize enabledSignal = _enabledSignal;
@synthesize enabled = _enabled;
@synthesize subitems = _subitems;

- (instancetype)initWithMenuItemModel:(CUIMenuItemModel *)menuItemModel {
  if (self = [super init]) {
    _menuItemModel = menuItemModel;
    _title = menuItemModel.localizedTitle;
    _iconURL = menuItemModel.iconURL;
    _enabledSignal = [RACSignal return:@YES];
    RAC(self, enabled) = [RACObserve(self, enabledSignal) switchToLatest];;
  }
  return self;
}

- (void)didTap {
  // Has no effect.
}

@end

NS_ASSUME_NONNULL_END
