// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTVGLines.h"

#import "LTVGLine.h"

@implementation LTVGLines

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithLines:(NSArray *)lines
             attributedString:(NSAttributedString *)attributedString {
  LTParameterAssert(attributedString);

  if (self = [super init]) {
    [self validateLines:lines];
    _lines = [lines copy];
    _attributedString = [attributedString copy];
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

  if (![object isKindOfClass:[LTVGLines class]]) {
    return NO;
  }

  return [((LTVGLines *)object).lines isEqualToArray:self.lines] &&
      [((LTVGLines *)object).attributedString isEqualToAttributedString:self.attributedString];
}

#pragma mark -
#pragma mark Public methods
#pragma mark -

- (CGPathRef)newPathWithLeadingFactor:(CGFloat)leadingFactor trackingFactor:(CGFloat)trackingFactor {
  CGMutablePathRef path = CGPathCreateMutable();

  CGFloat leading = 0;

  for (LTVGLine *line in self.lines) {
    CGPathRef linePath = [line newPathWithTrackingFactor:trackingFactor];
    CGAffineTransform transformation = CGAffineTransformMakeTranslation(0, leading);
    CGPathAddPath(path, &transformation, linePath);
    CGPathRelease(linePath);

    leading += leadingFactor * line.lineHeight;
  }
  return path;
}

#pragma mark -
#pragma mark Auxiliary methods
#pragma mark -

- (void)validateLines:(NSArray *)lines {
  LTParameterAssert(lines.count);

  for (id object in lines) {
    LTParameterAssert([object isKindOfClass:[LTVGLine class]]);
  }
}

@end
