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

- (CGPathRef)newPathWithLeadingFactor:(CGFloat)leadingFactor
                       trackingFactor:(CGFloat)trackingFactor {
  NSParagraphStyle *paragraphStyle = [self.attributedString attribute:NSParagraphStyleAttributeName
                                                              atIndex:0 effectiveRange:NULL];
  NSTextAlignment alignment = paragraphStyle ? paragraphStyle.alignment : NSTextAlignmentLeft;

  return [self newPathWithLeadingFactor:leadingFactor trackingFactor:trackingFactor
                              alignment:alignment];
}

- (CGPathRef)newPathWithLeadingFactor:(CGFloat)leadingFactor
                       trackingFactor:(CGFloat)trackingFactor alignment:(NSTextAlignment)alignment {
  CGMutablePathRef path = CGPathCreateMutable();

  CGFloat leading = 0;

  for (LTVGLine *line in self.lines) {
    CGPathRef linePath = [line newPathWithTrackingFactor:trackingFactor];
    CGAffineTransform alignmentTransformation = [self transformationForPath:linePath
                                                               andAlignment:alignment];
    CGAffineTransform finalTransformation =
        CGAffineTransformConcat(CGAffineTransformMakeTranslation(0, leading),
                                alignmentTransformation);
    CGPathAddPath(path, &finalTransformation, linePath);
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

/// Returns the transformation required to align the given \c path according to the given
/// \c aligment.
- (CGAffineTransform)transformationForPath:(CGPathRef)path andAlignment:(NSTextAlignment)alignment {
  CGRect pathBoundingBox = CGPathGetBoundingBox(path);

  if (alignment == NSTextAlignmentCenter) {
    return CGAffineTransformMakeTranslation(-pathBoundingBox.size.width / 2, 0);
  } else if (alignment == NSTextAlignmentRight) {
    return CGAffineTransformMakeTranslation(-pathBoundingBox.size.width, 0);
  } else {
    return CGAffineTransformIdentity;
  }
}

@end
