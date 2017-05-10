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

static lt::Ref<CGImageRef> LTCreatHalfFloatCGImage(size_t width, size_t height,
    CGColorSpaceRef colorSpace, LTVector4 color) {
  // Create drawing context.
  cv::Mat4hf mat((int)height, (int)width);
  size_t bitsPerComponent = mat.elemSize1() * CHAR_BIT;
  CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder16Little |
      kCGBitmapFloatComponents;
  lt::Ref<CGContextRef> context(CGBitmapContextCreate(mat.data, width, height, bitsPerComponent,
                                mat.step[0], colorSpace, bitmapInfo));
  LTAssert(context, @"Context not created");

  // Draw.
  CGContextSetRGBFillColor(context.get(), color.r(), color.g(), color.b(), color.a());
  CGContextFillRect(context.get(), CGRectMake(0, 0, width, height));

  return lt::Ref<CGImageRef>(CGBitmapContextCreateImage(context.get()));
}

static cv::Vec4b LTConvertRGBAComponents(const CGFloat *components,
    CGColorSpaceRef colorSpace, CGColorRenderingIntent intent) {
  auto uiSourceColor = [UIColor colorWithRed:components[0] green:components[1]
                                        blue:components[2] alpha:components[3]];
  auto cgDestColorRef =
      lt::Ref<CGColorRef>(CGColorCreateCopyByMatchingToColorSpace(colorSpace, intent,
                                                                  uiSourceColor.CGColor, NULL));
  const CGFloat *destComponents = CGColorGetComponents(cgDestColorRef.get());

  return cv::Vec4b(destComponents[0] * 255, destComponents[1] * 255, destComponents[2] * 255,
                   destComponents[3] * 255);
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

  it(@"should load indexed png image", ^{
    UIImage *png = LTLoadImage([self class], @"Indexed.png");

    LTImage *image = [[LTImage alloc] initWithImage:png];

    cv::Mat expected(image.size.height, image.size.width, CV_8UC4);
    expected.setTo(cv::Vec4b(0, 128, 255, 255));

    expect($(image.mat)).to.equalMat($(expected));
  });

  it(@"should load indexed png image with alpha", ^{
    UIImage *png = LTLoadImage([self class], @"IndexedWithAlpha.png");

    LTImage *image = [[LTImage alloc] initWithImage:png];

    cv::Mat expected(image.size.height, image.size.width, CV_8UC4);
    expected.setTo(cv::Vec4b(0, 64, 128, 128));

    expect($(image.mat)).to.equalMat($(expected));
  });

  it(@"should load @2x image", ^{
    UIImage *png = LTLoadImage([self class], @"LTImageNoise@2x.png");
    expect(png.scale).to.equal(2);

    LTImage *image = [[LTImage alloc] initWithImage:png];
    expect(image.size).to.equal(CGSizeMake(32, 32));

    // To do fair comparison, we rely on OpenCV's imread.
    cv::Mat4b expected(LTLoadRGBAImage([self class], @"LTImageNoise@2x"));

    expect($(image.mat)).to.equalMat($(expected));
  });

  it(@"should load 16 bit image as 8 bit", ^{
    UIImage *png = LTLoadImage([self class], @"White16.png");

    LTImage *image = [[LTImage alloc] initWithImage:png];
    expect(image.size).to.equal(CGSizeMake(16, 16));

    cv::Mat4b expected(image.size.height, image.size.width, cv::Vec4b(255, 255, 255, 255));
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
    itShouldBehaveLike(@"rotating an image", @{@"name": @"QuadLeft.jpg"});
    itShouldBehaveLike(@"rotating an image", @{@"name": @"QuadRight.jpg"});
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

  it(@"should load device gray color space for image with color space model monochrome", ^{
    auto jpeg = LTLoadImage([self class], @"Gray.jpg");
    auto image = [[LTImage alloc] initWithImage:jpeg];

    expect(CGColorSpaceGetModel(image.colorSpace)).to.equal(kCGColorSpaceModelMonochrome);
  });

  it(@"should load device RGB color space for image with color space model RGB", ^{
    auto jpeg = LTLoadImage([self class], @"White.jpg");
    auto image = [[LTImage alloc] initWithImage:jpeg];

    expect(CGColorSpaceGetModel(image.colorSpace)).to.equal(kCGColorSpaceModelRGB);
  });

  it(@"should load device RGB color space for image with color space model indexed", ^{
    auto png = LTLoadImage([self class], @"IndexedColor.png");
    auto colorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(png.CGImage));
    auto image = [[LTImage alloc] initWithImage:png];

    expect(colorSpaceModel).to.equal(kCGColorSpaceModelIndexed);
    expect(CGColorSpaceGetModel(image.colorSpace)).to.equal(kCGColorSpaceModelRGB);
  });

  it(@"should load correct colorspace for sRGB image", ^{
    auto jpeg = LTLoadImage([self class], @"White.jpg");
    auto jpegColorSpace = CGImageGetColorSpace(jpeg.CGImage);
    auto image = [[LTImage alloc] initWithImage:jpeg targetColorSpace:jpegColorSpace];

    expect(CGColorSpaceGetModel(image.colorSpace)).to.equal(CGColorSpaceGetModel(jpegColorSpace));
  });

  it(@"should load correct colorspace for monochrome image", ^{
    auto jpeg = LTLoadImage([self class], @"Gray.jpg");
    auto jpegColorSpace = CGImageGetColorSpace(jpeg.CGImage);
    auto image = [[LTImage alloc] initWithImage:jpeg targetColorSpace:jpegColorSpace];

    expect(CGColorSpaceGetModel(image.colorSpace)).to.equal(CGColorSpaceGetModel(jpegColorSpace));
  });

  it(@"should load wide gamut color space", ^{
    lt::Ref<CGColorSpaceRef> colorSpace(CGColorSpaceCreateWithName(kCGColorSpaceSRGB));

    const CGFloat sourceComponents[] = {0.5, 0.75, 0.25, 1.0};
    auto cgImageRef = LTCreatHalfFloatCGImage(2, 2, colorSpace.get(), LTVector4(sourceComponents[0],
        sourceComponents[1], sourceComponents[2], sourceComponents[3]));
    auto uiImage = [[UIImage alloc] initWithCGImage:cgImageRef.get()];

    lt::Ref<CGColorSpaceRef> p3ColorSpace(CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3));

    cv::Vec4b expectedColor = LTConvertRGBAComponents(sourceComponents, p3ColorSpace.get(),
                                                      CGImageGetRenderingIntent(cgImageRef.get()));
    cv::Mat4b expected = (cv::Mat4b(uiImage.size.height, uiImage.size.width) << expectedColor,
        expectedColor, expectedColor, expectedColor);

    auto actual = [[LTImage alloc] initWithImage:uiImage targetColorSpace:p3ColorSpace.get()];

    expect(CGColorSpaceGetModel(actual.colorSpace))
        .to.equal(CGColorSpaceGetModel((p3ColorSpace.get())));
    expect($(actual.mat)).to.beCloseToMatWithin($(expected), 1);
  });

  it(@"should load NULL color space when initialize with mat", ^{
    cv::Mat4b mat(2, 2, cv::Vec4b(255, 255, 255, 255));
    auto image = [[LTImage alloc] initWithMat:mat copy:NO colorSpace:NULL];

    expect(image).notTo.beNil();
    expect(image.colorSpace).to.beNil();
  });

  it(@"should load with image's color space", ^{
    lt::Ref<CGColorSpaceRef> colorSpace(CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3));

    auto cgImageRef = LTCreatHalfFloatCGImage(2, 2, colorSpace.get(),
        LTVector4(0.5, 0.75, 0.25, 1.0));
    auto uiImage = [[UIImage alloc] initWithCGImage:cgImageRef.get()];

    auto image = [[LTImage alloc] initWithImage:uiImage loadColorSpace:YES];
    expect(CGColorSpaceGetModel(image.colorSpace)).to.equal(CGColorSpaceGetModel(colorSpace.get()));
  });

  it(@"should deduce color space from image", ^{
    auto png = LTLoadImage([self class], @"IndexedColor.png");
    auto colorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(png.CGImage));
    auto image = [[LTImage alloc] initWithImage:png loadColorSpace:NO];

    expect(colorSpaceModel).to.equal(kCGColorSpaceModelIndexed);
    expect(CGColorSpaceGetModel(image.colorSpace)).to.equal(kCGColorSpaceModelRGB);
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

context(@"saving images", ^{
  __block NSString *path;

  beforeEach(^{
    path = [NSTemporaryDirectory() stringByAppendingString:@"_LTImageSaveTest.jpg"];
  });

  it(@"should write image to path", ^{
    UIImage *jpeg = LTLoadImage([self class], @"QuadUp.jpg");
    LTImage *expected = [[LTImage alloc] initWithImage:jpeg];

    NSError *error;
    BOOL success = [expected writeToPath:path error:&error];

    expect(error).to.beNil();
    expect(success).to.beTruthy();

    UIImage *image = [UIImage imageWithContentsOfFile:path];
    expect(image).toNot.beNil();

    LTImage *loaded = [[LTImage alloc] initWithImage:image];
    expect($(loaded.mat)).to.equalMat($(expected.mat));

    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
  });

  it(@"should write non contiguous matrices to path", ^{
    NSMutableData *data = [[NSMutableData dataWithLength:4 * 4] copy];
    cv::Mat mat(cv::Size(3, 4), CV_8U, (char *)data.bytes, 4);
    expect(mat.isContinuous()).to.beFalsy();

    LTImage *image = [[LTImage alloc] initWithMat:mat copy:NO];
    NSError *error;
    BOOL success = [image writeToPath:path error:&error];

    expect(error).to.beNil();
    expect(success).to.beTruthy();
  });
});

SpecEnd
