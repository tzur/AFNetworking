// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureUncompressedMatArchiver.h"

#import <LTKit/LTImageLoader.h>
#import <LTKit/NSError+LTKit.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "LTImage.h"
#import "LTTexture+Factory.h"

static BOOL LTSaveMat(const cv::Mat &mat, NSString *relativePath) {
  NSUInteger matSize = mat.total() * mat.elemSize();
  NSMutableData *data = [NSMutableData dataWithLength:matSize];
  cv::Mat continuousMat(mat.rows, mat.cols, mat.type(), data.mutableBytes);
  mat.copyTo(continuousMat);
  NSFileManager *fileManager = [JSObjection defaultInjector][[NSFileManager class]];
  return [fileManager lt_writeData:data toFile:LTTemporaryPath(relativePath)
                           options:NSDataWritingAtomic error:nil];
}

static BOOL LTLoadIntoMat(NSString *relativePath, cv::Mat *mat) {
  NSFileManager *fileManager = [JSObjection defaultInjector][[NSFileManager class]];
  NSData *data = [fileManager lt_dataWithContentsOfFile:LTTemporaryPath(relativePath)
                                                options:NSDataReadingUncached error:nil];

  if (!data) {
    return NO;
  }

  LTParameterAssert(data.length == mat->total() * mat->elemSize());
  cv::Mat storedMat(mat->rows, mat->cols, mat->type(), (void *)data.bytes);
  storedMat.copyTo(*mat);

  return YES;
}

SpecBegin(LTTextureUncompressedMatArchiver)

__block LTTextureUncompressedMatArchiver *archiver;
__block LTTexture *texture;
__block NSError *error;
__block id fileManager;
__block BOOL result;

static NSError * const kFakeError = [NSError errorWithDomain:@"foo" code:1337 userInfo:nil];

beforeEach(^{
  fileManager = OCMPartialMock([NSFileManager defaultManager]);
  LTBindObjectToClass(fileManager, [NSFileManager class]);
  archiver = [[LTTextureUncompressedMatArchiver alloc] init];

  NSString *path = LTTemporaryPath();
  OCMStub([fileManager lt_documentsDirectory]).andReturn(path);
  [fileManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
});

afterEach(^{
  [fileManager removeItemAtPath:LTTemporaryPath() error:nil];
  archiver = nil;
  texture = nil;
  error = nil;
  result = NO;
  [fileManager stopMocking];
  fileManager = nil;
});

context(@"archiving", ^{
  beforeEach(^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(8, 16)];
    [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->rowRange(0, 8).setTo(cv::Vec4b(255, 0, 0, 128));
      mapped->rowRange(8, 16).setTo(cv::Vec4b(0, 255, 0, 255));
    }];
  });

  it(@"should archive correctly", ^{
    result = [archiver archiveTexture:texture inPath:LTTemporaryPath(@"archive.mat") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.mat")).to.beTruthy();

    __block cv::Mat4b stored(texture.size.height, texture.size.width);
    expect(LTLoadIntoMat(@"archive.mat", &stored)).to.beTruthy();
    expect($(stored)).to.beCloseToMat($(texture.image));
  });

  it(@"should archive single channel texture", ^{
    texture = [LTTexture byteRedTextureWithSize:texture.size];
    [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->rowRange(0, 8).setTo(64);
      mapped->rowRange(8, 16).setTo(192);
    }];

    result = [archiver archiveTexture:texture inPath:LTTemporaryPath(@"archive.mat") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.mat")).to.beTruthy();

    __block cv::Mat1b stored(texture.size.height, texture.size.width);
    expect(LTLoadIntoMat(@"archive.mat", &stored)).to.beTruthy();
    expect($(stored)).to.beCloseToMat($(texture.image));
  });
  
  it(@"should archive half float texture", ^{
    LTTexture *halfFloatTexture = [LTTexture textureWithSize:texture.size
                                                 pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                              allocateMemory:YES];
    [texture cloneTo:halfFloatTexture];

    result = [archiver archiveTexture:halfFloatTexture
                               inPath:LTTemporaryPath(@"archive.mat") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.mat")).to.beTruthy();

    __block cv::Mat4hf stored(texture.size.height, texture.size.width);
    expect(LTLoadIntoMat(@"archive.mat", &stored)).to.beTruthy();
    expect($(stored)).to.beCloseToMat($(halfFloatTexture.image));
  });

  pending(@"should archive float texture", ^{
    cv::Mat4f mat(texture.size.height, texture.size.width);
    mat.rowRange(0, 8).setTo(cv::Vec4f(0.25f, 0.5f, 0.75f, 1.0f));
    mat.rowRange(8, 16).setTo(cv::Vec4f(0.75f, 0.5f, 0.25f, 1.0f));
    texture = [LTTexture textureWithImage:mat];
    
    result = [archiver archiveTexture:texture inPath:LTTemporaryPath(@"archive.mat") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.mat")).to.beTruthy();

    __block cv::Mat4f stored(texture.size.height, texture.size.width);
    expect(LTLoadIntoMat(@"archive.mat", &stored)).to.beTruthy();
    expect($(stored)).to.beCloseToMat($(mat));
  });

  it(@"should archive texture using the alpha channel", ^{
    texture.usingAlphaChannel = YES;
    expect(^{
      [archiver archiveTexture:texture inPath:LTTemporaryPath(@"archive.mat") error:&error];
    }).notTo.raise(NSInvalidArgumentException);
  });

  it(@"should return error if failed to archive the texture", ^{
    OCMStub([fileManager lt_writeData:[OCMArg any] toFile:LTTemporaryPath(@"archive.mat")
                              options:NSDataWritingAtomic
                                error:[OCMArg setTo:kFakeError]]).andReturn(NO);
    result = [archiver archiveTexture:texture inPath:LTTemporaryPath(@"archive.mat") error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileWriteFailed);
    expect(error.userInfo[NSUnderlyingErrorKey]).to.equal(kFakeError);
  });
});

context(@"unarchiving", ^{
  it(@"should unarchive correctly", ^{
    cv::Mat4b mat(32, 16);
    mat.rowRange(0, 16).setTo(cv::Vec4b(255, 0, 0, 255));
    mat.rowRange(16, 32).setTo(cv::Vec4b(0, 255, 0, 255));
    expect(LTSaveMat(mat, @"archive.mat")).to.beTruthy();

    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(mat.cols, mat.rows)];
    result = [archiver unarchiveToTexture:texture
                                 fromPath:LTTemporaryPath(@"archive.mat") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect($(texture.image)).to.beCloseToMat($(mat));
  });

  it(@"should unarchive single channel texture", ^{
    cv::Mat1b mat(32, 16);
    mat.rowRange(0, 16).setTo(64);
    mat.rowRange(16, 32).setTo(192);
    expect(LTSaveMat(mat, @"archive.mat")).to.beTruthy();

    texture = [LTTexture byteRedTextureWithSize:CGSizeMake(mat.cols, mat.rows)];
    result = [archiver unarchiveToTexture:texture
                                 fromPath:LTTemporaryPath(@"archive.mat") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect($(texture.image)).to.beCloseToMat($(mat));
  });
  
  it(@"should unarchive half float texture", ^{
    using half_float::half;
    cv::Mat4hf mat(32, 16);
    mat.rowRange(0, 16).setTo(cv::Vec4hf(half(0.25), half(0.5), half(0.75), half(1.0)));
    expect(LTSaveMat(mat, @"archive.mat")).to.beTruthy();

    texture = [LTTexture textureWithSize:CGSizeMake(mat.cols, mat.rows)
                             pixelFormat:$(LTGLPixelFormatRGBA16Float) allocateMemory:YES];
    result = [archiver unarchiveToTexture:texture
                                 fromPath:LTTemporaryPath(@"archive.mat") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect($(texture.image)).to.beCloseToMat($(mat));
  });

  pending(@"should unarchive float texture", ^{
    cv::Mat4f mat(32, 16);
    mat.rowRange(0, 16).setTo(cv::Vec4f(0.25, 0.5, 0.75, 1.0));
    expect(LTSaveMat(mat, @"archive.mat")).to.beTruthy();

    texture = [LTTexture textureWithSize:CGSizeMake(mat.cols, mat.rows)
                             pixelFormat:$(LTGLPixelFormatRGBA32Float) allocateMemory:YES];
    result = [archiver unarchiveToTexture:texture
                                 fromPath:LTTemporaryPath(@"archive.mat") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect($(texture.image)).to.beCloseToMat($(mat));
  });

  it(@"should unarchive texture using the alpha channel", ^{
    cv::Mat4b mat(32, 16);
    mat.rowRange(0, 16).setTo(cv::Vec4b(255, 0, 0, 64));
    mat.rowRange(16, 32).setTo(cv::Vec4b(0, 255, 0, 192));
    expect(LTSaveMat(mat, @"archive.mat")).to.beTruthy();

    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(mat.cols, mat.rows)];
    texture.usingAlphaChannel = YES;
    result = [archiver unarchiveToTexture:texture
                                 fromPath:LTTemporaryPath(@"archive.mat") error:&error];

    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect($(texture.image)).to.beCloseToMat($(mat));
  });

  it(@"should raise if trying to unarchive into a texture with wrong dimensions", ^{
    cv::Mat4b mat(32, 16);
    expect(LTSaveMat(mat, @"archive.mat")).to.beTruthy();

    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(mat.cols, mat.cols)];
    expect(^{
      [archiver unarchiveToTexture:texture fromPath:LTTemporaryPath(@"archive.mat") error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if trying to unarchive into a texture of the wrong type", ^{
    cv::Mat4b mat(32, 16);
    expect(LTSaveMat(mat, @"archive.mat")).to.beTruthy();

    texture = [LTTexture byteRedTextureWithSize:CGSizeMake(mat.cols, mat.rows)];
    expect(^{
      [archiver unarchiveToTexture:texture fromPath:LTTemporaryPath(@"archive.mat") error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should return error and keep texture unchanged if failed to unarchive the texture", ^{
    cv::Mat4b mat(32, 16);
    expect(LTSaveMat(mat, @"archive.mat")).to.beTruthy();

    OCMStub([fileManager lt_dataWithContentsOfFile:LTTemporaryPath(@"archive.mat")
                                           options:NSDataReadingUncached
                                             error:[OCMArg setTo:kFakeError]]);

    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(mat.cols, mat.rows)];
    NSString *generationID = texture.generationID;
    result = [archiver unarchiveToTexture:texture
                                 fromPath:LTTemporaryPath(@"archive.mat") error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileReadFailed);
    expect(texture.generationID).to.equal(generationID);
  });
});

context(@"removing", ^{
  it(@"should remove the archived texture", ^{
    OCMExpect([fileManager removeItemAtPath:LTTemporaryPath(@"archive.mat")
                                      error:[OCMArg anyObjectRef]]).andReturn(YES);
    result = [archiver removeArchiveInPath:LTTemporaryPath(@"archive.mat") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    OCMVerifyAll(fileManager);
  });

  it(@"should return error if failed to remove the archive", ^{
    OCMExpect([fileManager removeItemAtPath:LTTemporaryPath(@"archive.mat")
                                      error:[OCMArg setTo:kFakeError]]).andReturn(NO);
    result = [archiver removeArchiveInPath:LTTemporaryPath(@"archive.mat") error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileRemovalFailed);
    expect(error.userInfo[NSUnderlyingErrorKey]).to.equal(kFakeError);
    OCMVerifyAll(fileManager);
  });
});

SpecEnd
