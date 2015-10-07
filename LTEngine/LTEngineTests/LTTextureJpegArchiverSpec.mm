// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureJpegArchiver.h"

#import <LTKit/LTImageLoader.h>
#import <LTKit/NSError+LTKit.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "LTImage.h"
#import "LTTexture+Factory.h"

SpecBegin(LTTextureJpegArchiver)

__block LTTextureJpegArchiver *archiver;
__block LTTexture *texture;
__block NSError *error;
__block id fileManager;
__block BOOL result;

static NSError * const kFakeError = [NSError errorWithDomain:@"foo" code:1337 userInfo:nil];

beforeEach(^{
  fileManager = OCMPartialMock([NSFileManager defaultManager]);
  LTBindObjectToClass(fileManager, [NSFileManager class]);
  archiver = [[LTTextureJpegArchiver alloc] init];

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
      mapped->rowRange(0, 8).setTo(cv::Vec4b(255, 0, 0, 255));
      mapped->rowRange(8, 16).setTo(cv::Vec4b(0, 255, 0, 255));
    }];
  });

  it(@"should archive correctly", ^{
    result = [archiver archiveTexture:texture inPath:LTTemporaryPath(@"archive.jpg") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.jpg")).to.beTruthy();

    UIImage *uiImage = [UIImage imageWithContentsOfFile:LTTemporaryPath(@"archive.jpg")];
    LTImage *image = [[LTImage alloc] initWithImage:uiImage];
    expect($(image.mat)).to.beCloseToMat($(texture.image));
  });

  it(@"should archive single channel texture", ^{
    texture = [LTTexture byteRedTextureWithSize:texture.size];
    [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->rowRange(0, 8).setTo(64);
      mapped->rowRange(8, 16).setTo(192);
    }];

    result = [archiver archiveTexture:texture inPath:LTTemporaryPath(@"archive.jpg") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.jpg")).to.beTruthy();

    UIImage *uiImage = [UIImage imageWithContentsOfFile:LTTemporaryPath(@"archive.jpg")];
    LTImage *image = [[LTImage alloc] initWithImage:uiImage];
    expect($(image.mat)).to.beCloseToMat($(texture.image));
  });

  it(@"should raise if trying to archive non-byte precision texture", ^{
    LTTexture *halfFloatTexture = [LTTexture textureWithSize:texture.size
                                                   precision:LTTexturePrecisionHalfFloat
                                                      format:texture.format allocateMemory:YES];
    expect(^{
      [archiver archiveTexture:halfFloatTexture inPath:@"halfFloatArchive.jpg" error:&error];
    }).to.raise(NSInvalidArgumentException);
    expect(LTFileExistsInTemporaryPath(@"halfFloatArchive.jpg")).to.beFalsy();

    LTTexture *floatTexture = [LTTexture textureWithSize:texture.size
                                               precision:LTTexturePrecisionFloat
                                                  format:texture.format allocateMemory:YES];
    expect(^{
      [archiver archiveTexture:floatTexture inPath:@"floatArchive.jpg" error:&error];
    }).to.raise(NSInvalidArgumentException);
    expect(LTFileExistsInTemporaryPath(@"floatArchive.jpg")).to.beFalsy();
  });

  it(@"should raise if trying to archive texture using the alpha channel", ^{
    texture.usingAlphaChannel = YES;
    expect(^{
      [archiver archiveTexture:texture inPath:LTTemporaryPath(@"alphaArchive.jpg") error:&error];
    }).to.raise(NSInvalidArgumentException);
    expect(LTFileExistsInTemporaryPath(@"alphaArchive.jpg")).to.beFalsy();
  });

  it(@"should return error if failed to archive the texture", ^{
    // TODO:(amit) replace this horrible hack when switching to use LTImageCompressor.
    id mock = OCMClassMock([LTImage class]);
    OCMStub([mock writeToPath:[OCMArg any] error:[OCMArg setTo:kFakeError]]).andReturn(NO);
    OCMStub([mock alloc]).andReturn(mock);
    __unused id initMock = [[[[mock stub] ignoringNonObjectArgs] andReturn:mock]
                            initWithMat:cv::Mat4b(1,1) copy:NO];

    result = [archiver archiveTexture:texture inPath:LTTemporaryPath(@"archive.jpg") error:&error];
    expect(result).to.beFalsy();
    expect(error).to.equal(kFakeError);

    [mock stopMocking];
  });
});

context(@"unarchiving", ^{
  __block cv::Mat4b mat;

  beforeEach(^{
    mat.create(32, 16);
    mat.rowRange(0, 16).setTo(cv::Vec4b(255, 0, 0, 255));
    mat.rowRange(16, 32).setTo(cv::Vec4b(0, 255, 0, 255));

    cv::Mat bgr;
    cv::cvtColor(mat, bgr, CV_RGBA2BGRA);
    cv::imwrite([LTTemporaryPath(@"archive.jpg") cStringUsingEncoding:NSUTF8StringEncoding], bgr);
  });

  it(@"should unarchive correctly", ^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(mat.cols, mat.rows)];
    result = [archiver unarchiveToTexture:texture
                                 fromPath:LTTemporaryPath(@"archive.jpg") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect($(texture.image)).to.beCloseToMat($(mat));
  });

  it(@"should unarchive single channel texture", ^{
    cv::Mat1b gray;
    cv::cvtColor(mat, gray, CV_RGBA2GRAY);
    cv::imwrite([LTTemporaryPath(@"archive.jpg") cStringUsingEncoding:NSUTF8StringEncoding], gray);

    texture = [LTTexture byteRedTextureWithSize:CGSizeMake(mat.cols, mat.rows)];
    result = [archiver unarchiveToTexture:texture
                                 fromPath:LTTemporaryPath(@"archive.jpg") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect($(texture.image)).to.beCloseToMat($(gray));
  });

  it(@"should raise if trying to unarchive into a non-byte precision texture", ^{
    texture = [LTTexture textureWithSize:CGSizeMake(mat.rows, mat.cols)
                               precision:LTTexturePrecisionHalfFloat
                                  format:LTTextureFormatRGBA allocateMemory:YES];
    expect(^{
      [archiver unarchiveToTexture:texture fromPath:LTTemporaryPath(@"archive.jpg") error:&error];
    }).to.raise(NSInvalidArgumentException);

    texture = [LTTexture textureWithSize:CGSizeMake(mat.rows, mat.cols)
                               precision:LTTexturePrecisionFloat
                                  format:LTTextureFormatRGBA allocateMemory:YES];
    expect(^{
      [archiver unarchiveToTexture:texture fromPath:LTTemporaryPath(@"archive.jpg") error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if trying to unarchive into a texture using the alpha channel", ^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(mat.cols, mat.rows)];
    texture.usingAlphaChannel = YES;
    expect(^{
      [archiver unarchiveToTexture:texture fromPath:LTTemporaryPath(@"archive.jpg") error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if trying to unarchive into a texture with wrong dimensions", ^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(mat.cols, mat.cols)];
    expect(^{
      [archiver unarchiveToTexture:texture fromPath:LTTemporaryPath(@"archive.jpg") error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if trying to unarchive into a texture of the wrong type", ^{
    texture = [LTTexture byteRedTextureWithSize:CGSizeMake(mat.cols, mat.rows)];
    expect(^{
      [archiver unarchiveToTexture:texture fromPath:LTTemporaryPath(@"archive.jpg") error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should return error and keep texture unchanged if failed to unarchive the texture", ^{
    id imageLoader = LTMockClass([LTImageLoader class]);
    OCMStub([imageLoader imageWithContentsOfFile:LTTemporaryPath(@"archive.jpg")]);

    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(mat.cols, mat.rows)];
    NSString *generationID = texture.generationID;
    result = [archiver unarchiveToTexture:texture
                                 fromPath:LTTemporaryPath(@"archive.jpg") error:&error];
    expect(result).to.beFalsy();
    expect(error.code).to.equal(LTErrorCodeFileReadFailed);
    expect(texture.generationID).to.equal(generationID);
  });
});

context(@"removing", ^{
  it(@"should remove the archived texture", ^{
    OCMExpect([fileManager removeItemAtPath:LTTemporaryPath(@"archive.jpg")
                                      error:[OCMArg anyObjectRef]]).andReturn(YES);
    result = [archiver removeArchiveInPath:LTTemporaryPath(@"archive.jpg") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    OCMVerifyAll(fileManager);
  });

  it(@"should return error if failed to remove the archive", ^{
    OCMExpect([fileManager removeItemAtPath:LTTemporaryPath(@"archive.jpg")
                                      error:[OCMArg setTo:kFakeError]]).andReturn(NO);
    result = [archiver removeArchiveInPath:LTTemporaryPath(@"archive.jpg") error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileRemovalFailed);
    expect(error.userInfo[NSUnderlyingErrorKey]).to.equal(kFakeError);
    OCMVerifyAll(fileManager);
  });
});

SpecEnd
