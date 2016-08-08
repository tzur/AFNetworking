// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CUIGridViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIGridViewModel ()

/// Container whose grid is toggled by this object.
@property (readonly, nonatomic) id<CUIGridContainer> gridContainer;

@end

@implementation CUIGridViewModel

@synthesize title = _title;
@synthesize iconURL = _iconURL;
@synthesize selected = _selected;
@synthesize hidden = _hidden;
@synthesize enabledSignal = _enabledSignal;
@synthesize enabled = _enabled;
@synthesize subitems = _subitems;

- (instancetype)initWithGridContainer:(id<CUIGridContainer>)gridContainer title:(NSString *)title
                              iconURL:(NSURL *)iconURL {
  LTParameterAssert(gridContainer);
  if (self = [super init]) {
    _gridContainer = gridContainer;
    _hidden = NO;
    self.enabledSignal = [RACSignal return:@YES];
    RAC(self, enabled) = [RACObserve(self, enabledSignal) switchToLatest];
    _subitems = nil;
    _title = title;
    _iconURL = iconURL;
    RAC(self, selected, @NO) = [RACObserve(self, gridContainer.gridHidden) not];
  }
  return self;
}

- (void)didTap {
  self.gridContainer.gridHidden = !self.gridContainer.gridHidden;
}

@end

NS_ASSUME_NONNULL_END
