// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsFileArchiver.h"

#import "LTObjectionModule.h"
#import "LTOpenCVExtensions.h"
#import "LTFileManager.h"
#import "LTTexture+Factory.h"

@interface LTTextureContentsFileArchiver ()
@property (strong, nonatomic) LTFileManager *fileManager;
@end

@interface LTFakeFileManager : LTFileManager

@property (nonatomic) NSUInteger saveCount;
@property (strong, nonatomic) NSData *savedData;
@property (strong, nonatomic) NSString *savedPath;

@end

@implementation LTFakeFileManager

- (BOOL)writeData:(NSData *)data toFile:(NSString *)path
          options:(NSDataWritingOptions __unused)options
            error:(NSError *__autoreleasing __unused *)error {
  ++self.saveCount;
  self.savedData = data;
  self.savedPath = path;

  return YES;
}

@end

LTSpecBegin(LTTextureContentsFileArchiver)

__block LTTexture *texture;
__block LTFakeFileManager *fakeManager;

beforeEach(^{
  fakeManager = [[LTFakeFileManager alloc] init];
  LTBindObjectToClass(fakeManager, [LTFileManager class]);

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
  expect(fakeManager.saveCount).to.equal(1);
});

it(@"should store texture to given file path", ^{
  static NSString * const kFilePath = @"/a/b/c.file";

  LTTextureContentsFileArchiver *archiver = [[LTTextureContentsFileArchiver alloc]
                                             initWithFilePath:kFilePath];

  expect([archiver archiveTexture:texture error:nil]).toNot.beNil();
  expect(fakeManager.saveCount).to.equal(1);
  expect(fakeManager.savedPath).to.equal(kFilePath);
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

it(@"should fail loading and storing unsupported texture format", ^{
  LTTexture *unsupported = [LTTexture byteRedTextureWithSize:CGSizeMake(1, 1)];

  LTTextureContentsFileArchiver *archiver = [[LTTextureContentsFileArchiver alloc] init];

  expect(^{
    [archiver unarchiveData:[NSData data] toTexture:unsupported error:nil];
  }).to.raise(NSInvalidArgumentException);

  expect(^{
    [archiver archiveTexture:unsupported error:nil];
  }).to.raise(NSInvalidArgumentException);
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
