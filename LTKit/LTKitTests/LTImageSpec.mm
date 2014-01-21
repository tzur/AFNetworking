// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImage.h"

#import "LTTestUtils.h"

SpecBegin(LTImage)

context(@"loading images", ^{
  __block cv::Mat mat;

  beforeEach(^{
    mat.create(10, 10, CV_8UC4);
    mat.setTo(cv::Vec4b(255, 0, 255, 255));
  });

  it(@"should load mat without copying", ^{
    LTImage *image = [[LTImage alloc] initWithMat:mat copy:NO];

    expect(LTCompareMat(mat, image.mat)).to.beTruthy();
  });

  it(@"should load mat with copying", ^{
    cv::Mat expected;
    mat.copyTo(expected);

    LTImage *image = [[LTImage alloc] initWithMat:mat copy:YES];
    mat.setTo(cv::Vec4b(0, 0, 0, 0));

    expect(LTCompareMat(expected, image.mat)).to.beTruthy();
  });

  it(@"should load an rgba jpeg image", ^{
    UIImage *jpeg = LTLoadImageWithName([self class], @"White.jpg");

    LTImage *image = [[LTImage alloc] initWithImage:jpeg];

    cv::Mat expected(image.size.height, image.size.width, CV_8UC4);
    expected.setTo(cv::Vec4b(255, 255, 255, 255));

    expect(LTCompareMat(expected, image.mat)).to.beTruthy();
  });

  it(@"should load an non-premultiplied alpha png image", ^{
    UIImage *jpeg = LTLoadImageWithName([self class], @"BlueTransparent.png");

    LTImage *image = [[LTImage alloc] initWithImage:jpeg];

    cv::Mat expected(image.size.height, image.size.width, CV_8UC4);
    expected.setTo(cv::Vec4b(0, 0, 128, 128));

    expect(LTCompareMat(expected, image.mat)).to.beTruthy();
  });

  it(@"should load a premultiplied alpha png image", ^{
    UIImage *jpeg = LTLoadImageWithName([self class], @"BlueTransparentPremultiplied.png");

    LTImage *image = [[LTImage alloc] initWithImage:jpeg];

    cv::Mat expected(image.size.height, image.size.width, CV_8UC4);
    expected.setTo(cv::Vec4b(0, 0, 128, 128));

    expect(LTCompareMat(expected, image.mat)).to.beTruthy();
  });

  it(@"should load gray jpeg image", ^{
    UIImage *jpeg = LTLoadImageWithName([self class], @"Gray.jpg");

    LTImage *image = [[LTImage alloc] initWithImage:jpeg];

    cv::Mat expected(image.size.height, image.size.width, CV_8UC1);
    expected.setTo(128);

    expect(LTCompareMat(expected, image.mat)).to.beTruthy();
  });

  context(@"load rotated images as portrait", ^{
    __block LTImage *expected;

    beforeAll(^{
      UIImage *image = LTLoadImageWithName([self class], @"QuadUp.jpg");
      expected = [[LTImage alloc] initWithImage:image];
    });

    sharedExamplesFor(@"rotating an image", ^(NSDictionary *data) {
      it(@"should load rotated images as portrait", ^{
        NSString *imageName = data[@"name"];

        UIImage *rotated = LTLoadImageWithName([self class], imageName);
        LTImage *image = [[LTImage alloc] initWithImage:rotated];

        expect(LTCompareMat(expected.mat, image.mat)).to.beTruthy();
      });
    });

    itShouldBehaveLike(@"rotating an image", @{@"name": @"QuadDown.jpg"});
    if (LTRunningApplicationTests()) {
      // Logic tests flips the left/right orientations for an unknown reason.
      itShouldBehaveLike(@"rotating an image", @{@"name": @"QuadLeft.jpg"});
      itShouldBehaveLike(@"rotating an image", @{@"name": @"QuadRight.jpg"});
    }
    itShouldBehaveLike(@"rotating an image", @{@"name": @"QuadUpMirrored.jpg"});
    itShouldBehaveLike(@"rotating an image", @{@"name": @"QuadDownMirrored.jpg"});
    itShouldBehaveLike(@"rotating an image", @{@"name": @"QuadLeftMirrored.jpg"});
    itShouldBehaveLike(@"rotating an image", @{@"name": @"QuadRightMirrored.jpg"});
  });
});

context(@"image properties", ^{
  it(@"should have correct size", ^{
    UIImage *jpeg = LTLoadImageWithName([self class], @"White.jpg");
    LTImage *image = [[LTImage alloc] initWithImage:jpeg];

    expect(image.size).to.equal(jpeg.size);
  });

  it(@"should have correct depth for rgba images", ^{
    UIImage *jpeg = LTLoadImageWithName([self class], @"White.jpg");
    LTImage *image = [[LTImage alloc] initWithImage:jpeg];

    expect(image.depth).to.equal(LTImageDepthRGBA);
  });

  it(@"should have correct depth for grayscale images", ^{
    UIImage *jpeg = LTLoadImageWithName([self class], @"Gray.jpg");
    LTImage *image = [[LTImage alloc] initWithImage:jpeg];

    expect(image.depth).to.equal(LTImageDepthGrayscale);
  });
});

context(@"uiimage conversion", ^{
  __block LTImage *expected;

  beforeEach(^{
    UIImage *jpeg = LTLoadImageWithName([self class], @"QuadUp.jpg");
    expected = [[LTImage alloc] initWithImage:jpeg];
  });

  it(@"should convert to uiimage with default scale", ^{
    // Note that it's incorrect to compare two UIImages binary representation (in PNG, for example)
    // since it may contain metadata. So the better option here is to compare their bytes, and this
    // is done by inserting the given UIImage again into LTImage.
    UIImage *actualImage = [expected UIImage];
    LTImage *actual = [[LTImage alloc] initWithImage:actualImage];

    expect(actualImage.scale).to.equal(1);
    expect(expected.size).to.equal(actual.size);
    expect(LTCompareMat(expected.mat, actual.mat)).to.beTruthy();
  });

  it(@"should convert to uiimage with retina scale", ^{
    UIImage *actualImage = [expected UIImageWithScale:2 copyData:YES];
    LTImage *actual = [[LTImage alloc] initWithImage:actualImage];

    expect(actualImage.scale).to.equal(2);
    expect(actual.size).to.equal(expected.size);
    expect(LTCompareMat(expected.mat, actual.mat)).to.beTruthy();
  });
});

SpecEnd
