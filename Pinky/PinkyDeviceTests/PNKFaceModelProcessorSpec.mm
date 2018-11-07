// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "PNKFaceModelProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

#import "PNKTestUtils.h"

DeviceSpecBegin(PNKFaceModelProcessor)

__block NSBundle *bundle;
__block PNKFaceModelProcessor *processor;

beforeEach(^{
  bundle = NSBundle.lt_testBundle;

  NSError *error;
  auto networkModelURL = [NSURL URLWithString:[bundle lt_pathForResource:@"facemodel.nnmodel"]];
  processor = [[PNKFaceModelProcessor alloc] initWithNetworkModelURL:networkModelURL error:&error];
});

context(@"parameters validation", ^{
  it(@"should assert when given output matrix with more than one row", ^{
    auto inputBuffer = LTCVPixelBufferCreate(256, 256, kCVPixelFormatType_32BGRA);
    expect(^{
      cv::Mat1f output(2, 258);
      [processor fitFaceParametersWithInput:inputBuffer.get() output:&output
                                   faceRect:CGRectMake(0, 0, 10, 20)
                                 completion:^(BOOL, NSError * _Nullable) {
      }];
    }).to.raise(NSInvalidArgumentException);
  });

it(@"should assert when given output matrix with invalid colums number", ^{
    auto inputBuffer = LTCVPixelBufferCreate(256, 256, kCVPixelFormatType_32BGRA);
    expect(^{
      cv::Mat1f output(1, 259);
      [processor fitFaceParametersWithInput:inputBuffer.get() output:&output
                                   faceRect:CGRectMake(0, 0, 10, 20)
                                 completion:^(BOOL, NSError * _Nullable) {
      }];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"fit parameters", ^{
  it(@"should fit face model parameters aligned with the given image", ^{
    cv::Mat4b inputByteMat = LTLoadMatFromBundle(bundle, @"face_model_processor_fit_input.jpg");
    auto rect = CGRectMake(311, 411, 905 - 311, 1004 - 411);
    auto inputBuffer = LTCVPixelBufferCreate(inputByteMat.cols, inputByteMat.rows,
                                             kCVPixelFormatType_32BGRA);
    LTCVPixelBufferImageForWriting(inputBuffer.get(), ^(cv::Mat *image) {
      inputByteMat.copyTo(*image);
    });

    __block cv::Mat1f output(1, 258);
    waitUntil(^(DoneCallback done) {
      [processor fitFaceParametersWithInput:inputBuffer.get() output:&output faceRect:rect
                                 completion:^(BOOL success, NSError * _Nullable error) {
        expect(success).to.beTruthy();
        expect(error).to.beNil();
        done();
      }];
    });

    auto expected = PNKLoadFloatTensorFromBundleResource(bundle, @"face_model_params_1x258.tensor");

    auto shapeParams = output(cv::Rect(0, 0, 224, 1));
    auto shapeExpected = expected(cv::Rect(0, 0, 224, 1));
    expect($(shapeParams)).to.beCloseToMatWithin($(shapeExpected), 0.02);

    auto colorParams = output(cv::Rect(224, 0, 27, 1));
    auto colorExpected = expected(cv::Rect(224, 0, 27, 1));
    expect($(colorParams)).to.beCloseToMatWithin($(colorExpected), 0.05);

    auto rotationParams = output(cv::Rect(251, 0, 3, 1));
    auto rotationExpected = expected(cv::Rect(251, 0, 3, 1));
    expect($(rotationParams)).to.beCloseToMatWithin($(rotationExpected), 0.01);

    auto translationParams = output(cv::Rect(254, 0, 3, 1));
    auto translationExpected = expected(cv::Rect(254, 0, 3, 1));
    expect($(translationParams)).to.beCloseToMatWithin($(translationExpected), 0.1);

    auto focalLength = output(0, 257);
    auto expectedFocalLenght = expected(0, 257);
    expect(focalLength).to.beCloseToWithin(expectedFocalLenght, 0.01);
  });
});

DeviceSpecEnd
