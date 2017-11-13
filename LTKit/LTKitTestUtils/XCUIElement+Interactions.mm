// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "XCUIElement+Interactions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation XCUIElement (Interactions)

/// Duration of pressing the start coordinate before draging to end coordinate in pan interaction
/// emulation.
static const NSTimeInterval kLTPanPressBeforeDragDuration = 0.1;

- (void)lt_panFromOffset:(CGVector)normalizedStart toOffset:(CGVector)normalizedEnd {
  auto start = [self coordinateWithNormalizedOffset:normalizedStart];
  auto end = [self coordinateWithNormalizedOffset:normalizedEnd];
  [start pressForDuration:kLTPanPressBeforeDragDuration thenDragToCoordinate:end];
}

@end

NS_ASSUME_NONNULL_END
