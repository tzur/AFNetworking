// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRotatedRect.h"

#import <LTKit/LTHashExtensions.h>

@implementation LTRotatedRect

#pragma mark -
#pragma mark Class Methods
#pragma mark -

+ (instancetype)rect:(CGRect)rect {
  return [[LTRotatedRect alloc] initWithRect:rect angle:0];
}

+ (instancetype)rect:(CGRect)rect withAngle:(CGFloat)angle {
  return [[LTRotatedRect alloc] initWithRect:rect angle:angle];
}

+ (instancetype)rectWithCenter:(CGPoint)center size:(CGSize)size angle:(CGFloat)angle {
  return [[LTRotatedRect alloc] initWithCenter:center size:size angle:angle];
}

+ (instancetype)rectWithSize:(CGSize)size translation:(CGPoint)translation scaling:(CGFloat)scaling
                 andRotation:(CGFloat)rotation {
  CGRect scaledAndTranslated = CGRectCenteredAt(translation + size / 2, size * scaling);
  return [self rect:scaledAndTranslated withAngle:rotation];
}

+ (instancetype)squareWithCenter:(CGPoint)center length:(CGFloat)length angle:(CGFloat)angle {
  return [[LTRotatedRect alloc] initWithCenter:center size:CGSizeMakeUniform(length) angle:angle];
}

#pragma mark -
#pragma mark Initializers
#pragma mark -

- (instancetype)initWithCenter:(CGPoint)center size:(CGSize)size angle:(CGFloat)angle {
  return [self initWithRect:CGRectCenteredAt(center, size) angle:angle];
}

- (instancetype)initWithRect:(CGRect)rect angle:(CGFloat)angle {
  if (self = [super init]) {
    _rect = rect;
    _angle = angle;
    _center = CGRectCenter(rect);

    [self updateTransform];
    [self updateVertices];
  }
  return self;
}

- (instancetype)init {
  return [self initWithRect:CGRectZero angle:0];
}

- (void)updateTransform {
  if (!self.angle) {
    _transform = CGAffineTransformIdentity;
    return;
  }

  CGAffineTransform transform = CGAffineTransformMakeTranslation(self.center.x, self.center.y);
  transform = CGAffineTransformRotate(transform, self.angle);
  _transform = CGAffineTransformTranslate(transform, -self.center.x, -self.center.y);
}

- (void)updateVertices {
  CGPoint v0 = self.rect.origin;
  _v0 = self.transform * v0;
  _v1 = self.transform * CGPointMake(v0.x + self.rect.size.width, v0.y);
  _v2 = self.transform * CGPointMake(v0.x + self.rect.size.width, v0.y + self.rect.size.height);
  _v3 = self.transform * CGPointMake(v0.x, v0.y + self.rect.size.height);
}

#pragma mark -
#pragma mark Copying
#pragma mark -

- (id)copyWithZone:(NSZone *)zone {
  return [[LTRotatedRect allocWithZone:zone] initWithRect:self.rect angle:self.angle];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[LTRotatedRect class]]) {
    return NO;
  }

  return [self isEqualToRotatedRect:object];
}

- (BOOL)isEqualToRotatedRect:(LTRotatedRect *)rect {
  return CGRectEqualToRect(self.rect, rect.rect) &&
      self.angle == rect.angle &&
      self.center == rect.center;
}

- (NSUInteger)hash {
  size_t seed = 0;
  lt::hash_combine(seed, self.rect);
  lt::hash_combine(seed, self.angle);
  lt::hash_combine(seed, self.center);
  return seed;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, rect: %@, angle: %g, center: %@>",
          self.class, self, NSStringFromCGRect(self.rect), self.angle,
          NSStringFromCGPoint(self.center)];
}

#pragma mark -
#pragma mark Methods
#pragma mark -

- (BOOL)containsPoint:(CGPoint)point {
  CGPoint axisAlignedPoint =
      CGPointApplyAffineTransform(point, CGAffineTransformInvert(self.transform));
  return CGRectContainsPoint(self.rect, axisAlignedPoint);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setAngle:(CGFloat)angle {
  _angle = std::fmod(angle, 2 * M_PI);
}

- (CGRect)boundingRect {
  CGFloat minX = std::min(self.v0.x, std::min(self.v1.x, std::min(self.v2.x, self.v3.x)));
  CGFloat maxX = std::max(self.v0.x, std::max(self.v1.x, std::max(self.v2.x, self.v3.x)));
  CGFloat minY = std::min(self.v0.y, std::min(self.v1.y, std::min(self.v2.y, self.v3.y)));
  CGFloat maxY = std::max(self.v0.y, std::max(self.v1.y, std::max(self.v2.y, self.v3.y)));

  return CGRectFromEdges(minX, minY, maxX, maxY);
}

@end
