// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTIZCompressor.h"

#import <LTKit/NSError+LTKit.h>

#import "LTIZHeader.h"
#import "LTOpenCVExtensions.h"

static void LTFillImage(cv::Mat image) {
  int value = 0;

  if (image.type() == CV_8UC4) {
    std::generate(image.begin<cv::Vec4b>(), image.end<cv::Vec4b>(), [&value] {
      cv::Vec4b vector(value, value, value, 255);
      value = (value + 1) % 255;
      return vector;
    });
  } else if (image.type() == CV_8UC1) {
    std::generate(image.begin<uchar>(), image.end<uchar>(), [&value] {
      value = (value + 1) % 255;
      return value;
    });
  }
}

SpecBegin(LTIZCompressor)

__block LTIZCompressor *compressor;

__block NSString *path;
__block NSError *error;

beforeEach(^{
  compressor = [[LTIZCompressor alloc] init];

  LTCreateTemporaryDirectory();

  path = LTTemporaryPath(@"output.iz");
  error = nil;
});

afterEach(^{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  for (NSString *file in [fileManager enumeratorAtPath:LTTemporaryPath()]) {
    NSString *path = [LTTemporaryPath() stringByAppendingPathComponent:file];
    [fileManager removeItemAtPath:path error:nil];
  }
});

static NSString * const kImageZeroSharedExamples = @"ImageZero Shared Examples";
static NSString * const kImageZeroTypeKey = @"type";
static NSString * const kImageZeroOnePixelKey = @"onePixel";
static NSString * const kImageZeroComplexImageKey = @"complexImage";
static NSString * const kImageZeroReadWorldPathKey = @"realWorldPath";

sharedExamplesFor(kImageZeroSharedExamples, ^(NSDictionary *data) {
  __block int type;

  beforeEach(^{
    type = [data[kImageZeroTypeKey] intValue];
  });

  context(@"compression and decompression", ^{
    it(@"should correctly compress and decompress a zero pixel mat", ^{
      cv::Mat image(0, 0, type);
      cv::Mat expected(image.clone());
      expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();

      __block cv::Mat output;
      expect([compressor decompressFromPath:path toImage:&output error:&error]).to.beTruthy();

      // Creating a new Mat since theoretically compression may mutate the input.
      expect($(output)).to.equalMat($(expected));
    });

    it(@"should correctly compress and decompress a one pixel mat", ^{
      cv::Mat image([data[kImageZeroOnePixelKey] matValue]);
      cv::Mat expected(image.clone());
      expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();

      __block cv::Mat output(image.size(), image.type());
      expect([compressor decompressFromPath:path toImage:&output error:&error]).to.beTruthy();

      expect($(output)).to.equalMat($(expected));
    });

    it(@"should correctly compress and decompress a single row mat", ^{
      cv::Mat image(1, 256, type);
      LTFillImage(image);
      cv::Mat expected(image.clone());

      expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();

      __block cv::Mat output(image.size(), image.type());
      expect([compressor decompressFromPath:path toImage:&output error:&error]).to.beTruthy();

      expect($(output)).to.equalMat($(expected));
    });

    it(@"should correctly compress and decompress a single column mat", ^{
      cv::Mat image(256, 1, type);
      LTFillImage(image);
      cv::Mat expected(image.clone());

      expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();

      __block cv::Mat output(image.size(), image.type());
      expect([compressor decompressFromPath:path toImage:&output error:&error]).to.beTruthy();

      expect($(output)).to.equalMat($(expected));
    });

    it(@"should correctly compress and decompress a non-continuous mat", ^{
      cv::Mat image(128, 128, type);
      LTFillImage(image);
      cv::Mat expected(image.clone());

      cv::Mat subimage = image(cv::Rect(16, 16, 32, 32));
      expect([compressor compressImage:subimage toPath:path error:&error]).to.beTruthy();

      __block cv::Mat output(subimage.size(), subimage.type());
      expect([compressor decompressFromPath:path toImage:&output error:&error]).to.beTruthy();

      cv::Mat expectedSubimage = expected(cv::Rect(16, 16, 32, 32));
      expect($(output)).to.equalMat($(expectedSubimage));
    });

    it(@"should correctly compress and decompress to a non-continuous mat", ^{
      cv::Mat image(32, 32, type);
      LTFillImage(image);
      cv::Mat expected(image.clone());

      expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();

      cv::Mat output(128, 128, type);
      __block cv::Mat suboutput = output(cv::Rect(32, 32, 32, 32));
      expect([compressor decompressFromPath:path toImage:&suboutput error:&error]).to.beTruthy();

      expect($(suboutput)).to.equalMat($(expected));
    });

    it(@"should compress image to given path", ^{
      [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
      expect([[NSFileManager defaultManager] fileExistsAtPath:path]).to.beFalsy();

      cv::Mat image(32, 32, type);
      LTFillImage(image);

      expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();
      expect([[NSFileManager defaultManager] fileExistsAtPath:path]).to.beTruthy();
    });

    it(@"should compress and decompress a real-world image", ^{
      cv::Mat image(LTLoadMat(self.class, data[kImageZeroReadWorldPathKey]));
      cv::Mat expected(image.clone());

      expect([compressor compressImage:image toPath:path error:&error]).to.beTruthy();

      __block cv::Mat output(image.size(), image.type());
      expect([compressor decompressFromPath:path toImage:&output error:&error]).to.beTruthy();

      expect($(output)).to.equalMat($(expected));
    });
  });

  context(@"compression size", ^{
    it(@"should not create image larger than the maximal size for a single pixel image", ^{
      cv::Mat image([data[kImageZeroOnePixelKey] matValue]);
      size_t maximalSize = [LTIZCompressor maximalCompressedSizeForImage:image];

      [compressor compressImage:image toPath:path error:nil];
      unsigned long long size = [[NSFileManager defaultManager]
                                 attributesOfItemAtPath:path error:nil].fileSize;

      expect(size).to.beLessThanOrEqualTo(maximalSize);
    });

    it(@"should not create image larget than the maximal size for a complex image", ^{
      cv::Mat image([data[kImageZeroComplexImageKey] matValue]);
      size_t maximalSize = [LTIZCompressor maximalCompressedSizeForImage:image];

      [compressor compressImage:image toPath:path error:nil];
      unsigned long long size = [[NSFileManager defaultManager]
                                 attributesOfItemAtPath:path error:nil].fileSize;

      expect(size).to.beLessThanOrEqualTo(maximalSize);
    });

    // TODO:(yaron) find the worst-case image for this algorithm and test on an instance of it.
  });
});

itShouldBehaveLike(kImageZeroSharedExamples, ^{
  cv::Mat4b image(2, 2, cv::Vec4b(255, 255, 255, 255));
  image(0, 1) = cv::Vec4b(128, 0, 0, 255);
  image(1, 0) = cv::Vec4b(0, 128, 128, 255);

  return @{
    kImageZeroTypeKey: @(CV_8UC1),
    kImageZeroOnePixelKey: $(cv::Mat4b(1, 1, cv::Vec4b(24, 72, 56, 255))),
    kImageZeroComplexImageKey: $(image),
    kImageZeroReadWorldPathKey: @"Lena.png"
  };
});

itShouldBehaveLike(kImageZeroSharedExamples, ^{
  cv::Mat1b image(2, 2, 255);
  image(0, 1) = 128;
  image(1, 0) = 0;

  return @{
    kImageZeroTypeKey: @(CV_8UC4),
    kImageZeroOnePixelKey: $(cv::Mat1b(1, 1, 58)),
    kImageZeroComplexImageKey: $(image),
    kImageZeroReadWorldPathKey: @"ImageZeroGrayscale.png"
  };
});

context(@"header parsing", ^{
  it(@"should not err when correct header is given", ^{
    LTIZHeader header = {
      .signature = kLTIZHeaderSignature,
      .version = 1,
      .channels = 3,
      .totalWidth = 1,
      .totalHeight = 1,
      .shardWidth = 1,
      .shardHeight = 1,
      .shardIndex = 0,
      .shardCount = 1
    };

    char bytes[] = {'\xf0', '\xf1', '\x05', '\xe9'};
    NSMutableData *data = [NSMutableData dataWithBytes:&header length:sizeof(header)];
    [data appendBytes:bytes length:sizeof(bytes)];
    [data writeToFile:path atomically:YES];

    __block cv::Mat4b image(1, 1);
    expect([compressor decompressFromPath:path toImage:&image error:&error]).to.beTruthy();
    expect(error).to.beNil();
  });

  it(@"should err when decompressing file size smaller than the header size", ^{
    char bytes[] = {'A', 'B', 'C'};
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    [data writeToFile:path atomically:YES];

    __block cv::Mat4b image;
    expect([compressor decompressFromPath:path toImage:&image error:&error]).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeFileReadFailed);
  });

  it(@"should err when decompressing header with invalid signature", ^{
    LTIZHeader header = {
      .signature = kLTIZHeaderSignature,
      .version = 1,
      .channels = 3,
      .totalWidth = 1,
      .totalHeight = 1,
      .shardWidth = 1,
      .shardHeight = 1,
      .shardIndex = 0,
      .shardCount = 1
    };
    NSData *data = [NSData dataWithBytes:&header length:sizeof(header)];
    [data writeToFile:path atomically:YES];

    __block cv::Mat4b image;
    expect([compressor decompressFromPath:path toImage:&image error:&error]).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeBadHeader);
  });

  it(@"should err when decompressing header with invalid version", ^{
    LTIZHeader header = {
      .signature = kLTIZHeaderSignature,
      .version = 1337,
      .channels = 3,
      .totalWidth = 1,
      .totalHeight = 1,
      .shardWidth = 1,
      .shardHeight = 1,
      .shardIndex = 0,
      .shardCount = 1
    };
    NSData *data = [NSData dataWithBytes:&header length:sizeof(header)];
    [data writeToFile:path atomically:YES];

    __block cv::Mat4b image;
    expect([compressor decompressFromPath:path toImage:&image error:&error]).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeBadHeader);
  });

  it(@"should err when decompressing header with invalid number of channels", ^{
    LTIZHeader header = {
      .signature = kLTIZHeaderSignature,
      .version = 1337,
      .channels = 2,
      .totalWidth = 1,
      .totalHeight = 1,
      .shardWidth = 1,
      .shardHeight = 1,
      .shardIndex = 0,
      .shardCount = 1
    };
    NSData *data = [NSData dataWithBytes:&header length:sizeof(header)];
    [data writeToFile:path atomically:YES];

    __block cv::Mat4b image;
    expect([compressor decompressFromPath:path toImage:&image error:&error]).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeBadHeader);
  });

  it(@"should err when decompressing header to mat with invalid number of channels", ^{
    LTIZHeader header = {
      .signature = kLTIZHeaderSignature,
      .version = 1337,
      .channels = 1,
      .totalWidth = 1,
      .totalHeight = 1,
      .shardWidth = 1,
      .shardHeight = 1,
      .shardIndex = 0,
      .shardCount = 1
    };
    NSData *data = [NSData dataWithBytes:&header length:sizeof(header)];
    [data writeToFile:path atomically:YES];

    __block cv::Mat4b image;
    expect([compressor decompressFromPath:path toImage:&image error:&error]).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeBadHeader);
  });
  
  it(@"should err when decompressing to mat with invalid size", ^{
    LTIZHeader header = {
      .signature = kLTIZHeaderSignature,
      .version = 1,
      .channels = 3,
      .totalWidth = 2,
      .totalHeight = 2,
      .shardWidth = 1,
      .shardHeight = 1,
      .shardIndex = 0,
      .shardCount = 1
    };
    NSData *data = [NSData dataWithBytes:&header length:sizeof(header)];
    [data writeToFile:path atomically:YES];

    __block cv::Mat4b image(1, 1);
    expect([compressor decompressFromPath:path toImage:&image error:&error]).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeBadHeader);
  });

  it(@"should err when shard index is larger than shard count", ^{
    LTIZHeader header = {
      .signature = kLTIZHeaderSignature,
      .version = 1,
      .channels = 3,
      .totalWidth = 1,
      .totalHeight = 1,
      .shardWidth = 1,
      .shardHeight = 1,
      .shardIndex = 1,
      .shardCount = 1
    };
    NSData *data = [NSData dataWithBytes:&header length:sizeof(header)];
    [data writeToFile:path atomically:YES];

    __block cv::Mat4b image(1, 1);
    expect([compressor decompressFromPath:path toImage:&image error:&error]).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeBadHeader);
  });

  it(@"should err when shard size is invalid", ^{
    LTIZHeader header = {
      .signature = kLTIZHeaderSignature,
      .version = 1,
      .channels = 3,
      .totalWidth = 2,
      .totalHeight = 2,
      .shardWidth = 2,
      .shardHeight = 2,
      .shardIndex = 0,
      .shardCount = 2
    };
    NSData *data = [NSData dataWithBytes:&header length:sizeof(header)];
    [data writeToFile:path atomically:YES];

    __block cv::Mat4b image(2, 2);
    expect([compressor decompressFromPath:path toImage:&image error:&error]).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeFileReadFailed);
  });

  it(@"should err when shard count is zero", ^{
    LTIZHeader header = {
      .signature = kLTIZHeaderSignature,
      .version = 1,
      .channels = 3,
      .totalWidth = 1,
      .totalHeight = 1,
      .shardWidth = 1,
      .shardHeight = 1,
      .shardIndex = 0,
      .shardCount = 0
    };
    NSData *data = [NSData dataWithBytes:&header length:sizeof(header)];
    [data writeToFile:path atomically:YES];

    __block cv::Mat4b image(1, 1);
    expect([compressor decompressFromPath:path toImage:&image error:&error]).to.beFalsy();
    expect(error.domain).to.equal(kLTErrorDomain);
    expect(error.code).to.equal(LTErrorCodeBadHeader);
  });
});

context(@"large inputs", ^{
  it(@"should raise when compressing very large images", ^{
    __block cv::Mat4b image(1, 90210);
    expect(^{
      [compressor compressImage:image toPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"shard paths", ^{
  it(@"should return all shard paths given the first shard path", ^{
    LTIZHeader header = {
      .signature = ('Z' << CHAR_BIT) + 'I',
      .version = 1,
      .channels = 3,
      .totalWidth = 1,
      .totalHeight = 1,
      .shardWidth = 1,
      .shardHeight = 1,
      .shardIndex = 0,
      .shardCount = 3
    };

    char bytes[] = {'\xf0', '\xf1', '\x05', '\xe9'};
    NSMutableData *data = [NSMutableData dataWithBytes:&header length:sizeof(header)];
    [data appendBytes:bytes length:sizeof(bytes)];
    [data writeToFile:path atomically:YES];

    NSArray *paths = [compressor shardsPathsOfCompressedImageFromPath:path error:&error];
    expect(error).to.beNil();
    expect(paths).to.equal((@[
      path,
      [path stringByAppendingPathExtension:@"1"],
      [path stringByAppendingPathExtension:@"2"]
    ]));
  });

  it(@"should error when given a non-initial shard", ^{
    LTIZHeader header = {
      .signature = kLTIZHeaderSignature,
      .version = 1,
      .channels = 3,
      .totalWidth = 1,
      .totalHeight = 1,
      .shardWidth = 1,
      .shardHeight = 1,
      .shardIndex = 1,
      .shardCount = 3
    };

    char bytes[] = {'\xf0', '\xf1', '\x05', '\xe9'};
    NSMutableData *data = [NSMutableData dataWithBytes:&header length:sizeof(header)];
    [data appendBytes:bytes length:sizeof(bytes)];
    [data writeToFile:path atomically:YES];

    NSArray *paths = [compressor shardsPathsOfCompressedImageFromPath:path error:&error];
    expect(error).notTo.beNil();
    expect(paths).to.beNil();
  });
});

SpecEnd
