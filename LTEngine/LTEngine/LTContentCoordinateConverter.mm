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

- (CGPoint)convertPointFromContentToPresentationCoordinates:(CGPoint)point {
  return CGPointApplyAffineTransform(point, self.contentToPresentationCoordinateTransform);
}

- (CGPoint)convertPointFromPresentationToContentCoordinates:(CGPoint)point {
  return CGPointApplyAffineTransform(point, self.presentationToContentCoordinateTransform);
}

- (CGAffineTransform)contentToPresentationCoordinateTransform {
  CGFloat scaleFactor = self.provider.zoomScale / self.provider.contentScaleFactor;
  CGAffineTransform scaling = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
  return CGAffineTransformTranslate(scaling,
                                    -self.provider.visibleContentRect.origin.x,
                                    -self.provider.visibleContentRect.origin.y);
}

- (CGAffineTransform)presentationToContentCoordinateTransform {
  CGAffineTransform translation =
      CGAffineTransformMakeTranslation(self.provider.visibleContentRect.origin.x,
                                       self.provider.visibleContentRect.origin.y);
  CGFloat scaleFactor = self.provider.contentScaleFactor / self.provider.zoomScale;
  return CGAffineTransformScale(translation, scaleFactor, scaleFactor);
}

@end

NS_ASSUME_NONNULL_END
