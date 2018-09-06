// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureArchiver.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSError+LTKit.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "LTGLTexture.h"
#import "LTImage.h"
#import "LTTexture+Factory.h"
#import "LTTextureArchiveMetadata.h"
#import "LTTextureArchiveType.h"
#import "LTTextureArchiverNonPersistentStorage.h"
#import "LTTextureBaseArchiver.h"
#import "LTTextureMetadata.h"
#import "LTTextureRepository.h"

static LTPath *LTPathMake(NSString *relativePath) {
  return [LTPath pathWithPath:LTTemporaryPath(relativePath)];
}

static BOOL LTFileExists(NSString *relativePath) {
  LTPath *path = LTPathMake(relativePath);
  return [[NSFileManager defaultManager] fileExistsAtPath:path.path];
}

static BOOL LTDirectoryExists(NSString *relativePath) {
  LTPath *path = LTPathMake(relativePath);
  return [[NSFileManager defaultManager] lt_directoryExistsAtPath:path.path];
}

static BOOL LTLinkExists(NSString *relativePath) {
  LTPath *path = LTPathMake(relativePath);
  NSDictionary *attributes = [[NSFileManager defaultManager]
                              attributesOfItemAtPath:path.path error:nil];

  return ![attributes[NSFileType] isEqual:NSFileTypeDirectory] &&
         [attributes[NSFileReferenceCount] unsignedLongValue] > 1;
}

@interface LTTextureArchiverNonPersistentStorage()
@property (readonly, nonatomic) NSDictionary *dictionary;
@end

SpecBegin(LTTextureArchiver)

__block BOOL result;
__block NSError *error;
__block LTTexture *texture;
__block LTTextureArchiver *archiver;
__block LTTextureArchiverNonPersistentStorage *storage;
__block id mock;
__block id fileManager;
__block LTPath *archivePath;
__block LTTextureRepository *textureRepository;

static NSError * const kFakeError = [NSError errorWithDomain:@"foo" code:1337 userInfo:nil];

beforeEach(^{
  fileManager = OCMPartialMock([NSFileManager defaultManager]);
  LTBindObjectToClass(fileManager, [NSFileManager class]);
  storage = [[LTTextureArchiverNonPersistentStorage alloc] init];

  mock = OCMPartialMock(storage);
  textureRepository = OCMClassMock([LTTextureRepository class]);
  LTPath *path = LTPathMake(@"");
  archiver = [[LTTextureArchiver alloc] initWithStorage:storage
                                      textureRepository:textureRepository];
  [fileManager removeItemAtPath:path.path error:nil];
  [fileManager createDirectoryAtPath:path.path withIntermediateDirectories:NO
                          attributes:nil error:nil];

  archivePath = LTPathMake(@"archive");
});

afterEach(^{
  [fileManager stopMocking];
  fileManager = nil;
  archivePath = nil;
  texture = nil;
  archiver = nil;
  storage = nil;
  mock = nil;
  error = nil;
  result = NO;
});

context(@"archiving", ^{
  beforeEach(^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 8)];
  });

  it(@"should archive texture", ^{
    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"archive")).to.beTruthy();
    expect(LTFileExists(@"archive/metadata.plist")).to.beTruthy();
    expect(LTFileExists(@"archive/content.jpg")).to.beTruthy();
  });

  it(@"should raise if trying to archive a mipmap texture", ^{
    texture = [[LTGLTexture alloc] initWithBaseLevelMipmapImage:cv::Mat4b(16, 16)];
    expect(^{
      result = [archiver archiveTexture:texture inPath:archivePath
                        withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should return error and clean filesystem if archive folder with given name exists", ^{
    [fileManager createDirectoryAtPath:archivePath.path withIntermediateDirectories:NO
                            attributes:nil error:nil];
    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileAlreadyExists);
    expect(LTDirectoryExists(@"archive")).to.beTruthy();
    expect(LTFileExists(@"archive/metadata.plist")).to.beFalsy();
    expect(LTFileExists(@"archive/content.jpg")).to.beFalsy();
  });

  it(@"should return error and clean filesystem if metadata file with given name exists", ^{
    NSString *metadataPath = [archivePath pathByAppendingPathComponent:@"metadata.plist"].path;
    OCMStub([fileManager fileExistsAtPath:metadataPath]).andReturn(YES);
    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beFalsy();
    expect(error.code).to.equal(LTErrorCodeFileAlreadyExists);
    expect(LTDirectoryExists(@"archive")).to.beFalsy();
  });

  it(@"should return error and clean filesystem if failed to archive the content", ^{
    NSString *contentPath = [archivePath pathByAppendingPathComponent:@"content.jpg"].path;

    id typeMock = OCMPartialMock($(LTTextureArchiveTypeJPEG));
    id archiverMock = OCMProtocolMock(@protocol(LTTextureBaseArchiver));
    OCMStub([typeMock archiver]).andReturn(archiverMock);
    OCMStub([archiverMock archiveTexture:[OCMArg any] inPath:contentPath
                                   error:[OCMArg setTo:kFakeError]]).andReturn(NO);

    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:typeMock error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.lt_underlyingError).to.equal(kFakeError);
    expect(LTDirectoryExists(@"archive")).to.beFalsy();
  });

  it(@"should return error and clean filesystem if failed to save texture metadata", ^{
    NSString *metadataPath = [archivePath pathByAppendingPathComponent:@"metadata.plist"].path;
    OCMStub([fileManager lt_writeDictionary:[OCMArg any] toFile:metadataPath
                                      error:[OCMArg setTo:kFakeError]]).andReturn(NO);
    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beFalsy();
    expect(error).to.equal(kFakeError);
    expect(LTDirectoryExists(@"archive")).to.beFalsy();
  });

  it(@"should not save content of texture with solid fillColor", ^{
    [texture clearColor:LTVector4::ones()];
    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"archive")).to.beTruthy();
    expect(LTFileExists(@"archive/metadata.plist")).to.beTruthy();
    expect(LTFileExists(@"archive/content.jpg")).to.beFalsy();
  });

  it(@"should save content of a unique texture", ^{
    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect([storage.dictionary allValues]).to.haveCountOf(1);

    LTTexture *otherTexture = [LTTexture textureWithPropertiesOf:texture];
    result = [archiver archiveTexture:otherTexture inPath:LTPathMake(@"otherArchive")
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"otherArchive")).to.beTruthy();
    expect(LTFileExists(@"otherArchive/metadata.plist")).to.beTruthy();
    expect(LTFileExists(@"otherArchive/content.jpg")).to.beTruthy();
    expect(LTLinkExists(@"otherArchive/content.jpg")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(2);
  });

  it(@"should save content of an existing texture with different archive type", ^{
    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect([storage.dictionary allValues]).to.haveCountOf(1);

    LTTexture *otherTexture = [texture clone];
    result = [archiver archiveTexture:otherTexture inPath:LTPathMake(@"otherArchive")
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"otherArchive")).to.beTruthy();
    expect(LTFileExists(@"otherArchive/metadata.plist")).to.beTruthy();
    expect(LTFileExists(@"otherArchive/content.mat")).to.beTruthy();
    expect(LTLinkExists(@"otherArchive/content.mat")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(2);
  });

  context(@"linked to existing texture", ^{
    beforeEach(^{
      result = [archiver archiveTexture:texture inPath:archivePath
                        withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(LTDirectoryExists(@"archive")).to.beTruthy();
      expect(LTFileExists(@"archive/metadata.plist")).to.beTruthy();
      expect(LTFileExists(@"archive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"archive/content.jpg")).to.beFalsy();
      expect([storage.dictionary allValues]).to.haveCountOf(1);
    });

    it(@"should create link in case an identical texture is already archived", ^{
      LTTexture *otherTexture = [texture clone];
      result = [archiver archiveTexture:otherTexture inPath:LTPathMake(@"otherArchive")
                        withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(LTDirectoryExists(@"otherArchive")).to.beTruthy();
      expect(LTFileExists(@"otherArchive/metadata.plist")).to.beTruthy();
      expect(LTFileExists(@"otherArchive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"archive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"otherArchive/content.jpg")).to.beTruthy();
      expect([fileManager contentsEqualAtPath:LTPathMake(@"otherArchive/content.jpg").path
              andPath:LTPathMake(@"archive/content.jpg").path]).to.beTruthy();
      expect([storage.dictionary allValues]).to.haveCountOf(1);
    });

    it(@"should create link and cleanup zombie records in case identical texture is archived", ^{
      expect([storage.dictionary allValues].firstObject).to.haveCountOf(1);
      id firstRecord = [[storage.dictionary allValues].firstObject lastObject];

      LTTexture *otherTexture = [texture clone];
      result = [archiver archiveTexture:otherTexture inPath:LTPathMake(@"otherArchive")
                        withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
      expect([storage.dictionary allValues].firstObject).to.haveCountOf(2);
      id secondRecord = [[storage.dictionary allValues].firstObject lastObject];

      [fileManager removeItemAtPath:LTPathMake(@"archive/content.jpg").path error:nil];

      LTTexture *anotherTexture = [texture clone];
      result = [archiver archiveTexture:anotherTexture inPath:LTPathMake(@"anotherArchive")
                        withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(LTDirectoryExists(@"anotherArchive")).to.beTruthy();
      expect(LTFileExists(@"anotherArchive/metadata.plist")).to.beTruthy();
      expect(LTFileExists(@"anotherArchive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"otherArchive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"anotherArchive/content.jpg")).to.beTruthy();
      expect([fileManager contentsEqualAtPath:LTPathMake(@"anotherArchive/content.jpg").path
              andPath:LTPathMake(@"otherArchive/content.jpg").path]).to.beTruthy();
      expect([storage.dictionary allValues]).to.haveCountOf(1);
      expect([storage.dictionary allValues].firstObject).to.haveCountOf(2);
      expect([storage.dictionary allValues].firstObject).notTo.contain(firstRecord);
      expect([storage.dictionary allValues].firstObject).to.contain(secondRecord);
    });
  });

  context(@"archive that create multiple files", ^{
    __block id typeMock;

    beforeEach(^{
      NSDictionary *data1 = @{@"a": @1, @"b": @2};
      NSDictionary *data2 = @{@"c": @3, @"d": @4};

      typeMock = OCMPartialMock($(LTTextureArchiveTypeJPEG));
      id archiverMock = OCMProtocolMock(@protocol(LTTextureBaseArchiver));
      OCMStub([typeMock archiver]).andReturn(archiverMock);
      OCMStub([archiverMock archiveTexture:texture inPath:LTPathMake(@"archive/content.jpg").path
               error:[OCMArg anyObjectRef]]).andDo(^(NSInvocation *invocation) {
        [fileManager lt_writeDictionary:data1
                                 toFile:LTPathMake(@"archive/content.jpg").path error:nil];
        [fileManager lt_writeDictionary:data2
                                 toFile:LTPathMake(@"archive/aux.file").path error:nil];
        BOOL returnValue = YES;
        [invocation setReturnValue:&returnValue];
      });
    });

    afterEach(^{
      typeMock = nil;
    });

    it(@"should archive correctly", ^{
      result = [archiver archiveTexture:texture inPath:archivePath
                        withArchiveType:typeMock error:&error];
      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(LTDirectoryExists(@"archive")).to.beTruthy();
      expect(LTFileExists(@"archive/metadata.plist")).to.beTruthy();
      expect(LTFileExists(@"archive/content.jpg")).to.beTruthy();
      expect(LTFileExists(@"archive/aux.file")).to.beTruthy();
    });

    it(@"should create links for all files of archives that create multiple files", ^{
      result = [archiver archiveTexture:texture inPath:archivePath
                        withArchiveType:typeMock error:&error];

      result = [archiver archiveTexture:[texture clone] inPath:LTPathMake(@"otherArchive")
                        withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];

      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(LTDirectoryExists(@"otherArchive")).to.beTruthy();
      expect(LTFileExists(@"otherArchive/metadata.plist")).to.beTruthy();
      expect(LTFileExists(@"otherArchive/content.jpg")).to.beTruthy();
      expect(LTFileExists(@"otherArchive/aux.file")).to.beTruthy();
      expect(LTLinkExists(@"archive/metadata.plist")).to.beFalsy();
      expect(LTLinkExists(@"archive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"archive/aux.file")).to.beTruthy();
      expect(LTLinkExists(@"otherArchive/metadata.plist")).to.beFalsy();
      expect(LTLinkExists(@"otherArchive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"otherArchive/aux.file")).to.beTruthy();
      expect([fileManager contentsEqualAtPath:LTPathMake(@"otherArchive/content.jpg").path
              andPath:LTPathMake(@"archive/content.jpg").path]).to.beTruthy();
      expect([fileManager contentsEqualAtPath:LTPathMake(@"otherArchive/aux.file").path
              andPath:LTPathMake(@"archive/aux.file").path]).to.beTruthy();
    });
  });
});

context(@"unarchiving", ^{
  __block cv::Mat4b mat;

  beforeEach(^{
    mat.create(8, 4);
    mat.rowRange(0, 4).setTo(cv::Vec4b(255, 0, 0, 255));
    mat.rowRange(4, 8).setTo(cv::Vec4b(0, 255, 0, 255));
    texture = [LTTexture textureWithImage:mat];

    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();
  });

  context(@"unarchive to given texture", ^{
    it(@"should unarchive correctly", ^{
      LTTexture *otherTexture = [LTTexture textureWithPropertiesOf:texture];
      result = [archiver unarchiveToTexture:otherTexture fromPath:archivePath error:&error];
      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(mat));
    });

    it(@"should add target texture to texture repository", ^{
      LTTexture *otherTexture = [LTTexture textureWithPropertiesOf:texture];
      [archiver unarchiveToTexture:otherTexture fromPath:archivePath error:&error];

      OCMVerify([textureRepository addTexture:otherTexture]);
    });

    it(@"should raise if trying to unarchive to a wrong texture type", ^{
      expect(^{
        [archiver unarchiveToTexture:[LTTexture byteRGBATextureWithSize:texture.size * 2]
                            fromPath:archivePath error:nil];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [archiver unarchiveToTexture:[LTTexture byteRedTextureWithSize:texture.size]
                            fromPath:archivePath error:nil];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [archiver unarchiveToTexture:[LTTexture textureWithSize:texture.size
                                                    pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                                 allocateMemory:YES]
                            fromPath:archivePath error:nil];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise if trying to unarchive to a mipmap texture", ^{
      expect(^{
        [archiver unarchiveToTexture:[[LTGLTexture alloc]
                                      initWithSize:texture.size pixelFormat:texture.pixelFormat
                                      maxMipmapLevel:1]
                            fromPath:archivePath error:nil];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should return error if archive does not exist", ^{
      result = [archiver unarchiveToTexture:texture fromPath:LTPathMake(@"noArchive") error:&error];
      expect(result).to.beFalsy();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileNotFound);
    });

    it(@"should return error if failed to load archive metadata", ^{
      NSString *metadataPath = [archivePath pathByAppendingPathComponent:@"metadata.plist"].path;
      OCMStub([fileManager lt_dictionaryWithContentsOfFile:metadataPath
                                                     error:[OCMArg setTo:kFakeError]]);

      LTTexture *otherTexture = [LTTexture textureWithPropertiesOf:texture];
      result = [archiver unarchiveToTexture:otherTexture fromPath:archivePath error:&error];
      expect(result).to.beFalsy();
      expect(error).notTo.beNil();
      expect(error).to.equal(kFakeError);
    });

    it(@"should return error if failed to load archive content", ^{
      NSString *contentPath = [archivePath pathByAppendingPathComponent:@"content.mat"].path;
      result = [fileManager removeItemAtPath:contentPath error:&error];
      expect(result).to.beTruthy();

      LTTexture *otherTexture = [LTTexture textureWithPropertiesOf:texture];
      result = [archiver unarchiveToTexture:otherTexture fromPath:archivePath error:&error];
      expect(result).to.beFalsy();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileReadFailed);
    });

    it(@"should unarchive texture with solid color", ^{
      LTPath *solidArchivePath = LTPathMake(@"solidFillArchive");

      [texture clearColor:LTVector4(0.25, 0.5, 0.75, 1.0)];
      result = [archiver archiveTexture:texture inPath:solidArchivePath
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();
      expect(LTFileExists(@"solidFillArchive/content.mat")).to.beFalsy();

      LTTexture *otherTexture = [LTTexture textureWithPropertiesOf:texture];
      [archiver unarchiveToTexture:otherTexture fromPath:solidArchivePath error:&error];

      expect(error).to.beNil();
      expect(otherTexture).notTo.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.fillColor).to.equal(texture.fillColor);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(texture.image));
    });

    it(@"should unarchive texture with linked content", ^{
      LTTexture *clonedTexture = [texture clone];
      result = [archiver archiveTexture:clonedTexture inPath:LTPathMake(@"clonedArchive")
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();
      expect(LTLinkExists(@"clonedArchive/content.mat")).to.beTruthy();

      LTTexture *otherTexture = [LTTexture textureWithPropertiesOf:texture];
      [archiver unarchiveToTexture:otherTexture fromPath:LTPathMake(@"clonedArchive") error:&error];

      expect(error).to.beNil();
      expect(otherTexture).notTo.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(texture.image));
    });

    it(@"should return YES without unarchiving if target already has the same generationID", ^{
      // Content is removed, to make sure archiver will fail if tried to actually unarchive it.
      NSString *contentPath = [archivePath pathByAppendingPathComponent:@"content.mat"].path;
      result = [fileManager removeItemAtPath:contentPath error:&error];
      expect(result).to.beTruthy();

      LTTexture *otherTexture = [texture clone];
      expect(otherTexture.generationID).to.equal(texture.generationID);

      result = [archiver unarchiveToTexture:otherTexture fromPath:archivePath error:&error];
      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(mat));
    });
  });

  context(@"unarchive to new texture", ^{
    it(@"should unarchive correctly", ^{
      LTTexture *otherTexture = [archiver unarchiveTextureFromPath:archivePath error:&error];
      expect(error).to.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(mat));
    });

    it(@"should add returned texture to texture repository", ^{
      LTTexture *otherTexture = [archiver unarchiveTextureFromPath:archivePath error:&error];

      OCMVerify([textureRepository addTexture:otherTexture]);
    });

    it(@"should return nil if archive does not exist", ^{
      texture = [archiver unarchiveTextureFromPath:LTPathMake(@"noArchive") error:&error];
      expect(texture).to.beNil();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileNotFound);
    });

    it(@"should return nil if failed to load archive metadata", ^{
      NSString *metadataPath = [archivePath pathByAppendingPathComponent:@"metadata.plist"].path;
      OCMStub([fileManager lt_dictionaryWithContentsOfFile:metadataPath
                                                     error:[OCMArg setTo:kFakeError]]);

      texture = [archiver unarchiveTextureFromPath:archivePath error:&error];
      expect(texture).to.beNil();
      expect(error).notTo.beNil();
      expect(error).to.equal(kFakeError);
    });

    it(@"should return nil if failed to load archive content", ^{
      NSString *contentPath = [archivePath pathByAppendingPathComponent:@"content.mat"].path;
      result = [fileManager removeItemAtPath:contentPath error:&error];
      expect(result).to.beTruthy();

      texture = [archiver unarchiveTextureFromPath:archivePath error:&error];
      expect(texture).to.beNil();
      expect(error).notTo.beNil();
    });

    it(@"should unarchive texture with solid color", ^{
      LTPath *solidArchivePath = LTPathMake(@"solidFillArchive");

      [texture clearColor:LTVector4(0.25, 0.5, 0.75, 1.0)];
      result = [archiver archiveTexture:texture inPath:solidArchivePath
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();
      expect(LTFileExists(@"solidFillArchive/content.mat")).to.beFalsy();

      LTTexture *otherTexture = [archiver unarchiveTextureFromPath:solidArchivePath error:&error];

      expect(error).to.beNil();
      expect(otherTexture).notTo.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.fillColor).to.equal(texture.fillColor);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(texture.image));
    });

    it(@"should unarchive texture with linked content", ^{
      LTPath *clonedArchivePath = LTPathMake(@"clonedArchive");

      LTTexture *clonedTexture = [texture clone];
      result = [archiver archiveTexture:clonedTexture inPath:clonedArchivePath
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();
      expect(LTLinkExists(@"clonedArchive/content.mat")).to.beTruthy();

      LTTexture *otherTexture = [archiver unarchiveTextureFromPath:clonedArchivePath error:&error];

      expect(error).to.beNil();
      expect(otherTexture).notTo.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(texture.image));
    });
  });

  context(@"unarchive to a UIImage", ^{
    __block UIImage *image;

    afterEach(^{
      image = nil;
    });

    it(@"should unarchive correctly", ^{
      image = [archiver unarchiveImageFromPath:archivePath error:&error];
      expect(error).to.beNil();
      expect(image.size).to.equal(texture.size);
      expect($([[LTImage alloc] initWithImage:image].mat)).to.equalMat($(texture.image));
    });

    it(@"should return nil if archive does not exist", ^{
      image = [archiver unarchiveImageFromPath:LTPathMake(@"noArchive") error:&error];
      expect(image).to.beNil();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileNotFound);
    });

    it(@"should return nil if failed to load archive metadata", ^{
      NSString *metadataPath = [archivePath pathByAppendingPathComponent:@"metadata.plist"].path;
      OCMStub([fileManager lt_dictionaryWithContentsOfFile:metadataPath
                                                     error:[OCMArg setTo:kFakeError]]);

      image = [archiver unarchiveImageFromPath:archivePath error:&error];
      expect(image).to.beNil();
      expect(error).notTo.beNil();
      expect(error).to.equal(kFakeError);
    });

    it(@"should return nil if failed to load archive content", ^{
      NSString *contentPath = [archivePath pathByAppendingPathComponent:@"content.mat"].path;
      result = [fileManager removeItemAtPath:contentPath error:&error];
      expect(result).to.beTruthy();

      image = [archiver unarchiveImageFromPath:archivePath error:&error];
      expect(image).to.beNil();
      expect(error).notTo.beNil();
    });

    it(@"should return nil if archive pixel format is not byte RGBA", ^{
      LTPath *grayArchivePath = LTPathMake(@"grayArchive");
      LTPath *halfFloatArchivePath = LTPathMake(@"halfFloatArchive");

      LTTexture *greyTexture = [LTTexture byteRedTextureWithSize:texture.size];
      result = [archiver archiveTexture:greyTexture inPath:grayArchivePath
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();

      LTTexture *halfFloatTexture = [LTTexture textureWithSize:texture.size
                                                   pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                                allocateMemory:YES];
      result = [archiver archiveTexture:halfFloatTexture inPath:halfFloatArchivePath
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();

      image = [archiver unarchiveImageFromPath:grayArchivePath error:&error];
      expect(image).to.beNil();
      expect(error).notTo.beNil();

      error = nil;
      image = [archiver unarchiveImageFromPath:halfFloatArchivePath error:&error];
      expect(image).to.beNil();
      expect(error).notTo.beNil();
    });

    it(@"should unarchive image with solid color", ^{
      LTPath *solidArchivePath = LTPathMake(@"solidFillArchive");

      [texture clearColor:LTVector4(0.25, 0.5, 0.75, 1.0)];
      result = [archiver archiveTexture:texture inPath:solidArchivePath
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();
      expect(LTFileExists(@"solidFillArchive/content.mat")).to.beFalsy();

      image = [archiver unarchiveImageFromPath:solidArchivePath error:&error];

      expect(error).to.beNil();
      expect(image).notTo.beNil();
      expect($([[LTImage alloc] initWithImage:image].mat)).to.equalMat($(texture.image));
    });

    it(@"should unarchive image with linked content", ^{
      LTPath *clonedArchivePath = LTPathMake(@"clonedArchive");

      LTTexture *clonedTexture = [texture clone];
      result = [archiver archiveTexture:clonedTexture inPath:clonedArchivePath
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();
      expect(LTLinkExists(@"clonedArchive/content.mat")).to.beTruthy();

      image = [archiver unarchiveImageFromPath:clonedArchivePath error:&error];

      expect(error).to.beNil();
      expect(image).notTo.beNil();
      expect($([[LTImage alloc] initWithImage:image].mat)).to.equalMat($(texture.image));
    });
  });

  context(@"texture metadata", ^{
    it(@"should unarchive correctly", ^{
      LTTextureArchiveMetadata *metadata = [archiver metadataFromPath:archivePath error:&error];
      expect(error).to.beNil();
      expect(metadata.archiveType).to.equal($(LTTextureArchiveTypeUncompressedMat));
      expect(metadata.textureMetadata).to.equal(texture.metadata);
    });

    it(@"should return nil if archive does not exist", ^{
      LTTextureArchiveMetadata *metadata = [archiver metadataFromPath:LTPathMake(@"noArchive")
                                                                error:&error];
      expect(metadata).to.beNil();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileNotFound);
    });

    it(@"should return nil if failed to load archive metadata", ^{
      NSString *metadataPath = [archivePath pathByAppendingPathComponent:@"metadata.plist"].path;
      OCMStub([fileManager lt_dictionaryWithContentsOfFile:metadataPath
                                                     error:[OCMArg setTo:kFakeError]]);

      LTTextureArchiveMetadata *metadata = [archiver metadataFromPath:archivePath error:&error];
      expect(metadata).to.beNil();
      expect(error).notTo.beNil();
      expect(error).to.equal(kFakeError);
    });
  });
});

context(@"removing", ^{
  beforeEach(^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 8)];
  });

  it(@"should successfully remove archive", ^{
    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();

    result = [archiver removeArchiveInPath:archivePath error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"archive")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(0);
  });

  it(@"should successfully remove archive of solid color texture", ^{
    [texture clearColor:LTVector4::ones()];
    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();

    result = [archiver removeArchiveInPath:archivePath error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"archive")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(0);
  });

  it(@"should successfully remove archive with linked content", ^{
    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();
    expect([storage.dictionary allValues]).to.haveCountOf(1);
    expect([storage.dictionary allValues].firstObject).to.haveCountOf(1);

    result = [archiver archiveTexture:[texture clone] inPath:LTPathMake(@"clonedArchive")
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();
    expect([storage.dictionary allValues]).to.haveCountOf(1);
    expect([storage.dictionary allValues].firstObject).to.haveCountOf(2);
    id secondRecord = [[storage.dictionary allValues].firstObject lastObject];

    result = [archiver removeArchiveInPath:archivePath error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"archive")).to.beFalsy();
    expect(LTDirectoryExists(@"clonedArchive")).to.beTruthy();
    expect([storage.dictionary allValues]).to.haveCountOf(1);
    expect([storage.dictionary allValues].firstObject).to.equal(@[secondRecord]);

    result = [archiver removeArchiveInPath:LTPathMake(@"clonedArchive") error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"clonedArchive")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(0);
  });

  it(@"should return error if trying to remove an archive that does not exist", ^{
    result = [archiver removeArchiveInPath:archivePath error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileNotFound);
  });

  it(@"should return error if failed to remove the archive or part of it", ^{
    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();

    OCMStub([fileManager removeItemAtPath:archivePath.path
                                    error:[OCMArg setTo:kFakeError]]).andReturn(NO);

    result = [archiver removeArchiveInPath:archivePath error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileRemovalFailed);
    expect(LTFileExists(@"archive/metadata.plist")).to.beTruthy();
    expect(LTFileExists(@"archive/content.mat")).to.beTruthy();
    expect([storage.dictionary allValues]).to.haveCountOf(0);
  });
});

context(@"maintenance", ^{
  beforeEach(^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 8)];
    result = [archiver archiveTexture:texture inPath:LTPathMake(@"a.1")
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    result = [archiver archiveTexture:texture inPath:LTPathMake(@"a.2")
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    result = [archiver archiveTexture:texture inPath:LTPathMake(@"a.3")
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    [texture mappedImageForWriting:^(cv::Mat *, BOOL) {}];
    result = [archiver archiveTexture:texture inPath:LTPathMake(@"b.1")
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    result = [archiver archiveTexture:texture inPath:LTPathMake(@"b.2")
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    result = [archiver archiveTexture:texture inPath:LTPathMake(@"b.3")
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
  });

  it(@"should not change stroage if all records are valid", ^{
    NSDictionary *beforeMaintenance = [storage.dictionary copy];
    [archiver performStorageMaintenance];
    expect(storage.dictionary).to.equal(beforeMaintenance);
  });

  it(@"should cleanup zombie records from existing keys", ^{
    [fileManager removeItemAtPath:LTPathMake(@"a.1/metadata.plist").path error:nil];
    [fileManager removeItemAtPath:LTPathMake(@"a.2/content.mat").path error:nil];
    [fileManager removeItemAtPath:LTPathMake(@"b.2").path error:nil];
    [fileManager removeItemAtPath:LTPathMake(@"b.3/metadata.plist").path error:nil];
    [archiver performStorageMaintenance];
    expect([storage.dictionary allValues]).to.haveCountOf(2);
    expect([storage.dictionary allValues].firstObject).to.haveCountOf(1);
    expect([storage.dictionary allValues].lastObject).to.haveCountOf(1);
  });

  it(@"should remove keys containing only zombie records", ^{
    [archiver performStorageMaintenance];
    [fileManager removeItemAtPath:LTPathMake(@"b.1").path error:nil];
    [fileManager removeItemAtPath:LTPathMake(@"b.2").path error:nil];
    [fileManager removeItemAtPath:LTPathMake(@"b.3").path error:nil];
    [archiver performStorageMaintenance];
    expect([storage.dictionary allValues]).to.haveCountOf(1);
    expect([storage.dictionary allValues].firstObject).to.haveCountOf(3);
  });
});

context(@"texture repository", ^{
  __block cv::Mat4b mat;
  __block NSString *generationID;

  beforeEach(^{
    mat.create(8, 4);
    mat.rowRange(0, 4).setTo(cv::Vec4b(255, 0, 0, 255));
    mat.rowRange(4, 8).setTo(cv::Vec4b(0, 255, 0, 255));
    texture = [LTTexture textureWithImage:mat];
    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    generationID = texture.generationID;
    OCMStub([textureRepository textureWithGenerationID:generationID]).andReturn(texture);

    NSString *contentPath = [archivePath pathByAppendingPathComponent:@"content.mat"].path;
    result = [fileManager removeItemAtPath:contentPath error:&error];
  });

  it(@"should add archived texture to repository", ^{
    result = [archiver archiveTexture:texture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];

    OCMVerify([textureRepository addTexture:texture]);
  });

  it(@"should clone from a texture in the repository when unarchiving to texture", ^{
    LTTexture *otherTexture = [LTTexture textureWithPropertiesOf:texture];
    result = [archiver unarchiveToTexture:otherTexture fromPath:archivePath error:&error];

    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(otherTexture.metadata).to.equal(texture.metadata);
    expect(otherTexture.generationID).to.equal(texture.generationID);
    expect($(otherTexture.image)).to.equalMat($(mat));
    OCMVerify([textureRepository addTexture:otherTexture]);
  });

  it(@"should return a clone of texture from repository when unarchiving", ^{
    LTTexture *otherTexture = [archiver unarchiveTextureFromPath:archivePath error:&error];

    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(otherTexture.metadata).to.equal(texture.metadata);
    expect(otherTexture).toNot.beIdenticalTo(texture);
    expect(otherTexture.generationID).to.equal(texture.generationID);
    expect($(otherTexture.image)).to.equalMat($(mat));
    OCMVerify([textureRepository addTexture:otherTexture]);
  });
});

context(@"duplication", ^{
  __block LTPath *targetPath;

  beforeEach(^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 8)];
    targetPath = LTPathMake(@"target");
  });

  it(@"should successfully duplicate a texture", ^{
    [archiver archiveTexture:texture inPath:archivePath withArchiveType:$(LTTextureArchiveTypeJPEG)
                       error:nil];

    result = [archiver duplicateTextureFromPath:archivePath toPath:targetPath error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"target")).to.beTruthy();
    expect(LTFileExists(@"target/metadata.plist")).to.beTruthy();
    expect(LTFileExists(@"target/content.jpg")).to.beTruthy();
    expect(LTLinkExists(@"archive/content.jpg")).to.beTruthy();
    expect(LTLinkExists(@"target/content.jpg")).to.beTruthy();
    expect([fileManager contentsEqualAtPath:LTPathMake(@"target/content.jpg").path
                                    andPath:LTPathMake(@"archive/content.jpg").path]).to.beTruthy();
    expect([storage.dictionary allValues]).to.haveCountOf(1);
  });

  it(@"should successfully duplicate a solid color texture", ^{
    [texture clearColor:LTVector4::ones()];
    [archiver archiveTexture:texture inPath:archivePath withArchiveType:$(LTTextureArchiveTypeJPEG)
                       error:nil];

    result = [archiver duplicateTextureFromPath:archivePath toPath:targetPath error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"target")).to.beTruthy();
    expect(LTFileExists(@"target/metadata.plist")).to.beTruthy();
    expect(LTFileExists(@"target/content.jpg")).to.beFalsy();
  });

  it(@"should successfully duplicate a texture using multiple files", ^{
    NSDictionary *data1 = @{@"a": @1, @"b": @2};
    NSDictionary *data2 = @{@"c": @3, @"d": @4};

    LTTextureArchiveType *typeMock = OCMPartialMock($(LTTextureArchiveTypeJPEG));
    id archiverMock = OCMProtocolMock(@protocol(LTTextureBaseArchiver));
    OCMStub([typeMock archiver]).andReturn(archiverMock);
    OCMStub([archiverMock archiveTexture:texture inPath:LTPathMake(@"archive/content.jpg").path
                                   error:[OCMArg anyObjectRef]]).andDo(^(NSInvocation *invocation) {
      [fileManager lt_writeDictionary:data1
                               toFile:LTPathMake(@"archive/content.jpg").path error:nil];
      [fileManager lt_writeDictionary:data2
                               toFile:LTPathMake(@"archive/aux.file").path error:nil];
      BOOL returnValue = YES;
      [invocation setReturnValue:&returnValue];
    });

    result = [archiver archiveTexture:texture inPath:archivePath withArchiveType:typeMock
                                error:nil];

    result = [archiver duplicateTextureFromPath:archivePath toPath:targetPath error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"target")).to.beTruthy();
    expect(LTFileExists(@"target/metadata.plist")).to.beTruthy();
    expect(LTFileExists(@"target/content.jpg")).to.beTruthy();
    expect(LTLinkExists(@"target/content.jpg")).to.beTruthy();
    expect(LTFileExists(@"target/aux.file")).to.beTruthy();
    expect(LTLinkExists(@"target/aux.file")).to.beTruthy();
  });

  it(@"should return error if archive folder with given name exists", ^{
    [fileManager createDirectoryAtPath:targetPath.path withIntermediateDirectories:NO
                            attributes:nil error:nil];

    result = [archiver duplicateTextureFromPath:archivePath toPath:targetPath error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileAlreadyExists);
    expect(LTDirectoryExists(@"target")).to.beTruthy();
    expect(LTFileExists(@"target/metadata.plist")).to.beFalsy();
    expect(LTFileExists(@"target/content.jpg")).to.beFalsy();
  });

  it(@"should fail if there is no metadata", ^{
    result = [archiver duplicateTextureFromPath:archivePath toPath:targetPath error:&error];
    expect(result).to.beFalsy();
    expect(error).toNot.beNil();
    expect(error.code).to.equal(LTErrorCodeFileNotFound);
  });

  it(@"should return error and clean filesystem if failed to save texture metadata", ^{
    [archiver archiveTexture:texture inPath:archivePath withArchiveType:$(LTTextureArchiveTypeJPEG)
                       error:nil];

    NSString *metadataPath = [targetPath pathByAppendingPathComponent:@"metadata.plist"].path;
    OCMStub([fileManager lt_writeDictionary:[OCMArg any] toFile:metadataPath
                                      error:[OCMArg setTo:kFakeError]]).andReturn(NO);

    result = [archiver duplicateTextureFromPath:archivePath toPath:targetPath error:&error];
    expect(result).to.beFalsy();
    expect(error).to.equal(kFakeError);
    expect(LTDirectoryExists(@"target")).to.beFalsy();
  });

  it(@"should return error and clean filesystem if failed to link content", ^{
    [archiver archiveTexture:texture inPath:archivePath withArchiveType:$(LTTextureArchiveTypeJPEG)
                       error:nil];

    NSString *contentPath = [targetPath pathByAppendingPathComponent:@"content.jpg"].path;
    OCMStub([fileManager linkItemAtPath:[OCMArg any] toPath:contentPath
                                  error:[OCMArg setTo:kFakeError]]).andReturn(NO);

    result = [archiver duplicateTextureFromPath:archivePath toPath:targetPath error:&error];
    expect(result).to.beFalsy();
    expect(LTDirectoryExists(@"target")).to.beFalsy();
  });
});

it(@"should not retain archived texture", ^{
  __weak LTTexture *weakTexture;

  // needed so the mock won't keep a reference to the texture.
  archiver = [[LTTextureArchiver alloc] initWithStorage:storage
                                      textureRepository:[[LTTextureRepository alloc] init]];
  @autoreleasepool {
    LTTexture *newTexture = [LTTexture byteRedTextureWithSize:CGSizeMake(1, 2)];
    weakTexture = newTexture;
    result = [archiver archiveTexture:newTexture inPath:archivePath
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
  }

  expect(weakTexture).to.beNil();
});

SpecEnd
