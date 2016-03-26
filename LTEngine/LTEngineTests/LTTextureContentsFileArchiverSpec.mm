// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsFileArchiver.h"

#import <LTKit/NSFileManager+LTKit.h>

#import "LTObjectionModule.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTTextureContentsFileArchiver)

__block LTTexture *texture;

beforeEach(^{
  cv::Mat4b image(2, 2);
  image(0, 0) = cv::Vec4b(255, 0, 0, 255);
  image(0, 1) = cv::Vec4b(0, 255, 0, 255);
  image(1, 0) = cv::Vec4b(0, 0, 255, 255);
  image(1, 1) = cv::Vec4b(0, 0, 0, 255);

  texture = [LTTexture textureWithImage:image];
});

afterEach(^{
  texture = nil;
});

it(@"should store texture to temporary file", ^{
  LTTextureContentsFileArchiver *archiver = [[LTTextureContentsFileArchiver alloc] init];

  expect([archiver archiveTexture:texture error:nil]).toNot.beNil();
  expect([[NSFileManager defaultManager] fileExistsAtPath:archiver.filePath]).to.beTruthy();

  [[NSFileManager defaultManager] removeItemAtPath:archiver.filePath error:nil];
});

it(@"should store texture to given file path", ^{
  NSString *filePath = [NSTemporaryDirectory()
                        stringByAppendingString:@"_LTTextureContentsFileArchiverSaveTest.jpg"];

  LTTextureContentsFileArchiver *archiver = [[LTTextureContentsFileArchiver alloc]
                                             initWithFilePath:filePath];

  expect([archiver archiveTexture:texture error:nil]).toNot.beNil();
  expect([[NSFileManager defaultManager] fileExistsAtPath:archiver.filePath]).to.beTruthy();

  [[NSFileManager defaultManager] removeItemAtPath:archiver.filePath error:nil];
});

it(@"should load texture from file", ^{
  NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"TextureContentsImage"
                                                                    ofType:@"png"];
  LTTextureContentsFileArchiver *archiver = [[LTTextureContentsFileArchiver alloc]
                                             initWithFilePath:path];

  LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];

  __block NSError *error;
  expect([archiver unarchiveData:[NSData data] toTexture:texture error:&error]).to.beTruthy();
  expect(error).to.beNil();
  expect($([texture image])).to.equalMat($(LTLoadMat([self class], @"TextureContentsImage.png")));
});

context(@"half float textures", ^{
  using half_float::half;

  __block id fileManager;
  __block cv::Mat4hf image;
  __block NSString *filePath;
  __block LTTextureContentsFileArchiver *archiver;

  beforeEach(^{
    fileManager = LTMockClass([NSFileManager class]);

    image.create(2, 2);
    image(0, 0) = cv::Vec4hf(half(1), half(0), half(0), half(1));
    image(0, 1) = cv::Vec4hf(half(0), half(1), half(0), half(1));
    image(1, 0) = cv::Vec4hf(half(0), half(0), half(1), half(1));
    image(1, 1) = cv::Vec4hf(half(0), half(0), half(0), half(1));

    texture = [LTTexture textureWithImage:image];
    expect(texture.pixelFormat).to.equal($(LTGLPixelFormatRGBA16Float));

    filePath = [NSTemporaryDirectory()
                stringByAppendingString:@"_LTTextureContentsFileArchiverSaveTest.jpg"];

    archiver = [[LTTextureContentsFileArchiver alloc] initWithFilePath:filePath];
  });

  it(@"should store texture to given file path", ^{
    OCMExpect([fileManager lt_writeData:[OCMArg checkWithBlock:^BOOL(NSData *data) {
      cv::Mat mat(image.rows, image.cols, image.type(), const_cast<void *>(data.bytes));
      return LTCompareMat(image, mat);
    }] toFile:filePath options:NSDataWritingAtomic error:[OCMArg anyObjectRef]]).andReturn(YES);
    expect([archiver archiveTexture:texture error:nil]).toNot.beNil();
    OCMVerifyAll(fileManager);
  });

  it(@"should store non-continuous texture to given file path", ^{
    __block cv::Mat4hf bigImage(4, 4, cv::Vec4hf(half(0), half(0), half(0), half(0)));
    cv::Rect subrect(1, 1, 2, 2);
    image.copyTo(bigImage(subrect));
    expect(bigImage(subrect).isContinuous()).to.beFalsy();
    id mock = OCMPartialMock(texture);
    OCMStub([mock mappedImageForReading:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
      LTTextureMappedReadBlock passedBlock;
      [invocation getArgument:&passedBlock atIndex:2];
      passedBlock(bigImage(subrect), NO);
    });

    OCMExpect([fileManager lt_writeData:[OCMArg checkWithBlock:^BOOL(NSData *data) {
      cv::Mat mat(image.rows, image.cols, image.type(), const_cast<void *>(data.bytes));
      return LTCompareMat(image, mat);
    }] toFile:filePath options:NSDataWritingAtomic error:[OCMArg anyObjectRef]]).andReturn(YES);
    expect([archiver archiveTexture:texture error:nil]).toNot.beNil();
    OCMVerifyAll(fileManager);
  });

  it(@"should load texture from file", ^{
    NSData *data = [NSData dataWithBytes:image.data length:image.total() * image.elemSize()];
    OCMExpect([fileManager lt_dataWithContentsOfFile:filePath options:NSDataReadingUncached
              error:[OCMArg anyObjectRef]]).andReturn(data);

    LTTextureContentsFileArchiver *archiver = [[LTTextureContentsFileArchiver alloc]
                                               initWithFilePath:filePath];

    LTTexture *newTexture = [LTTexture textureWithPropertiesOf:texture];

    __block NSError *error;
    expect([archiver unarchiveData:[NSData data] toTexture:newTexture error:&error]).to.beTruthy();
    expect(error).to.beNil();
    expect($(newTexture.image)).to.equalMat($(image));
    OCMVerifyAll(fileManager);
  });
});

context(@"coding", ^{
  it(@"should encode and decode correctly", ^{
    LTTextureContentsFileArchiver *archiver = [[LTTextureContentsFileArchiver alloc] init];

    NSData *encoded = [NSKeyedArchiver archivedDataWithRootObject:archiver];
    LTTextureContentsFileArchiver *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:encoded];

    expect(decoded.filePath).to.equal(archiver.filePath);
  });
});

SpecEnd
