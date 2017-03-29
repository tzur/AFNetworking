// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureIZArchiver.h"

#import <LTKit/NSError+LTKit.h>

#import "LTIZCompressor.h"
#import "LTTexture+Factory.h"

@interface LTFakeIZCompressor : LTIZCompressor

/// Fails all the next compressions with the given \c error.
- (void)failOnCompressionWithError:(NSError *)error;

/// Fails all the next decompressions with the given \c error.
- (void)failOnDecompressionWithError:(NSError *)error;

/// Fails all the next calls to shardsPathsOfCompressedImageFromPath:error with the given \c error.
- (void)failOnShardPathWithError:(NSError *)error;

/// Error to apply on compression.
@property (readonly, nonatomic) NSError *compressionError;

/// Error to apply on decompression.
@property (readonly, nonatomic) NSError *decompressionError;

/// Error to apply on shard path.
@property (readonly, nonatomic) NSError *shardPathsError;

/// Image sent to compression.
@property (readonly, nonatomic) cv::Mat4b compressedImage;

/// Path sent to compression.
@property (readonly, nonatomic) NSString *compressedPath;

/// Image sent to decompression.
@property (readonly, nonatomic) cv::Mat4b decompressedImage;

/// Path sent to decompression.
@property (readonly, nonatomic) NSString *decompressedPath;

/// Shard paths to return.
@property (strong, nonatomic) NSArray *shardPaths;

/// Shard paths given path.
@property (readonly, nonatomic) NSString *shardPathsPath;

/// \c YES if the image was sent to compression with alpha channel.
@property (readonly, nonatomic) BOOL compressedWithAlphaChannel;

@end

@implementation LTFakeIZCompressor

- (void)failOnCompressionWithError:(NSError *)error {
  _compressionError = error;
}

- (void)failOnDecompressionWithError:(NSError *)error {
  _decompressionError = error;
}

- (void)failOnShardPathWithError:(NSError *)error {
  _shardPathsError = error;
}

- (BOOL)compressImage:(const cv::Mat &)image toPath:(NSString *)path
                error:(NSError * __autoreleasing *)error withAlpha:(BOOL)withAlpha {
  _compressedImage = image.clone();
  _compressedPath = path;
  _compressedWithAlphaChannel = withAlpha;

  if (self.compressionError) {
    if (error) {
      *error = self.compressionError;
    }
    return NO;
  }
  return YES;
}

- (BOOL)decompressFromPath:(NSString *)path toImage:(cv::Mat *)image
                     error:(NSError * __autoreleasing *)error {
  _decompressedPath = path;
  _decompressedImage = image->clone();

  if (self.decompressionError) {
    if (error) {
      *error = self.decompressionError;
    }
    return NO;
  }
  return YES;
}

- (nullable NSArray *)shardsPathsOfCompressedImageFromPath:(NSString *)path
                                                     error:(NSError * __autoreleasing *)error {
  _shardPathsPath = path;

  if (self.shardPathsError) {
    if (error) {
      *error = self.shardPathsError;
    }
    return nil;
  }

  return self.shardPaths;
}

@end

SpecBegin(LTTextureIZArchiver)

static NSString * const kPath = @"archive.iz";

__block LTFakeIZCompressor *compressor;
__block LTTextureIZArchiver *archiver;

beforeEach(^{
  compressor = LTBindObjectToClass([[LTFakeIZCompressor alloc] init], [LTIZCompressor class]);
  archiver = [[LTTextureIZArchiver alloc] init];
});

context(@"archiving", ^{
  static NSError * const kCompressionError = [NSError errorWithDomain:@"foo" code:1337
                                                             userInfo:nil];

  __block LTTexture *texture;
  __block NSError *error;

  beforeEach(^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(8, 16)];
    [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->rowRange(0, 8).setTo(cv::Vec4b(255, 0, 0, 255));
      mapped->rowRange(8, 16).setTo(cv::Vec4b(0, 255, 0, 255));
    }];
  });

  afterEach(^{
    texture = nil;
    error = nil;
  });

  it(@"should archive a valid input correctly", ^{
    BOOL result = [archiver archiveTexture:texture inPath:kPath error:&error];

    expect(error).to.beNil();
    expect(result).to.beTruthy();

    expect(compressor.compressedPath).to.equal(kPath);
    expect($(compressor.compressedImage)).to.equalMat($([texture image]));
    expect(compressor.compressedWithAlphaChannel).to.beFalsy();
  });

  it(@"should archive a valid input with alpha channel correctly", ^{
    texture.usingAlphaChannel = YES;
    [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->rowRange(0, 8).setTo(cv::Vec4b(255, 0, 0, 128));
      mapped->rowRange(8, 16).setTo(cv::Vec4b(0, 255, 0, 200));
    }];

    BOOL result = [archiver archiveTexture:texture inPath:kPath error:&error];

    expect(error).to.beNil();
    expect(result).to.beTruthy();
    expect(compressor.compressedPath).to.equal(kPath);
    expect($(compressor.compressedImage)).to.equalMat($([texture image]));
    expect(compressor.compressedWithAlphaChannel).to.beTruthy();
  });

  it(@"should raise if trying to archive half float precision texture", ^{
    LTTexture *halfFloatTexture = [LTTexture textureWithSize:texture.size
                                                 pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                              allocateMemory:YES];
    expect(^{
      [archiver archiveTexture:halfFloatTexture inPath:kPath error:&error];
    }).to.raise(NSInvalidArgumentException);
    expect(compressor.compressedPath).to.beNil();
  });

  it(@"should raise if trying to archive float precision texture", ^{
    LTTexture *floatTexture = [LTTexture textureWithSize:texture.size
                                             pixelFormat:$(LTGLPixelFormatRGBA32Float)
                                          allocateMemory:YES];
    expect(^{
      [archiver archiveTexture:floatTexture inPath:kPath error:&error];
    }).to.raise(NSInvalidArgumentException);
    expect(compressor.compressedPath).to.beNil();
  });

  it(@"should err if compressor failed compressing the texture", ^{
    [compressor failOnCompressionWithError:kCompressionError];

    BOOL result = [archiver archiveTexture:texture inPath:kPath error:&error];

    expect(error).to.equal(kCompressionError);
    expect(result).to.beFalsy();
  });
});

context(@"unarchiving", ^{
  static NSError * const kDecompressionError = [NSError errorWithDomain:@"bar" code:1337
                                                               userInfo:nil];

  __block LTTexture *texture;
  __block NSError *error;

  beforeEach(^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(8, 16)];
    error = nil;
  });

  afterEach(^{
    texture = nil;
  });

  it(@"should unarchive a valid input correctly", ^{
    BOOL result = [archiver unarchiveToTexture:texture fromPath:kPath error:&error];

    expect(result).to.beTruthy();
    expect(error).to.beNil();

    expect(compressor.decompressedPath).to.equal(kPath);
    expect($(compressor.decompressedImage)).to.equalMat($(texture.image));
  });

  it(@"should unarchive a valid input correctly with usingAlphaChannel set to YES", ^{
    texture.usingAlphaChannel = YES;
    BOOL result = [archiver unarchiveToTexture:texture fromPath:kPath error:&error];

    expect(result).to.beTruthy();
    expect(error).to.beNil();

    expect(compressor.decompressedPath).to.equal(kPath);
    expect($(compressor.decompressedImage)).to.equalMat($(texture.image));
  });

  it(@"should raise if trying to unarchive half float precision texture", ^{
    LTTexture *halfFloatTexture = [LTTexture textureWithSize:texture.size
                                                 pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                              allocateMemory:YES];
    expect(^{
      [archiver unarchiveToTexture:halfFloatTexture fromPath:kPath error:&error];
    }).to.raise(NSInvalidArgumentException);
    expect(compressor.compressedPath).to.beNil();
  });

  it(@"should raise if trying to unarchive float precision texture", ^{
    LTTexture *floatTexture = [LTTexture textureWithSize:texture.size
                                             pixelFormat:$(LTGLPixelFormatRGBA32Float)
                                          allocateMemory:YES];
    expect(^{
      [archiver unarchiveToTexture:floatTexture fromPath:kPath error:&error];
    }).to.raise(NSInvalidArgumentException);
    expect(compressor.compressedPath).to.beNil();
  });

  it(@"should err if compressor failed decompressing the texture", ^{
    [compressor failOnDecompressionWithError:kDecompressionError];

    BOOL result = [archiver unarchiveToTexture:texture fromPath:kPath error:&error];

    expect(error).to.equal(kDecompressionError);
    expect(result).to.beFalsy();
  });
});

SpecEnd
