// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MTBImagePropertiesExamples.h"

NSString * const kMTBImagePropertiesExamples = @"MTBImagePropertiesExamples";
NSString * const kMTBImagePropertiesExamplesImage = @"MTBImagePropertiesExamplesImage";
NSString * const kMTBImagePropertiesExamplesWidth = @"MTBImagePropertiesExamplesWidth";
NSString * const kMTBImagePropertiesExamplesHeight = @"MTBImagePropertiesExamplesHeight";
NSString * const kMTBImagePropertiesExamplesFeatureChannels =
    @"MTBImagePropertiesExamplesFeatureChannels";
NSString * const kMTBImagePropertiesExamplesPixelFormat = @"MTBImagePropertiesExamplesPixelFormat";

SharedExamplesBegin(MTBImageExamples)

sharedExamplesFor(kMTBImagePropertiesExamples, ^(NSDictionary *data) {
  it(@"should manage readCount properly upon consumption", ^{
    MPSImage *image = data[kMTBImagePropertiesExamplesImage];
    expect(image.width).to.equal(data[@"MTBImagePropertiesExamplesWidth"]);
    expect(image.height).to.equal(data[@"MTBImagePropertiesExamplesHeight"]);
    expect(image.featureChannels).to.equal(data[@"MTBImagePropertiesExamplesFeatureChannels"]);
    expect(image.pixelFormat).to.equal(data[kMTBImagePropertiesExamplesPixelFormat]);
  });
});

SharedExamplesEnd
