// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentCoordinateConverter.h"

#import "LTContentLocationProvider.h"
#import "LTQuad.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTContentCoordinateConverter ()

/// Internally used content location provider.
@property (readonly, nonatomic) id<LTContentLocationProvider> provider;

@end

@implementation LTContentCoordinateConverter

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithLocationProvider:(id<LTContentLocationProvider>)provider {
  if (self = [super init]) {
    _provider = provider;
  }
  return self;
}

#pragma mark -
#pragma mark LTContentCoordinateConverter
#pragma mark -

- (CGPoint)convertPointFromContentToView:(CGPoint)point {
  return (point - self.provider.visibleContentRect.origin) * self.provider.zoomScale /
      self.provider.contentScaleFactor;
}

- (CGPoint)convertPointFromViewToContent:(CGPoint)point {
  return point * self.provider.contentScaleFactor / self.provider.zoomScale +
      self.provider.visibleContentRect.origin;
}

@end

NS_ASSUME_NONNULL_END
