// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentLocationProvider.h"

#import <LTKit/LTHashExtensions.h>

NS_ASSUME_NONNULL_BEGIN

@implementation LTContentLocationInfo

@synthesize contentSize = _contentSize;
@synthesize contentScaleFactor = _contentScaleFactor;
@synthesize contentInset = _contentInset;
@synthesize visibleContentRect = _visibleContentRect;
@synthesize maxZoomScale = _maxZoomScale;
@synthesize zoomScale = _zoomScale;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithContentSize:(CGSize)contentSize
                 contentScaleFactor:(CGFloat)contentScaleFactor
                       contentInset:(UIEdgeInsets)contentInset
                 visibleContentRect:(CGRect)visibleContentRect
                       maxZoomScale:(CGFloat)maxZoomScale
                          zoomScale:(CGFloat)zoomScale {
  if (self = [super init]) {
    _contentSize = contentSize;
    _contentScaleFactor = contentScaleFactor;
    _contentInset = contentInset;
    _visibleContentRect = visibleContentRect;
    _maxZoomScale = maxZoomScale;
    _zoomScale = zoomScale;
  }
  return self;
}

- (instancetype)initWithValuesOfContentLocationProvider:(id<LTContentLocationProvider>)provider {
  return [self initWithContentSize:provider.contentSize
                contentScaleFactor:provider.contentScaleFactor
                      contentInset:provider.contentInset
                visibleContentRect:provider.visibleContentRect maxZoomScale:provider.maxZoomScale
                         zoomScale:provider.zoomScale];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTContentLocationInfo *)locationInfo {
  if (self == locationInfo) {
    return YES;
  }

  if (![locationInfo isKindOfClass:[self class]]) {
    return NO;
  }

  return locationInfo.contentSize == self.contentSize &&
      locationInfo.contentScaleFactor == self.contentScaleFactor &&
      locationInfo.contentInset == self.contentInset &&
      locationInfo.visibleContentRect == self.visibleContentRect &&
      locationInfo.maxZoomScale == self.maxZoomScale &&
      locationInfo.zoomScale == self.zoomScale;
}

- (NSUInteger)hash {
  size_t seed = 0;
  lt::hash_combine(seed, self.contentSize);
  lt::hash_combine(seed, self.contentScaleFactor);
  lt::hash_combine(seed, self.contentInset.top);
  lt::hash_combine(seed, self.contentInset.left);
  lt::hash_combine(seed, self.contentInset.bottom);
  lt::hash_combine(seed, self.contentInset.right);
  lt::hash_combine(seed, self.visibleContentRect);
  lt::hash_combine(seed, self.maxZoomScale);
  lt::hash_combine(seed, self.zoomScale);
  return seed;
}

@end

NS_ASSUME_NONNULL_END
