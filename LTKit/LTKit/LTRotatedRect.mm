// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRotatedRect.h"

#import "LTCGExtensions.h"

@interface LTRotatedRect ()

@property (nonatomic) CGRect rect;
@property (nonatomic) CGFloat angle;
@property (nonatomic) CGPoint center;

@property (nonatomic) CGPoint v0;
@property (nonatomic) CGPoint v1;
@property (nonatomic) CGPoint v2;
@property (nonatomic) CGPoint v3;

@property (nonatomic) CGAffineTransform transform;

@end

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

- (instancetype)initWithRect:(CGRect)rect angle:(CGFloat)angle {
  if (self = [super init]) {
    self.rect = rect;
    self.angle = angle;
    self.center = CGRectCenter(rect);
    [self updateTransform];
    [self updateVertices];
  }
  return self;
}

- (instancetype)initWithCenter:(CGPoint)center size:(CGSize)size angle:(CGFloat)angle {
  return [self initWithRect:CGRectCenteredAt(center, size) angle:angle];
}

- (void)updateTransform {
  CGAffineTransform transform = CGAffineTransformIdentity;
  if (self.angle) {
    transform = CGAffineTransformTranslate(transform, self.center.x, self.center.y);
    // In iOS, negative values mean clockwise rotation, while positive values in OSX.
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    transform = CGAffineTransformRotate(transform, self.angle);
#else
    transform = CGAffineTransformRotate(transform, -self.angle);
#endif
    transform = CGAffineTransformTranslate(transform, -self.center.x, -self.center.y);
  }
  self.transform = transform;
}

- (void)updateVertices {
  CGPoint v0 = self.rect.origin;
  self.v0 = self.transform * v0;
  self.v1 = self.transform * CGPointMake(v0.x + self.rect.size.width, v0.y);
  self.v2 = self.transform * CGPointMake(v0.x + self.rect.size.width, v0.y + self.rect.size.height);
  self.v3 = self.transform * CGPointMake(v0.x, v0.y + self.rect.size.height);
}

#pragma mark -
#pragma mark Copying
#pragma mark -

- (id)copyWithZone:(NSZone *)zone {
  return [[LTRotatedRect allocWithZone:zone] initWithRect:self.rect angle:self.angle];
}

#pragma mark -
#pragma mark Equality
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
  NSUInteger hashCode = CGRectHash(self.rect);
  hashCode = 31 * hashCode + [@(self.angle) hash];
  hashCode = 31 * hashCode + CGPointHash(self.center);
  return hashCode;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setAngle:(CGFloat)angle {
  _angle = std::fmod(angle, 2 * M_PI);
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Origin: (%g,%g), Size: (%g,%g), Center: (%g,%g), Angle: %g",
          self.rect.origin.x, self.rect.origin.y, self.rect.size.width, self.rect.size.height,
          self.center.x, self.center.y, self.angle];
}

@end
