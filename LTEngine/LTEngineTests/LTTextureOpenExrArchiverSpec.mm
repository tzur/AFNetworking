// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LTTextureOpenExrArchiver.h"

#import "LTTexture+Factory.h"

SpecBegin(LTTextureOpenExrArchiver)

__block LTTextureOpenExrArchiver *archiver;
__block LTTexture *texture;
__block NSError *error;
__block NSString *path;

beforeEach(^{
  archiver = [[LTTextureOpenExrArchiver alloc] init];

  texture = [LTTexture halfFloatRGBATextureWithSize:CGSizeMake(8, 16)];
  [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    mapped->rowRange(0, 8).setTo(cv::Vec4hf(half_float::half(1.f), half_float::half(0.f),
                                            half_float::half(0.f), half_float::half(1.f)));
    mapped->rowRange(8, 16).setTo(cv::Vec4hf(half_float::half(0.f), half_float::half(1.f),
                                             half_float::half(1.f), half_float::half(0.f)));
  }];

  path = LTTemporaryPath(@"output.openexrpiz");
});

afterEach(^{
  texture = nil;
  error = nil;
});

context(@"archiving", ^{
  it(@"should archive valid input and unarchive it to texture correctly", ^{
    BOOL result = [archiver archiveTexture:texture inPath:path error:&error];
    expect(error).to.beNil();
    expect(result).to.beTruthy();

    __block LTTexture *output = [LTTexture halfFloatRGBATextureWithSize:CGSizeMake(8, 16)];

    result = [archiver unarchiveToTexture:output fromPath:path error:&error];
    expect(error).to.beNil();
    expect(result).to.beTruthy();

    [texture mappedImageForReading:^(const cv::Mat &mappedInput, BOOL) {
      [output mappedImageForReading:^(const cv::Mat &mappedOutput, BOOL) {
        expect($(mappedOutput)).to.equalMat($(mappedInput));
      }];
    }];
  });

  it(@"should archive valid input and unarchive it to matrix correctly", ^{
    BOOL result = [archiver archiveTexture:texture inPath:path error:&error];
    expect(error).to.beNil();
    expect(result).to.beTruthy();

    cv::Mat4hf output(16, 8);

    result = [archiver unarchiveToMat:&output fromPath:path error:&error];
    expect(error).to.beNil();
    expect(result).to.beTruthy();

    [texture mappedImageForReading:^(const cv::Mat &mappedInput, BOOL) {
      expect($(output)).to.equalMat($(mappedInput));
    }];
  });

  it(@"should raise if trying to archive 8-bit precision texture", ^{
    LTTexture *rgbaByteTexture = [LTTexture textureWithSize:texture.size
                                                pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                             allocateMemory:YES];
    expect(^{
      [archiver archiveTexture:rgbaByteTexture inPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if trying to archive float precision texture", ^{
    LTTexture *floatTexture = [LTTexture textureWithSize:texture.size
                                             pixelFormat:$(LTGLPixelFormatRGBA32Float)
                                          allocateMemory:YES];
    expect(^{
      [archiver archiveTexture:floatTexture inPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if trying to archive half-float grayscale texture", ^{
    LTTexture *grayscaleTexture = [LTTexture textureWithSize:texture.size
                                                 pixelFormat:$(LTGLPixelFormatR16Float)
                                              allocateMemory:YES];
    expect(^{
      [archiver archiveTexture:grayscaleTexture inPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"unarchiving", ^{
  beforeEach(^{
    BOOL result = [archiver archiveTexture:texture inPath:path error:&error];
    expect(error).to.beNil();
    expect(result).to.beTruthy();
  });

  afterEach(^{
    texture = nil;
  });

  it(@"should raise if trying to unarchive to 8-bit precision texture", ^{
    LTTexture *rgbaByteTexture = [LTTexture textureWithSize:texture.size
                                                pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                             allocateMemory:YES];
    expect(^{
      [archiver unarchiveToTexture:rgbaByteTexture fromPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if trying to unarchive to float precision texture", ^{
    LTTexture *floatTexture = [LTTexture textureWithSize:texture.size
                                             pixelFormat:$(LTGLPixelFormatRGBA32Float)
                                          allocateMemory:YES];
    expect(^{
      [archiver unarchiveToTexture:floatTexture fromPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if trying to unarchive to half-float grayscale texture", ^{
    LTTexture *grayscaleTexture = [LTTexture textureWithSize:texture.size
                                             pixelFormat:$(LTGLPixelFormatR16Float)
                                          allocateMemory:YES];
    expect(^{
      [archiver unarchiveToTexture:grayscaleTexture fromPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if trying to unarchive to 8-bit precision matrix", ^{
    __block cv::Mat4b rgbaByteMatrix(texture.size.height, texture.size.width);
    expect(^{
      [archiver unarchiveToMat:&rgbaByteMatrix fromPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if trying to unarchive to float precision matrix", ^{
    __block cv::Mat4f rgbaFloatMatrix(texture.size.height, texture.size.width);
    expect(^{
      [archiver unarchiveToMat:&rgbaFloatMatrix fromPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if trying to unarchive to half-float grayscale matrix", ^{
    __block cv::Mat1hf grayscaleMatrix(texture.size.height, texture.size.width);
    expect(^{
      [archiver unarchiveToMat:&grayscaleMatrix fromPath:path error:&error];
    }).to.raise(NSInvalidArgumentException);
  });
});

SpecEnd
