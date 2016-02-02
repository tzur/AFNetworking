// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureArchiver.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSError+LTKit.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "LTGLTexture.h"
#import "LTImage.h"
#import "LTTexture+Factory.h"
#import "LTTextureArchiveType.h"
#import "LTTextureArchiverNonPersistentStorage.h"
#import "LTTextureBaseArchiver.h"
#import "LTTextureMetadata.h"

static BOOL LTLinkExists(NSString *relativePath) {
  NSDictionary *attributes =  [[NSFileManager defaultManager]
                               attributesOfItemAtPath:LTTemporaryPath(relativePath) error:nil];

  return ![attributes[NSFileType] isEqual:NSFileTypeDirectory] &&
         [attributes[NSFileReferenceCount] unsignedLongValue] > 1;
}

static BOOL LTDirectoryExists(NSString *relativePath) {
  return [[NSFileManager defaultManager] lt_directoryExistsAtPath:LTTemporaryPath(relativePath)];
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

static NSError * const kFakeError = [NSError errorWithDomain:@"foo" code:1337 userInfo:nil];

beforeEach(^{
  fileManager = OCMPartialMock([NSFileManager defaultManager]);
  LTBindObjectToClass(fileManager, [NSFileManager class]);
  storage = [[LTTextureArchiverNonPersistentStorage alloc] init];
  mock = OCMPartialMock(storage);


  LTPath *path = [LTPath pathWithPath:LTTemporaryPath()];
  archiver = [[LTTextureArchiver alloc] initWithStorage:storage baseDirectory:path];
  [fileManager removeItemAtPath:path.path error:nil];
  [fileManager createDirectoryAtPath:path.path withIntermediateDirectories:NO
                          attributes:nil error:nil];
});

afterEach(^{
  [fileManager stopMocking];
  fileManager = nil;
  texture = nil;
  archiver = nil;
  storage = nil;
  mock = nil;
  error = nil;
  result = NO;
});

context(@"initialization", ^{
  it(@"should initialize with the given base directory", ^{
    archiver = [[LTTextureArchiver alloc] initWithStorage:storage
                                            baseDirectory:[LTPath pathWithPath:@"somePath"]];
    expect(archiver.baseDirectory).to.equal([LTPath pathWithPath:@"somePath"]);
  });

  it(@"should initialize with the documents directory", ^{
    archiver = [[LTTextureArchiver alloc] initWithStorage:storage];
    expect(archiver.baseDirectory.baseDirectory).to.equal(LTPathBaseDirectoryDocuments);
    expect(archiver.baseDirectory.relativePath).to.equal(@"/");
  });
});

context(@"archiving", ^{
  beforeEach(^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 8)];
  });

  it(@"should archive texture", ^{
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"archive")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"archive/metadata.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"archive/content.jpg")).to.beTruthy();
  });

  it(@"should raise if trying to archive a mipmap texture", ^{
    texture = [[LTGLTexture alloc] initWithBaseLevelMipmapImage:cv::Mat4b(16, 16)];
    expect(^{
      result = [archiver archiveTexture:texture inPath:@"archive"
                        withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should return error and clean filesystem if archive folder with given name exists", ^{
    [fileManager createDirectoryAtPath:LTTemporaryPath(@"archive") withIntermediateDirectories:NO
                            attributes:nil error:nil];
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileAlreadyExists);
    expect(LTDirectoryExists(@"archive")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"archive/metadata.plist")).to.beFalsy();
    expect(LTFileExistsInTemporaryPath(@"archive/content.jpg")).to.beFalsy();
  });

  it(@"should return error and clean filesystem if metadata file with given name exists", ^{
    OCMStub([fileManager fileExistsAtPath:LTTemporaryPath(@"archive/metadata.plist")])
        .andReturn(YES);
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beFalsy();
    expect(error.code).to.equal(LTErrorCodeFileAlreadyExists);
    expect(LTDirectoryExists(@"archive")).to.beFalsy();
  });

  it(@"should return error and clean filesystem if failed to archive the content", ^{
    id typeMock = OCMPartialMock($(LTTextureArchiveTypeJPEG));
    id archiverMock = OCMProtocolMock(@protocol(LTTextureBaseArchiver));
    OCMStub([typeMock archiver]).andReturn(archiverMock);
    OCMStub([archiverMock archiveTexture:[OCMArg any] inPath:LTTemporaryPath(@"archive/content.jpg")
                                   error:[OCMArg setTo:kFakeError]]).andReturn(NO);

    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:typeMock error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.lt_underlyingError).to.equal(kFakeError);
    expect(LTDirectoryExists(@"archive")).to.beFalsy();
  });

  it(@"should return error and clean filesystem if failed to save texture metadata", ^{
    OCMStub([fileManager lt_writeDictionary:[OCMArg any]
                                     toFile:LTTemporaryPath(@"archive/metadata.plist")
                                      error:[OCMArg setTo:kFakeError]]).andReturn(NO);
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beFalsy();
    expect(error).to.equal(kFakeError);
    expect(LTDirectoryExists(@"archive")).to.beFalsy();
  });

  it(@"should not save content of texture with solid fillColor", ^{
    [texture clearWithColor:LTVector4::ones()];
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"archive")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"archive/metadata.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"archive/content.jpg")).to.beFalsy();
  });

  it(@"should save content of a unique texture", ^{
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect([storage.dictionary allValues]).to.haveCountOf(1);

    LTTexture *otherTexture = [LTTexture textureWithPropertiesOf:texture];
    result = [archiver archiveTexture:otherTexture inPath:@"otherArchive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"otherArchive")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"otherArchive/metadata.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"otherArchive/content.jpg")).to.beTruthy();
    expect(LTLinkExists(@"otherArchive/content.jpg")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(2);
  });

  it(@"should save content of an existing texture with different archive type", ^{
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect([storage.dictionary allValues]).to.haveCountOf(1);

    LTTexture *otherTexture = [texture clone];
    result = [archiver archiveTexture:otherTexture inPath:@"otherArchive"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"otherArchive")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"otherArchive/metadata.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"otherArchive/content.mat")).to.beTruthy();
    expect(LTLinkExists(@"otherArchive/content.mat")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(2);
  });

  context(@"linked to existing texture", ^{
    beforeEach(^{
      result = [archiver archiveTexture:texture inPath:@"archive"
                        withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(LTDirectoryExists(@"archive")).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"archive/metadata.plist")).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"archive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"archive/content.jpg")).to.beFalsy();
      expect([storage.dictionary allValues]).to.haveCountOf(1);
    });

    it(@"should create link in case an identical texture is already archived", ^{
      LTTexture *otherTexture = [texture clone];
      result = [archiver archiveTexture:otherTexture inPath:@"otherArchive"
                        withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(LTDirectoryExists(@"otherArchive")).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"otherArchive/metadata.plist")).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"otherArchive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"archive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"otherArchive/content.jpg")).to.beTruthy();
      expect([fileManager contentsEqualAtPath:LTTemporaryPath(@"otherArchive/content.jpg")
              andPath:LTTemporaryPath(@"archive/content.jpg")]).to.beTruthy();
      expect([storage.dictionary allValues]).to.haveCountOf(1);
    });

    it(@"should create link and cleanup zombie records in case identical texture is archived", ^{
      expect([storage.dictionary allValues].firstObject).to.haveCountOf(1);
      id firstRecord = [[storage.dictionary allValues].firstObject lastObject];

      LTTexture *otherTexture = [texture clone];
      result = [archiver archiveTexture:otherTexture inPath:@"otherArchive"
                        withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
      expect([storage.dictionary allValues].firstObject).to.haveCountOf(2);
      id secondRecord = [[storage.dictionary allValues].firstObject lastObject];

      [fileManager removeItemAtPath:LTTemporaryPath(@"archive/content.jpg") error:nil];

      LTTexture *anotherTexture = [texture clone];
      result = [archiver archiveTexture:anotherTexture inPath:@"anotherArchive"
                        withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(LTDirectoryExists(@"anotherArchive")).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"anotherArchive/metadata.plist")).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"anotherArchive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"otherArchive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"anotherArchive/content.jpg")).to.beTruthy();
      expect([fileManager contentsEqualAtPath:LTTemporaryPath(@"anotherArchive/content.jpg")
              andPath:LTTemporaryPath(@"otherArchive/content.jpg")]).to.beTruthy();
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
      OCMStub([archiverMock archiveTexture:texture inPath:LTTemporaryPath(@"archive/content.jpg")
               error:[OCMArg anyObjectRef]]).andDo(^(NSInvocation *invocation) {
        [fileManager lt_writeDictionary:data1
                                 toFile:LTTemporaryPath(@"archive/content.jpg") error:nil];
        [fileManager lt_writeDictionary:data2
                                 toFile:LTTemporaryPath(@"archive/aux.file") error:nil];
        BOOL returnValue = YES;
        [invocation setReturnValue:&returnValue];
      });
    });

    afterEach(^{
      typeMock = nil;
    });

    it(@"should archive correctly", ^{
      result = [archiver archiveTexture:texture inPath:@"archive"
                        withArchiveType:typeMock error:&error];
      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(LTDirectoryExists(@"archive")).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"archive/metadata.plist")).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"archive/content.jpg")).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"archive/aux.file")).to.beTruthy();
    });

    it(@"should create links for all files of archives that create multiple files", ^{
      result = [archiver archiveTexture:texture inPath:@"archive"
                        withArchiveType:typeMock error:&error];

      result = [archiver archiveTexture:[texture clone] inPath:@"otherArchive"
                        withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];

      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(LTDirectoryExists(@"otherArchive")).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"otherArchive/metadata.plist")).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"otherArchive/content.jpg")).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"otherArchive/aux.file")).to.beTruthy();
      expect(LTLinkExists(@"archive/metadata.plist")).to.beFalsy();
      expect(LTLinkExists(@"archive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"archive/aux.file")).to.beTruthy();
      expect(LTLinkExists(@"otherArchive/metadata.plist")).to.beFalsy();
      expect(LTLinkExists(@"otherArchive/content.jpg")).to.beTruthy();
      expect(LTLinkExists(@"otherArchive/aux.file")).to.beTruthy();
      expect([fileManager contentsEqualAtPath:LTTemporaryPath(@"otherArchive/content.jpg")
              andPath:LTTemporaryPath(@"archive/content.jpg")]).to.beTruthy();
      expect([fileManager contentsEqualAtPath:LTTemporaryPath(@"otherArchive/aux.file")
              andPath:LTTemporaryPath(@"archive/aux.file")]).to.beTruthy();
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

    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();
  });

  context(@"unarchive to given texture", ^{
    it(@"should unarchive correctly", ^{
      LTTexture *otherTexture = [LTTexture textureWithPropertiesOf:texture];
      result = [archiver unarchiveToTexture:otherTexture fromPath:@"archive" error:&error];
      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(mat));
    });

    it(@"should raise if trying to unarchive to a wrong texture type", ^{
      expect(^{
        [archiver unarchiveToTexture:[LTTexture byteRGBATextureWithSize:texture.size * 2]
                            fromPath:@"archive" error:nil];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [archiver unarchiveToTexture:[LTTexture byteRedTextureWithSize:texture.size]
                            fromPath:@"archive" error:nil];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [archiver unarchiveToTexture:[LTTexture textureWithSize:texture.size
                                                    pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                                 allocateMemory:YES]
                            fromPath:@"archive" error:nil];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise if trying to unarchive to a mipmap texture", ^{
      expect(^{
        [archiver unarchiveToTexture:[[LTGLTexture alloc]
                                      initWithSize:texture.size pixelFormat:texture.pixelFormat
                                      maxMipmapLevel:1]
                            fromPath:@"archive" error:nil];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should return error if archive does not exist", ^{
      result = [archiver unarchiveToTexture:texture fromPath:@"noArchive" error:&error];
      expect(result).to.beFalsy();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileNotFound);
    });

    it(@"should return error if failed to load archive metadata", ^{
      OCMStub([fileManager
               lt_dictionaryWithContentsOfFile:LTTemporaryPath(@"archive/metadata.plist")
               error:[OCMArg setTo:kFakeError]]);

      result = [archiver unarchiveToTexture:texture fromPath:@"archive" error:&error];
      expect(result).to.beFalsy();
      expect(error).notTo.beNil();
      expect(error).to.equal(kFakeError);
    });

    it(@"should return error if failed to load archive content", ^{
      OCMStub([fileManager lt_dataWithContentsOfFile:LTTemporaryPath(@"archive/content.mat")
                                             options:NSDataReadingUncached
                                               error:[OCMArg setTo:kFakeError]]);

      result = [archiver unarchiveToTexture:texture fromPath:@"archive" error:&error];
      expect(result).to.beFalsy();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileReadFailed);
      expect(error.userInfo[NSUnderlyingErrorKey]).to.equal(kFakeError);
    });

    it(@"should unarchive texture with solid color", ^{
      [texture clearWithColor:LTVector4(0.25, 0.5, 0.75, 1.0)];
      result = [archiver archiveTexture:texture inPath:@"solidFillArchive"
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"solidFillArchive/content.mat")).to.beFalsy();

      LTTexture *otherTexture = [LTTexture textureWithPropertiesOf:texture];
      [archiver unarchiveToTexture:otherTexture fromPath:@"solidFillArchive" error:&error];

      expect(error).to.beNil();
      expect(otherTexture).notTo.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.fillColor).to.equal(texture.fillColor);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(texture.image));
    });

    it(@"should unarchive texture with linked content", ^{
      LTTexture *clonedTexture = [texture clone];
      result = [archiver archiveTexture:clonedTexture inPath:@"clonedArchive"
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();
      expect(LTLinkExists(@"clonedArchive/content.mat")).to.beTruthy();

      LTTexture *otherTexture = [LTTexture textureWithPropertiesOf:texture];
      [archiver unarchiveToTexture:otherTexture fromPath:@"clonedArchive" error:&error];

      expect(error).to.beNil();
      expect(otherTexture).notTo.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(texture.image));
    });
  });

  context(@"unarchive to new texture", ^{
    it(@"should unarchive correctly", ^{
      LTTexture *otherTexture = [archiver unarchiveTextureFromPath:@"archive" error:&error];
      expect(error).to.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(mat));
    });
    
    it(@"should return nil if archive does not exist", ^{
      texture = [archiver unarchiveTextureFromPath:@"noArchive" error:&error];
      expect(texture).to.beNil();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileNotFound);
    });

    it(@"should return nil if failed to load archive metadata", ^{
      OCMStub([fileManager
               lt_dictionaryWithContentsOfFile:LTTemporaryPath(@"archive/metadata.plist")
               error:[OCMArg setTo:kFakeError]]);

      texture = [archiver unarchiveTextureFromPath:@"archive" error:&error];
      expect(texture).to.beNil();
      expect(error).notTo.beNil();
      expect(error).to.equal(kFakeError);
    });

    it(@"should return nil if failed to load archive content", ^{
      OCMStub([fileManager lt_dataWithContentsOfFile:LTTemporaryPath(@"archive/content.mat")
                                             options:NSDataReadingUncached
                                               error:[OCMArg setTo:kFakeError]]);

      texture = [archiver unarchiveTextureFromPath:@"archive" error:&error];
      expect(texture).to.beNil();
      expect(error).notTo.beNil();
      expect(error.lt_underlyingError).to.equal(kFakeError);
    });

    it(@"should unarchive texture with solid color", ^{
      [texture clearWithColor:LTVector4(0.25, 0.5, 0.75, 1.0)];
      result = [archiver archiveTexture:texture inPath:@"solidFillArchive"
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"solidFillArchive/content.mat")).to.beFalsy();

      LTTexture *otherTexture = [archiver unarchiveTextureFromPath:@"solidFillArchive"
                                                             error:&error];

      expect(error).to.beNil();
      expect(otherTexture).notTo.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.fillColor).to.equal(texture.fillColor);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(texture.image));
    });

    it(@"should unarchive texture with linked content", ^{
      LTTexture *clonedTexture = [texture clone];
      result = [archiver archiveTexture:clonedTexture inPath:@"clonedArchive"
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();
      expect(LTLinkExists(@"clonedArchive/content.mat")).to.beTruthy();

      LTTexture *otherTexture = [archiver unarchiveTextureFromPath:@"clonedArchive" error:&error];

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
      image = [archiver unarchiveImageFromPath:@"archive" error:&error];
      expect(error).to.beNil();
      expect(image.size).to.equal(texture.size);
      expect($([[LTImage alloc] initWithImage:image].mat)).to.equalMat($(texture.image));
    });
    
    it(@"should return nil if archive does not exist", ^{
      image = [archiver unarchiveImageFromPath:@"noArchive" error:&error];
      expect(image).to.beNil();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileNotFound);
    });

    it(@"should return nil if failed to load archive metadata", ^{
      OCMStub([fileManager
               lt_dictionaryWithContentsOfFile:LTTemporaryPath(@"archive/metadata.plist")
               error:[OCMArg setTo:kFakeError]]);

      image = [archiver unarchiveImageFromPath:@"archive" error:&error];
      expect(image).to.beNil();
      expect(error).notTo.beNil();
      expect(error).to.equal(kFakeError);
    });

    it(@"should return nil if failed to load archive content", ^{
      OCMStub([fileManager lt_dataWithContentsOfFile:LTTemporaryPath(@"archive/content.mat")
                                             options:NSDataReadingUncached
                                               error:[OCMArg setTo:kFakeError]]);

      image = [archiver unarchiveImageFromPath:@"archive" error:&error];
      expect(image).to.beNil();
      expect(error).notTo.beNil();
      expect(error.lt_underlyingError).to.equal(kFakeError);
    });

    it(@"should return nil if archive pixel format is not byte RGBA", ^{
      LTTexture *greyTexture = [LTTexture byteRedTextureWithSize:texture.size];
      result = [archiver archiveTexture:greyTexture inPath:@"greyArchive"
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();

      LTTexture *halfFloatTexture = [LTTexture textureWithSize:texture.size
                                                   pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                                allocateMemory:YES];
      result = [archiver archiveTexture:halfFloatTexture inPath:@"halfFloatArchive"
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();

      image = [archiver unarchiveImageFromPath:@"greyArchive" error:&error];
      expect(image).to.beNil();
      expect(error).notTo.beNil();

      error = nil;
      image = [archiver unarchiveImageFromPath:@"halfFloatArchive" error:&error];
      expect(image).to.beNil();
      expect(error).notTo.beNil();
    });

    it(@"should unarchive image with solid color", ^{
      [texture clearWithColor:LTVector4(0.25, 0.5, 0.75, 1.0)];
      result = [archiver archiveTexture:texture inPath:@"solidFillArchive"
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();
      expect(LTFileExistsInTemporaryPath(@"solidFillArchive/content.mat")).to.beFalsy();

      image = [archiver unarchiveImageFromPath:@"solidFillArchive" error:&error];

      expect(error).to.beNil();
      expect(image).notTo.beNil();
      expect($([[LTImage alloc] initWithImage:image].mat)).to.equalMat($(texture.image));
    });

    it(@"should unarchive image with linked content", ^{
      LTTexture *clonedTexture = [texture clone];
      result = [archiver archiveTexture:clonedTexture inPath:@"clonedArchive"
                        withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();
      expect(LTLinkExists(@"clonedArchive/content.mat")).to.beTruthy();

      image = [archiver unarchiveImageFromPath:@"clonedArchive" error:&error];

      expect(error).to.beNil();
      expect(image).notTo.beNil();
      expect($([[LTImage alloc] initWithImage:image].mat)).to.equalMat($(texture.image));
    });
  });
});

context(@"removing", ^{
  beforeEach(^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 8)];
  });

  it(@"should successfully remove archive", ^{
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();

    result = [archiver removeArchiveInPath:@"archive" error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"archive")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(0);
  });

  it(@"should successfully remove archive of solid color texture", ^{
    [texture clearWithColor:LTVector4::ones()];
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();

    result = [archiver removeArchiveInPath:@"archive" error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"archive")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(0);
  });

  it(@"should successfully remove archive with linked content", ^{
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();
    expect([storage.dictionary allValues]).to.haveCountOf(1);
    expect([storage.dictionary allValues].firstObject).to.haveCountOf(1);

    result = [archiver archiveTexture:[texture clone] inPath:@"clonedArchive"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();
    expect([storage.dictionary allValues]).to.haveCountOf(1);
    expect([storage.dictionary allValues].firstObject).to.haveCountOf(2);
    id secondRecord = [[storage.dictionary allValues].firstObject lastObject];

    result = [archiver removeArchiveInPath:@"archive" error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"archive")).to.beFalsy();
    expect(LTDirectoryExists(@"clonedArchive")).to.beTruthy();
    expect([storage.dictionary allValues]).to.haveCountOf(1);
    expect([storage.dictionary allValues].firstObject).to.equal(@[secondRecord]);

    result = [archiver removeArchiveInPath:@"clonedArchive" error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTDirectoryExists(@"clonedArchive")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(0);
  });

  it(@"should return error if trying to remove an archive that does not exist", ^{
    result = [archiver removeArchiveInPath:@"archive" error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileNotFound);
  });

  it(@"should return error if failed to remove the archive or part of it", ^{
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();

    OCMStub([fileManager removeItemAtPath:LTTemporaryPath(@"archive")
                                    error:[OCMArg setTo:kFakeError]]).andReturn(NO);

    result = [archiver removeArchiveInPath:@"archive" error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileRemovalFailed);
    expect(LTFileExistsInTemporaryPath(@"archive/metadata.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"archive/content.mat")).to.beTruthy();
    expect([storage.dictionary allValues]).to.haveCountOf(0);
  });
});

context(@"maintenance", ^{
  beforeEach(^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 8)];
    result = [archiver archiveTexture:texture inPath:@"a.1"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    result = [archiver archiveTexture:texture inPath:@"a.2"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    result = [archiver archiveTexture:texture inPath:@"a.3"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    [texture mappedImageForWriting:^(cv::Mat *, BOOL) {}];
    result = [archiver archiveTexture:texture inPath:@"b.1"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    result = [archiver archiveTexture:texture inPath:@"b.2"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    result = [archiver archiveTexture:texture inPath:@"b.3"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
  });

  it(@"should not change stroage if all records are valid", ^{
    NSDictionary *beforeMaintenance = [storage.dictionary copy];
    [archiver performStorageMaintenance];
    expect(storage.dictionary).to.equal(beforeMaintenance);
  });

  it(@"should cleanup zombie records from existing keys", ^{
    [fileManager removeItemAtPath:LTTemporaryPath(@"a.1/metadata.plist") error:nil];
    [fileManager removeItemAtPath:LTTemporaryPath(@"a.2/content.mat") error:nil];
    [fileManager removeItemAtPath:LTTemporaryPath(@"b.2") error:nil];
    [fileManager removeItemAtPath:LTTemporaryPath(@"b.3/metadata.plist") error:nil];
    [archiver performStorageMaintenance];
    expect([storage.dictionary allValues]).to.haveCountOf(2);
    expect([storage.dictionary allValues].firstObject).to.haveCountOf(1);
    expect([storage.dictionary allValues].lastObject).to.haveCountOf(1);
  });

  it(@"should remove keys containing only zombie records", ^{
    [archiver performStorageMaintenance];
    [fileManager removeItemAtPath:LTTemporaryPath(@"b.1") error:nil];
    [fileManager removeItemAtPath:LTTemporaryPath(@"b.2") error:nil];
    [fileManager removeItemAtPath:LTTemporaryPath(@"b.3") error:nil];
    [archiver performStorageMaintenance];
    expect([storage.dictionary allValues]).to.haveCountOf(1);
    expect([storage.dictionary allValues].firstObject).to.haveCountOf(3);
  });
});

SpecEnd
