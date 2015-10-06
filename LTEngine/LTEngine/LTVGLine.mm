// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTVGLine.h"

#import "LTVGGlyphRun.h"

@implementation LTVGLine

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithGlyphRuns:(NSArray *)runs {
  if (self = [super init]) {
    [self validateRuns:runs];
    _glyphRuns = [runs copy];
    _baselineOrigin = runs.count ? ((LTVGGlyphRun *)runs.firstObject).baselineOrigin : CGPointNull;
    _lineHeight = runs.count ? [self lineHeightFromRuns] : 0;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[LTVGLine class]]) {
    return NO;
  }

  return [((LTVGLine *)object).glyphRuns isEqualToArray:self.glyphRuns];
}

#pragma mark -
#pragma mark Public methods
#pragma mark -

- (CGPathRef)newPathWithTrackingFactor:(CGFloat)trackingFactor {
  CGMutablePathRef path = CGPathCreateMutable();

  CGFloat tracking = 0;
  for (LTVGGlyphRun *run in self.glyphRuns) {
    CGPathRef runPath = [run newPathWithTrackingFactor:trackingFactor];
    CGAffineTransform transformation = CGAffineTransformMakeTranslation(tracking, 0);
    CGPathAddPath(path, &transformation, runPath);
    CGPathRelease(runPath);

    tracking += trackingFactor * run.glyphs.count * run.font.pointSize;
  }
  return path;
}

#pragma mark -
#pragma mark Auxiliary methods
#pragma mark -

- (void)validateRuns:(NSArray *)runs {
  LTParameterAssert(runs);

  LTVGGlyphRun *firstRun = runs.firstObject;
  CGFloat expectedVerticalBaseLineOrigin = firstRun ? firstRun.baselineOrigin.y : 0;

  for (LTVGGlyphRun *run in runs) {
    LTParameterAssert([run isKindOfClass:[LTVGGlyphRun class]]);
    LTParameterAssert(expectedVerticalBaseLineOrigin == run.baselineOrigin.y);
  }
}

- (CGFloat)lineHeightFromRuns {
  CGFloat result = 0;
  for (LTVGGlyphRun *run in self.glyphRuns) {
    result = MAX(result, run.font.lineHeight);
  }
  return result;
}

@end
