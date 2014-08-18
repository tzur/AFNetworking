// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImage.h"

#import "LTOpenCVExtensions.h"

static cv::Mat4b LTLoadRGBAImage(Class className, NSString *name) {
  NSBundle *bundle = [NSBundle bundleForClass:className];
  NSString *path = [bundle pathForResource:name ofType:@"png"];

  cv::Mat3b bgr(cv::imread([path cStringUsingEncoding:NSUTF8StringEncoding]));
  cv::Mat ones = cv::Mat::ones(bgr.size(), CV_8U) * 255;

  cv::Mat4b output(bgr.size());

  const int fromTo[] = {0, 2, 1, 1, 2, 0, 3, 3};
  Matrices inputs{bgr, ones};
  Matrices outputs{output};

  cv::mixChannels(inputs, outputs, fromTo, 4);

  return output;
}

SpecBegin(LTImage)

context(@"loading images", ^{
  __block cv::Mat mat;

  beforeEach(^{
    mat.create(10, 10, CV_8UC4);
    mat.setTo(cv::Vec4b(255, 0, 255, 255));
  });

  it(@"should load mat without copying", ^{
    LTImage *image = [[LTImage alloc] initWithMat:mat copy:NO];

    expect($(image.mat)).to.equalMat($(mat));
  });

  it(@"should load mat with copying", ^{
    cv::Mat expected;
    mat.copyTo(expected);

    LTImage *image = [[LTImage alloc] initWithMat:mat copy:YES];
    mat.setTo(cv::Vec4b(0, 0, 0, 0));

    expect($(image.mat)).to.equalMat($(expected));
  });

  it(@"should load an rgba jpeg image", ^{
    UIImage *jpeg = LTLoadImage([self class], @"White.jpg");

    LTImage *image = [[LTImage alloc] initWithImage:jpeg];

    cv::Mat expected(image.size.height, image.size.width, CV_8UC4);
    expected.setTo(cv::Vec4b(255, 255, 255, 255));

    expect($(image.mat)).to.equalMat($(expected));
  });

  it(@"should load an non-premultiplied alpha png image", ^{
    UIImage *png = LTLoadImage([self class], @"BlueTransparent.png");

    LTImage *image = [[LTImage alloc] initWithImage:png];

    cv::Mat expected(image.size.height, image.size.width, CV_8UC4);
    expected.setTo(cv::Vec4b(0, 0, 128, 128));

    expect($(image.mat)).to.equalMat($(expected));
  });

  it(@"should load a premultiplied alpha png image", ^{
    UIImage *png = LTLoadImage([self class], @"BlueTransparentPremultiplied.png");

    LTImage *image = [[LTImage alloc] initWithImage:png];

    cv::Mat expected(image.size.height, image.size.width, CV_8UC4);
    expected.setTo(cv::Vec4b(0, 0, 128, 128));

    expect($(image.mat)).to.equalMat($(expected));
  });

  it(@"should load gray jpeg image", ^{
    UIImage *jpeg = LTLoadImage([self class], @"Gray.jpg");

    LTImage *image = [[LTImage alloc] initWithImage:jpeg];

    cv::Mat expected(image.size.height, image.size.width, CV_8UC1);
    expected.setTo(128);

    expect($(image.mat)).to.equalMat($(expected));
  });

  sit(@"should load @2x image", ^{
    UIImage *png = LTLoadImage([self class], @"LTImageNoise@2x.png");
    expect(png.scale).to.equal(2);

    LTImage *image = [[LTImage alloc] initWithImage:png];
    expect(image.size).to.equal(CGSizeMake(32, 32));

    // To do fair comparison, we rely on OpenCV's imread.
    cv::Mat4b expected(LTLoadRGBAImage([self class], @"LTImageNoise@2x"));

    expect($(image.mat)).to.equalMat($(expected));
  });

  context(@"load rotated images as portrait", ^{
    __block LTImage *expected;

    beforeAll(^{
      UIImage *image = LTLoadImage([self class], @"QuadUp.jpg");
      expected = [[LTImage alloc] initWithImage:image];
    });

    sharedExamplesFor(@"rotating an image", ^(NSDictionary *data) {
      it(@"should load rotated images as portrait", ^{
        NSString *imageName = data[@"name"];

        UIImage *rotated = LTLoadImage([self class], imageName);
        LTImage *image = [[LTImage alloc] initWithImage:rotated];

        expect($(image.mat)).to.equalMat($(expected.mat));
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

    it(@"should rotate non-rectangular image", ^{
      UIImage *expectedImage = LTLoadImage([self class], @"RectUp.jpg");
      LTImage *expected = [[LTImage alloc] initWithImage:expectedImage];

      UIImage *rotated = LTLoadImage([self class], @"RectRotated.jpg");
      LTImage *image = [[LTImage alloc] initWithImage:rotated];

      expect($(image.mat)).to.equalMat($(expected.mat));
    });
  });
});

context(@"image properties", ^{
  it(@"should have correct size", ^{
    UIImage *jpeg = LTLoadImage([self class], @"White.jpg");
    LTImage *image = [[LTImage alloc] initWithImage:jpeg];

    expect(image.size).to.equal(jpeg.size);
  });

  it(@"should have correct depth for rgba images", ^{
    UIImage *jpeg = LTLoadImage([self class], @"White.jpg");
    LTImage *image = [[LTImage alloc] initWithImage:jpeg];

    expect(image.depth).to.equal(LTImageDepthRGBA);
  });

  it(@"should have correct depth for grayscale images", ^{
    UIImage *jpeg = LTLoadImage([self class], @"Gray.jpg");
    LTImage *image = [[LTImage alloc] initWithImage:jpeg];

    expect(image.depth).to.equal(LTImageDepthGrayscale);
  });
});

context(@"uiimage conversion", ^{
  __block LTImage *expected;

  beforeEach(^{
    UIImage *jpeg = LTLoadImage([self class], @"QuadUp.jpg");
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
    expect($(actual.mat)).to.equalMat($(expected.mat));
  });

  it(@"should convert to uiimage with retina scale", ^{
    UIImage *actualImage = [expected UIImageWithScale:2 copyData:YES];
    LTImage *actual = [[LTImage alloc] initWithImage:actualImage];

    expect(actualImage.scale).to.equal(2);
    expect(actual.size).to.equal(expected.size);
    expect($(actual.mat)).to.equalMat($(expected.mat));
  });
});

SpecEnd
