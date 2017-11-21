// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LTOpenExrPizCompressor.h"

#import "LTOpenCVExtensions.h"
#import "LTOpenCVHalfFloat.h"

static void LTFillImage(cv::Mat image) {
  int value = 0;

  if (image.type() == CV_16FC4) {
    std::generate(image.begin<cv::Vec4hf>(), image.end<cv::Vec4hf>(), [&value] {
      half_float::half halfValue((float)value / 255.f);
      cv::Vec4f vector(halfValue, halfValue, halfValue, halfValue);
      value = (value + 1) % 255;
      return vector;
    });
  }
}

SpecBegin(LTOpenExrPizCompressor)

__block LTOpenExrPizCompressor *compressor;
__block NSString *path;
__block NSError *error;

beforeEach(^{
  compressor = [[LTOpenExrPizCompressor alloc] init];

  path = LTTemporaryPath(@"output.openexrpiz");
  error = nil;
});

context(@"compression and decompression", ^{
  it(@"should correctly compress and decompress a one pixel mat", ^{
    cv::Mat4hf image(1, 1, cv::Vec4hf(half_float::half(1.f), half_float::half(2.f),
                                      half_float::half(3.f), half_float::half(4.f)));

    cv::Mat expected(image.clone());
    expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();

    __block cv::Mat4hf output(1, 1);
    expect([compressor decompressFromPath:path toImage:&output error:&error]).to.beTruthy();

    expect($(output)).to.equalMat($(expected));
  });

  it(@"should correctly compress and decompress a single row mat", ^{
    cv::Mat4hf image(1, 256);
    LTFillImage(image);
    cv::Mat expected(image.clone());

    expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();

    __block cv::Mat output(image.size(), image.type());
    expect([compressor decompressFromPath:path toImage:&output error:&error]).to.beTruthy();

    expect($(output)).to.equalMat($(expected));
  });

  it(@"should correctly compress and decompress a single column mat", ^{
    cv::Mat4hf image(256, 1);
    LTFillImage(image);
    cv::Mat expected(image.clone());

    expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();;

    __block cv::Mat output(image.size(), image.type());
    expect([compressor decompressFromPath:path toImage:&output error:&error]).to.beTruthy();

    expect($(output)).to.equalMat($(expected));
  });

  it(@"should correctly compress and decompress a non-continuous mat", ^{
    cv::Mat4hf image(128, 128);
    LTFillImage(image);
    cv::Mat expected(image.clone());

    cv::Mat subimage = image(cv::Rect(16, 16, 32, 32));
    expect([compressor compressImage:subimage toPath:path error:&error]).to.beTruthy();;

    __block cv::Mat output(subimage.size(), subimage.type());
    expect([compressor decompressFromPath:path toImage:&output error:&error]).to.beTruthy();

    cv::Mat expectedSubimage = expected(cv::Rect(16, 16, 32, 32));
    expect($(output)).to.equalMat($(expectedSubimage));
  });

  it(@"should correctly compress and decompress to a non-continuous mat", ^{
    cv::Mat4hf image(32, 32);
    LTFillImage(image);
    cv::Mat expected(image.clone());

    expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();;

    cv::Mat4hf output(128, 128);
    __block cv::Mat suboutput = output(cv::Rect(32, 32, 32, 32));
    expect([compressor decompressFromPath:path toImage:&suboutput error:&error]).to.beTruthy();

    expect($(suboutput)).to.equalMat($(expected));
  });

  it(@"should compress image to given path", ^{
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    expect([[NSFileManager defaultManager] fileExistsAtPath:path]).to.beFalsy();

    cv::Mat4hf image(32, 32);
    LTFillImage(image);

    expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();;
    expect([[NSFileManager defaultManager] fileExistsAtPath:path]).to.beTruthy();
  });

  it(@"should compress and decompress a real-world image", ^{
    cv::Mat4hf image;
    LTLoadMat(self.class, @"Flower.png").convertTo(image, image.type());

    cv::Mat expected(image.clone());

    expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();;

    __block cv::Mat output(image.size(), image.type());
    expect([compressor decompressFromPath:path toImage:&output error:&error]).to.beTruthy();

    expect($(output)).to.equalMat($(expected));
  });

  it(@"should compress and decompress a white-noise image", ^{
    cv::setRNGSeed(0);
    for (int i = 0; i < 20; ++i) {
      cv::Mat4s imageShort(256, 256);
      cv::randu(imageShort, cv::Scalar::all(std::numeric_limits<short>::min()),
                cv::Scalar::all(std::numeric_limits<short>::max()));

      cv::Mat4hf image;
      imageShort.convertTo(image, image.type());

      cv::Mat expected(image.clone());

      expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();;

      __block cv::Mat output(image.size(), image.type());
      expect([compressor decompressFromPath:path toImage:&output error:&error]).to.beTruthy();

      expect($(output)).to.equalMat($(expected));
    }
  });
});

context(@"error handling", ^{
  it(@"should return error when trying to write to an illegal path", ^{
    cv::Mat4hf image(1, 1, cv::Vec4hf(half_float::half(1.f), half_float::half(2.f),
                                      half_float::half(3.f), half_float::half(4.f)));
    NSString *invalidPath = @"/foo/bar";

    expect([compressor compressImage:image toPath:invalidPath error:&error]).to.beFalsy();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(LTErrorCodeFileWriteFailed);
  });

  it(@"should raise when trying to save a matrix of wrong type", ^{
    cv::Mat4f image(1, 1, cv::Vec4f(1, 2, 3, 4));
    expect(^{
      [compressor compressImage:image toPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when trying to save a matrix with zero rows", ^{
    cv::Mat4f image(0, 1);
    expect(^{
      [compressor compressImage:image toPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when trying to save a matrix with zero columns", ^{
    cv::Mat4f image(1, 0);
    expect(^{
      [compressor compressImage:image toPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should return error when trying to read from an illegal path", ^{
    __block cv::Mat4hf image(1, 1);
    NSString *invalidPath = @"/foo/bar";

    expect([compressor decompressFromPath:invalidPath toImage:&image error:&error]).to.beFalsy();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(LTErrorCodeFileReadFailed);
  });

  it(@"should raise when trying to read to a matrix of wrong type", ^{
    cv::Mat4f image(1, 1, cv::Vec4f(1, 2, 3, 4));
    expect(^{
      [compressor compressImage:image toPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when trying to read to a matrix with zero rows", ^{
    cv::Mat4hf image(1, 1, cv::Vec4hf(half_float::half(1.f), half_float::half(2.f),
                                      half_float::half(3.f), half_float::half(4.f)));
    expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();

    __block cv::Mat4hf output(0, 1);
    expect(^{
      [compressor decompressFromPath:path toImage:&output error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when trying to read to a matrix with zero columns", ^{
    cv::Mat4hf image(1, 1, cv::Vec4hf(half_float::half(1.f), half_float::half(2.f),
                                      half_float::half(3.f), half_float::half(4.f)));
    expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();

    __block cv::Mat4hf output(1, 0);
    expect(^{
      [compressor decompressFromPath:path toImage:&output error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should return error when trying to read into matrix with size other than size of the "
     "original matrix", ^{
    cv::Mat4hf image(1, 1, cv::Vec4hf(half_float::half(1.f), half_float::half(2.f),
                                     half_float::half(3.f), half_float::half(4.f)));
    expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();

    __block cv::Mat4hf output(2, 2);

    expect([compressor decompressFromPath:path toImage:&output error:&error]).to.beFalsy();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(LTErrorCodeFileReadFailed);
  });
});
SpecEnd
