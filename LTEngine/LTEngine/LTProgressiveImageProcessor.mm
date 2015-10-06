// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTProgressiveImageProcessor+Protected.h"

@implementation LTProgressiveImageProcessor

- (void)resetProgress {
  self.processedProgress = 0;
  self.targetProgress = 0;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTProperty(double, targetProgress, TargetProgress, 0, 1, 0);

@end
