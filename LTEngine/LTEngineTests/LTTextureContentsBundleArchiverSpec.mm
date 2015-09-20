// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsBundleArchiver.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTTextureContentsBundleArchiver)

it(@"should intialize and set properties", ^{
  static NSString * const kName = @"MyTexture";

  LTTextureContentsBundleArchiver *archiver = [[LTTextureContentsBundleArchiver alloc]
                                              initWithName:kName bundle:[NSBundle mainBundle]];

  expect(archiver.name).to.equal(kName);
  expect(archiver.bundle).to.equal([NSBundle mainBundle]);
});

it(@"should encode and decode correctly", ^{
  static NSString * const kName = @"MyTexture";

  LTTextureContentsBundleArchiver *archiver = [[LTTextureContentsBundleArchiver alloc]
                                               initWithName:kName bundle:[NSBundle mainBundle]];

  NSData *encoded = [NSKeyedArchiver archivedDataWithRootObject:archiver];
  LTTextureContentsBundleArchiver *decoded = [NSKeyedUnarchiver unarchiveObjectWithData:encoded];

  expect(decoded.name).to.equal(archiver.name);
  expect(decoded.bundle).to.equal(archiver.bundle);
});

it(@"should load texture from file", ^{
  LTTextureContentsBundleArchiver *archiver = [[LTTextureContentsBundleArchiver alloc]
                                               initWithName:@"TextureContentsImage.png"
                                               bundle:[NSBundle bundleForClass:[self class]]];

  LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];

  __block NSError *error;
  expect([archiver unarchiveData:[NSData data] toTexture:texture error:&error]).to.beTruthy();
  expect(error).to.beNil();
  expect($([texture image])).to.equalMat($(LTLoadMat([self class], @"TextureContentsImage.png")));
});

it(@"should return yes when archiving texture", ^{
  LTTextureContentsBundleArchiver *archiver = [[LTTextureContentsBundleArchiver alloc]
                                               initWithName:@"TextureContentsImage.png"
                                               bundle:[NSBundle bundleForClass:[self class]]];

  LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];

  __block NSError *error;
  expect([archiver archiveTexture:texture error:&error]).toNot.beNil();
  expect(error).to.beNil();
});

LTSpecEnd
