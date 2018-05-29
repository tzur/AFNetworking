// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionLayerExamples.h"

#import "PNKImageMotionLayer.h"

NSString * const kPNKImageMotionLayerExamples = @"PNKImageMotionLayerExamples";
NSString * const kPNKImageMotionLayerExamplesLayer = @"PNKImageMotionLayerExamplesLayer";
NSString * const kPNKImageMotionLayerExamplesImageWidth = @"PNKImageMotionLayerExamplesImageWidth";
NSString * const kPNKImageMotionLayerExamplesImageHeight =
    @"PNKImageMotionLayerExamplesImageHeight";

SharedExamplesBegin(PNKImageMotionLayerExamples)

sharedExamplesFor(kPNKImageMotionLayerExamples, ^(NSDictionary *data) {
  context(@"PNKImageMotionLayer protocol", ^{
    __block id<PNKImageMotionLayer> layer;
    __block int imageWidth;
    __block int imageHeight;

    beforeEach(^{
      layer = data[kPNKImageMotionLayerExamplesLayer];
      imageWidth = [data[kPNKImageMotionLayerExamplesImageWidth] intValue];
      imageHeight = [data[kPNKImageMotionLayerExamplesImageHeight] intValue];
    });

    it(@"should raise when displacements matrix has 1 channel", ^{
      __block cv::Mat1hf displacements(imageHeight, imageWidth);
      expect(^{
        [layer displacements:&displacements forTime:0];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when displacements matrix is not of half-float type", ^{
      __block cv::Mat2f displacements(imageHeight, imageWidth);
      expect(^{
        [layer displacements:&displacements forTime:0];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when displacements matrix has wrong height", ^{
      __block cv::Mat2hf displacements(imageHeight + 1, imageWidth);
      expect(^{
        [layer displacements:&displacements forTime:0];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when displacements matrix has wrong width", ^{
      __block cv::Mat2hf displacements(imageHeight, imageWidth + 1);
      expect(^{
        [layer displacements:&displacements forTime:0];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should return the correct image size", ^{
      auto imageSize = layer.imageSize;
      expect(imageSize.width).to.equal(imageWidth);
      expect(imageSize.height).to.equal(imageHeight);
    });
  });
});

SharedExamplesEnd
