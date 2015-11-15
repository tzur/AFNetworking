// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageResizer.h"

static void PTNWriteImageOfSizeToFile(CGSize size, NSString *path, UIImageOrientation orientation) {
  UIGraphicsBeginImageContext(size); {
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *rotatedImage = [UIImage imageWithCGImage:image.CGImage scale:image.scale
                                          orientation:orientation];
    [UIImageJPEGRepresentation(rotatedImage, 1) writeToFile:path atomically:YES];
  } UIGraphicsEndImageContext();
}

SpecBegin(PTNImageResizer)

__block PTNImageResizer *resizer;

beforeEach(^{
  LTCreateTemporaryDirectory();
  resizer = [[PTNImageResizer alloc] init];
});

context(@"portrait image", ^{
  static NSString * const kImageResizerSharedExamples = @"common resizing operations";
  static NSString * const kImageResizerContentModeKey = @"contentMode";

  static CGSize kOriginalSize = CGSizeMake(8, 8);

  __block NSURL *fileURL;

  sharedExamplesFor(kImageResizerSharedExamples, ^(NSDictionary *data) {
    __block PTNImageContentMode contentMode;

    beforeEach(^{
      contentMode = (PTNImageContentMode)[data[kImageResizerContentModeKey] unsignedIntegerValue];
    });

    it(@"should return a perfectly resized image and complete", ^{
      static CGSize kTargetSize = CGSizeMake(4, 4);

      RACSignal *signal = [resizer resizeImageAtURL:fileURL toSize:kTargetSize
                                        contentMode:contentMode];
      expect(signal).will.matchValue(0, ^BOOL(UIImage *value) {
        return value.size.width == kTargetSize.width && value.size.height == kTargetSize.height;
      });
      expect(signal).to.complete();
    });

    it(@"should return the original image if a larger size is provided", ^{
      static CGSize kTargetSize = CGSizeMake(10, 9);

      RACSignal *signal = [resizer resizeImageAtURL:fileURL toSize:kTargetSize
                                        contentMode:contentMode];
      expect(signal).will.matchValue(0, ^BOOL(UIImage *value) {
        return value.size.width == kOriginalSize.width && value.size.height == kOriginalSize.height;
      });
      expect(signal).to.complete();
    });
  });

  beforeEach(^{
    NSString *path = LTTemporaryPath(@"PTNImageResizerTest.jpg");
    fileURL = [NSURL fileURLWithPath:path];

    PTNWriteImageOfSizeToFile(kOriginalSize, path, UIImageOrientationUp);
  });

  context(@"aspect fill", ^{
    itShouldBehaveLike(kImageResizerSharedExamples,
                       @{kImageResizerContentModeKey: @(PTNImageContentModeAspectFill)});

    it(@"should return an aspect fitted image with integral scale factor and complete", ^{
      static CGSize kTargetSize = CGSizeMake(2, 4);
      static CGSize kExpectedSize = CGSizeMake(4, 4);

      RACSignal *signal = [resizer resizeImageAtURL:fileURL toSize:kTargetSize
                                        contentMode:PTNImageContentModeAspectFill];
      expect(signal).will.matchValue(0, ^BOOL(UIImage *value) {
        return value.size.width == kExpectedSize.width && value.size.height == kExpectedSize.height;
      });
      expect(signal).to.complete();
    });

    it(@"should return an aspect fitted image with fractional scale factor and complete", ^{
      static CGSize kTargetSize = CGSizeMake(2, 3);
      static CGSize kExpectedSize = CGSizeMake(3, 3);

      RACSignal *signal = [resizer resizeImageAtURL:fileURL toSize:kTargetSize
                                        contentMode:PTNImageContentModeAspectFill];
      expect(signal).will.matchValue(0, ^BOOL(UIImage *value) {
        return value.size.width == kExpectedSize.width && value.size.height == kExpectedSize.height;
      });
      expect(signal).to.complete();
    });
  });

  context(@"aspect fit", ^{
    itShouldBehaveLike(kImageResizerSharedExamples,
                       @{kImageResizerContentModeKey: @(PTNImageContentModeAspectFit)});

    it(@"should return an aspect fitted image with integral scale factor and complete", ^{
      static CGSize kTargetSize = CGSizeMake(2, 3);
      static CGSize kExpectedSize = CGSizeMake(2, 2);

      RACSignal *signal = [resizer resizeImageAtURL:fileURL toSize:kTargetSize
                                        contentMode:PTNImageContentModeAspectFit];
      expect(signal).will.matchValue(0, ^BOOL(UIImage *value) {
        return value.size.width == kExpectedSize.width && value.size.height == kExpectedSize.height;
      });
      expect(signal).to.complete();
    });
  });
});

context(@"rotated image", ^{
  __block NSURL *fileURL;

  beforeEach(^{
    NSString *path = LTTemporaryPath(@"PTNImageResizerRotatedTest.jpg");
    fileURL = [NSURL fileURLWithPath:path];

    PTNWriteImageOfSizeToFile(CGSizeMake(6, 12), path, UIImageOrientationRight);
  });

  context(@"aspect fill", ^{
    it(@"should return a resized aspect filled image", ^{
      static CGSize kTargetSize = CGSizeMake(3, 4);
      static CGSize kExpectedSize = CGSizeMake(8, 4);

      RACSignal *signal = [resizer resizeImageAtURL:fileURL toSize:kTargetSize
                                        contentMode:PTNImageContentModeAspectFill];
      expect(signal).will.matchValue(0, ^BOOL(UIImage *value) {
        return value.size.width == kExpectedSize.width && value.size.height == kExpectedSize.height;
      });
      expect(signal).to.complete();
    });
  });

  context(@"aspect fit", ^{
    it(@"should return a resized aspect fitted image", ^{
      static CGSize kTargetSize = CGSizeMake(6, 6);
      static CGSize kExpectedSize = CGSizeMake(6, 3);

      RACSignal *signal = [resizer resizeImageAtURL:fileURL toSize:kTargetSize
                                        contentMode:PTNImageContentModeAspectFit];
      expect(signal).will.matchValue(0, ^BOOL(UIImage *value) {
        return value.size.width == kExpectedSize.width && value.size.height == kExpectedSize.height;
      });
      expect(signal).to.complete();
    });
  });
});

SpecEnd
