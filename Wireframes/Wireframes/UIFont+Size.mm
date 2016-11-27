// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "UIFont+Size.h"

#import <LTKit/LTCGExtensions.h>

NS_ASSUME_NONNULL_BEGIN

@implementation UIFont (Size)

+ (CGFloat)wf_fontSizeForAvailableHeight:(CGFloat)height
                       withControlPoints:(WFHeightToFontSizeDictionary *)controlPoints {
  LTParameterAssert(controlPoints.count > 0, @"Control points number must be greater than 0");

  NSArray<NSNumber *> *sortedHeights =
      [controlPoints.allKeys sortedArrayUsingSelector:@selector(compare:)];
  NSUInteger heightIndex =
      [sortedHeights indexOfObject:@(height)
                     inSortedRange:NSMakeRange(0, sortedHeights.count)
                           options:(NSBinarySearchingInsertionIndex | NSBinarySearchingLastEqual)
                   usingComparator:^NSComparisonResult(NSNumber *height1, NSNumber *height2) {
                     return [height1 compare:height2];
                   }];
  
  if (heightIndex == 0) {
    return std::round(controlPoints[sortedHeights.firstObject].CGFloatValue);
  } else if (heightIndex >= sortedHeights.count &&
              [@(height) compare:sortedHeights.lastObject] != NSOrderedAscending) {
    return std::round(controlPoints[sortedHeights.lastObject].CGFloatValue);
  }
  
  NSNumber *heightStart = sortedHeights[heightIndex - 1];
  NSNumber *heightEnd = sortedHeights[heightIndex];
  CGFloat fontSizeStart = controlPoints[heightStart].CGFloatValue;
  CGFloat fontSizeEnd = controlPoints[heightEnd].CGFloatValue;
  
  CGFloat slope = (fontSizeEnd - fontSizeStart) /
      (heightEnd.CGFloatValue - heightStart.CGFloatValue);
  CGFloat intercept = fontSizeEnd - slope * heightEnd.CGFloatValue;
  return std::round(slope * height + intercept);
}

@end

NS_ASSUME_NONNULL_END
