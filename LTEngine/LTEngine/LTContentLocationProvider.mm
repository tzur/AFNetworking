// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentLocationProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTContentLocationInfo

@synthesize contentSize = _contentSize;
@synthesize contentScaleFactor = _contentScaleFactor;
@synthesize contentInset = _contentInset;
@synthesize visibleContentRect = _visibleContentRect;
@synthesize maxZoomScale = _maxZoomScale;
@synthesize zoomScale = _zoomScale;

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

@end

NS_ASSUME_NONNULL_END
