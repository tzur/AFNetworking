// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIFocusIconMode.h"

#import <LTKit/LTHashExtensions.h>

NS_ASSUME_NONNULL_BEGIN

@implementation CUIFocusIconMode

- (instancetype)initWithMode:(CUIFocusIconDisplayMode)mode atPosition:(nullable NSValue *)position {
  if (self = [super init]) {
    _mode = mode;
    _position = position;
  }
  return self;
}

+ (CUIFocusIconMode *)hiddenFocus {
  return [[CUIFocusIconMode alloc] initWithMode:CUIFocusIconDisplayModeHidden
                                     atPosition:nil];
}

+ (CUIFocusIconMode *)definiteFocusAtPosition:(CGPoint)position {
  return [[CUIFocusIconMode alloc] initWithMode:CUIFocusIconDisplayModeDefinite
                                     atPosition:$(position)];
}

+ (CUIFocusIconMode *)indefiniteFocusAtPosition:(CGPoint)position {
  return [[CUIFocusIconMode alloc] initWithMode:CUIFocusIconDisplayModeIndefinite
                                     atPosition:$(position)];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(CUIFocusIconMode *)object {
  if (object == self) {
    return YES;
  }

  if (![object isKindOfClass:[CUIFocusIconMode class]]) {
    return NO;
  }

  BOOL positionIsEqual = self.position == object.position ||
      [self.position isEqual:object.position];
  return self.mode == object.mode && positionIsEqual;
}

- (NSUInteger)hash {
  return self.mode ^ self.position.hash;
}

@end

NS_ASSUME_NONNULL_END
