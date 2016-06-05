// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUISimpleMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUISimpleMenuItemViewModel ()

/// Number of times \c didTap was called.
@property (readwrite, nonatomic) NSUInteger didTapCounter;

@end

@implementation CUISimpleMenuItemViewModel

- (void)didTap {
  self.didTapCounter++;
}

@end

NS_ASSUME_NONNULL_END
