// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsFileArchiver.h"

#import "LTObjectionModule.h"
#import "LTOpenCVExtensions.h"
#import "LTFileManager.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTTextureContentsFileArchiver)

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

context(@"coding", ^{
  it(@"should encode and decode correctly", ^{
    LTTextureContentsFileArchiver *archiver = [[LTTextureContentsFileArchiver alloc] init];

    NSData *encoded = [NSKeyedArchiver archivedDataWithRootObject:archiver];
    LTTextureContentsFileArchiver *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:encoded];

    expect(decoded.filePath).to.equal(archiver.filePath);
  });
});

LTSpecEnd
