// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTAspectFillResizeProcessor.h"

#import "LTFbo.h"

@interface LTAspectFillResizeProcessor ()

/// Input texture to resize.
@property (strong, nonatomic) LTTexture *inputTexture;

/// Output texture containing resized input.
@property (strong, nonatomic) LTTexture *outputTexture;

@end

@implementation LTAspectFillResizeProcessor

- (instancetype)initWithInput:(LTTexture *)inputTexture andOutput:(LTTexture *)outputTexture {
  if (self = [super init]) {
    self.inputTexture = inputTexture;
    self.outputTexture = outputTexture;
  }
  return self;
}

- (void)process {
  [self.inputTexture mappedCGImage:^(CGImageRef imageRef, BOOL) {
    [self.outputTexture drawWithCoreGraphics:^(CGContextRef context) {
      // Reset transformation since drawing here is already flipped.
      CGAffineTransform currentTransform = CGContextGetCTM(context);
      CGContextConcatCTM(context, CGAffineTransformInvert(currentTransform));

      CGContextSetAllowsAntialiasing(context, true);
      CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

      CGSize aspectFillSize = CGSizeAspectFill(self.inputTexture.size, self.outputTexture.size);
      CGSize origin = (self.outputTexture.size - aspectFillSize) / 2;
      CGRect outputRect = CGRectMake(origin.width, origin.height,
                                     aspectFillSize.width, aspectFillSize.height);

      CGContextDrawImage(context, outputRect, imageRef);
    }];
  }];
}

@end
