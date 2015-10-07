// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureArchiver.h"

#import <LTKit/NSError+LTKit.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "LTGLTexture.h"
#import "LTTexture+Factory.h"
#import "LTTextureArchiveType.h"
#import "LTTextureMetadata.h"

static BOOL LTLinkExists(NSString *relativePath) {
  NSDictionary *attributes =  [[NSFileManager defaultManager]
                               attributesOfItemAtPath:LTTemporaryPath(relativePath) error:nil];

  return [attributes[NSFileReferenceCount] unsignedLongValue] > 1;
}

@interface LTTextureArchiverTestStorage : NSObject <LTTextureArchiverStorage>
@property (strong, nonatomic) NSMutableDictionary *dictionary;
@end

@implementation LTTextureArchiverTestStorage

- (instancetype)init {
  if (self = [super init]) {
    self.dictionary = [NSMutableDictionary dictionary];
  }
  return self;
}

- (id)objectForKeyedSubscript:(NSString *)key {
  return self.dictionary[key];
}

- (void)setObject:(id<NSCopying>)object forKeyedSubscript:(NSString *)key {
  self.dictionary[key] = object;
}

- (void)removeObjectForKey:(NSString *)key {
  [self.dictionary removeObjectForKey:key];
}

- (NSArray *)allKeys {
  return [self.dictionary allKeys];
}

@end

SpecBegin(LTTextureArchive)

__block BOOL result;
__block NSError *error;
__block LTTexture *texture;
__block LTTextureArchiver *archiver;
__block LTTextureArchiverTestStorage *storage;
__block id mock;
__block id fileManager;

static NSError * const kFakeError = [NSError errorWithDomain:@"foo" code:1337 userInfo:nil];

beforeEach(^{
  fileManager = OCMPartialMock([NSFileManager defaultManager]);
  LTBindObjectToClass(fileManager, [NSFileManager class]);
  storage = [[LTTextureArchiverTestStorage alloc] init];
  mock = OCMPartialMock(storage);

  NSString *path = LTTemporaryPath();
  archiver = [[LTTextureArchiver alloc] initWithStorage:storage baseDirectory:path];
  [fileManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
});

afterEach(^{
  [fileManager removeItemAtPath:LTTemporaryPath() error:nil];
  texture = nil;
  archiver = nil;
  storage = nil;
  mock = nil;
  error = nil;
  result = NO;
  fileManager = nil;
});

context(@"initialization", ^{
  it(@"should initialize with the given base directory", ^{
    archiver = [[LTTextureArchiver alloc] initWithStorage:storage baseDirectory:@"somePath"];
    expect(archiver.baseDirectory).to.equal(@"somePath");
  });

  it(@"should initialize with the documents directory", ^{
    NSString *path = @"documentsPath";
    OCMStub([fileManager lt_documentsDirectory]).andReturn(path);
    archiver = [[LTTextureArchiver alloc] initWithStorage:storage];
    expect(archiver.baseDirectory).to.equal(path);
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
    expect(LTFileExistsInTemporaryPath(@"archive.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"archive.jpg")).to.beTruthy();
  });

  it(@"should raise if trying to archive a mipmap texture", ^{
    texture = [[LTGLTexture alloc] initWithBaseLevelMipmapImage:cv::Mat4b(16, 16)];
    expect(^{
      result = [archiver archiveTexture:texture inPath:@"archive"
                        withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should return error without saving content if archive metadata with given name exists", ^{
    OCMStub([fileManager fileExistsAtPath:LTTemporaryPath(@"archive.plist")]).andReturn(YES);
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.jpg")).to.beFalsy();
  });

  it(@"should return error without saving metadata if archive content with given name exists", ^{
    OCMStub([fileManager fileExistsAtPath:LTTemporaryPath(@"archive.jpg")]).andReturn(YES);
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.plist")).to.beFalsy();
  });

  it(@"should return error if failed to save texture metadata", ^{
    OCMStub([fileManager lt_writeDictionary:[OCMArg any]
                                     toFile:LTTemporaryPath(@"archive.plist")]).andReturn(NO);
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.jpg")).to.beFalsy();
  });

  it(@"should not save content of texture with solid fillColor", ^{
    [texture clearWithColor:LTVector4One];
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"archive.jpg")).to.beFalsy();
  });

  it(@"should save content of a unique texture", ^{
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"archive.jpg")).to.beTruthy();
    expect(LTLinkExists(@"archive.jpg")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(1);

    LTTexture *otherTexture = [LTTexture textureWithPropertiesOf:texture];
    result = [archiver archiveTexture:otherTexture inPath:@"otherArchive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"otherArchive.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"otherArchive.jpg")).to.beTruthy();
    expect(LTLinkExists(@"otherArchive.jpg")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(2);
  });

  it(@"should save content of an existing texture with different archive type", ^{
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"archive.jpg")).to.beTruthy();
    expect(LTLinkExists(@"archive.jpg")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(1);

    LTTexture *otherTexture = [texture clone];
    result = [archiver archiveTexture:otherTexture inPath:@"otherArchive"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"otherArchive.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"otherArchive.mat")).to.beTruthy();
    expect(LTLinkExists(@"otherArchive.mat")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(2);
  });

  it(@"should create link in case an identical texture is already archived", ^{
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"archive.jpg")).to.beTruthy();
    expect(LTLinkExists(@"archive.jpg")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(1);

    LTTexture *otherTexture = [texture clone];
    result = [archiver archiveTexture:otherTexture inPath:@"otherArchive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"otherArchive.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"otherArchive.jpg")).to.beTruthy();
    expect(LTLinkExists(@"archive.jpg")).to.beTruthy();
    expect(LTLinkExists(@"otherArchive.jpg")).to.beTruthy();
    expect([storage.dictionary allValues]).to.haveCountOf(1);
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
      result = [archiver unarchiveToTexture:otherTexture fromPath:@"archive"
                            withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beTruthy();
      expect(error).to.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(mat));
    });

    it(@"should raise if trying to unarchive to a wrong texture type", ^{
      expect(^{
        [archiver unarchiveToTexture:[LTTexture byteRGBATextureWithSize:texture.size * 2]
                            fromPath:@"archive"
                     withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:nil];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [archiver unarchiveToTexture:[LTTexture byteRedTextureWithSize:texture.size]
                            fromPath:@"archive"
                     withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:nil];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [archiver unarchiveToTexture:[LTTexture textureWithSize:texture.size
                                                      precision:LTTexturePrecisionHalfFloat
                                                         format:texture.format allocateMemory:YES]
                            fromPath:@"archive"
                     withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:nil];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise if trying to unarchive to a mipmap texture", ^{
      expect(^{
        [archiver unarchiveToTexture:[[LTGLTexture alloc]
                                      initWithSize:texture.size precision:texture.precision
                                      format:texture.format maxMipmapLevel:1]
                            fromPath:@"archive"
                     withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:nil];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should return error if archive does not exist", ^{
      result = [archiver unarchiveToTexture:texture fromPath:@"noArchive"
                            withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beFalsy();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileNotFound);
    });

    it(@"should return error if failed to load archive metadata", ^{
      OCMStub([fileManager lt_dictionaryWithContentsOfFile:[OCMArg any]]);
      result = [archiver unarchiveToTexture:texture fromPath:@"archive"
                            withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beFalsy();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileReadFailed);
    });

    it(@"should return error if failed to load archive content", ^{
      OCMStub([fileManager lt_dataWithContentsOfFile:[OCMArg any] options:NSDataReadingUncached
                                               error:[OCMArg setTo:kFakeError]]);
      result = [archiver unarchiveToTexture:texture fromPath:@"archive"
                            withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(result).to.beFalsy();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileReadFailed);
      expect(error.userInfo[NSUnderlyingErrorKey]).to.equal(kFakeError);
    });
  });

  context(@"unarchive to new texture", ^{
    it(@"should unarchive correctly", ^{
      LTTexture *otherTexture = [archiver unarchiveFromPath:@"archive"
                                            withArchiveType:$(LTTextureArchiveTypeUncompressedMat)
                                                      error:&error];
      expect(error).to.beNil();
      expect(otherTexture.metadata).to.equal(texture.metadata);
      expect(otherTexture.generationID).to.equal(texture.generationID);
      expect($(otherTexture.image)).to.equalMat($(mat));
    });
    
    it(@"should return nil if archive does not exist", ^{
      texture = [archiver unarchiveFromPath:@"noArchive"
                            withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(texture).to.beNil();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileNotFound);
    });

    it(@"should return nil if failed to load archive metadata", ^{
      OCMStub([fileManager lt_dictionaryWithContentsOfFile:[OCMArg any]]);
      texture = [archiver unarchiveFromPath:@"archive"
                            withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(texture).to.beNil();
      expect(error).notTo.beNil();
      expect(error.code).to.equal(LTErrorCodeFileReadFailed);
    });

    it(@"should return nil if failed to load archive content", ^{
      OCMStub([fileManager lt_dataWithContentsOfFile:[OCMArg any] options:NSDataReadingUncached
                                               error:[OCMArg setTo:kFakeError]]);
      texture = [archiver unarchiveFromPath:@"archive"
                            withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
      expect(texture).to.beNil();
      expect(error).notTo.beNil();
      expect(error.userInfo[NSUnderlyingErrorKey]).to.equal(kFakeError);
    });
  });

  it(@"should unarchive texture with solid color", ^{
    [texture clearWithColor:LTVector4One];
    result = [archiver archiveTexture:texture inPath:@"solidFillArchive"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"otherArchive.mat")).to.beFalsy();

    LTTexture *otherTexture = [archiver unarchiveFromPath:@"solidFillArchive"
                                          withArchiveType:$(LTTextureArchiveTypeUncompressedMat)
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
    expect(LTLinkExists(@"clonedArchive.mat")).to.beTruthy();

    LTTexture *otherTexture = [archiver unarchiveFromPath:@"clonedArchive"
                                          withArchiveType:$(LTTextureArchiveTypeUncompressedMat)
                                                    error:&error];

    expect(error).to.beNil();
    expect(otherTexture).notTo.beNil();
    expect(otherTexture.metadata).to.equal(texture.metadata);
    expect(otherTexture.generationID).to.equal(texture.generationID);
    expect($(otherTexture.image)).to.equalMat($(texture.image));
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

    result = [archiver removeArchiveType:$(LTTextureArchiveTypeUncompressedMat)
                                  inPath:@"archive" error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.plist")).to.beFalsy();
    expect(LTFileExistsInTemporaryPath(@"archive.mat")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(0);
  });

  it(@"should successfully remove archive of solid color texture", ^{
    [texture clearWithColor:LTVector4One];
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();

    result = [archiver removeArchiveType:$(LTTextureArchiveTypeUncompressedMat)
                                  inPath:@"archive" error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    expect(LTFileExistsInTemporaryPath(@"archive.plist")).to.beFalsy();
    expect(LTFileExistsInTemporaryPath(@"archive.mat")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(0);
  });

  it(@"should return error if trying to remove an archive that does not exist", ^{
    result = [archiver removeArchiveType:$(LTTextureArchiveTypeUncompressedMat)
                                  inPath:@"archive" error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileNotFound);
  });

  it(@"should return error without removing if trying to remove an archive of the wrong type", ^{
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeJPEG) error:&error];
    expect(result).to.beTruthy();

    result = [archiver removeArchiveType:$(LTTextureArchiveTypeUncompressedMat)
                                  inPath:@"archive" error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileNotFound);
    expect(LTFileExistsInTemporaryPath(@"archive.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"archive.jpg")).to.beTruthy();
    expect([storage.dictionary allValues]).to.haveCountOf(1);
  });

  it(@"should return error if failed to remove the archive metadata", ^{
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();

    OCMStub([fileManager removeItemAtPath:[OCMArg checkWithBlock:^BOOL(NSString *path) {
      return [path hasSuffix:@"archive.plist"];
    }] error:[OCMArg setTo:kFakeError]]).andReturn(NO);

    result = [archiver removeArchiveType:$(LTTextureArchiveTypeUncompressedMat)
                                  inPath:@"archive" error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileRemovalFailed);
    expect(LTFileExistsInTemporaryPath(@"archive.plist")).to.beTruthy();
    expect(LTFileExistsInTemporaryPath(@"archive.mat")).to.beFalsy();
    expect([storage.dictionary allValues]).to.haveCountOf(0);
  });

  it(@"should return error if failed to remove the archive content", ^{
    result = [archiver archiveTexture:texture inPath:@"archive"
                      withArchiveType:$(LTTextureArchiveTypeUncompressedMat) error:&error];
    expect(result).to.beTruthy();

    OCMStub([fileManager removeItemAtPath:[OCMArg checkWithBlock:^BOOL(NSString *path) {
      return [path hasSuffix:@"archive.mat"];
    }] error:[OCMArg setTo:kFakeError]]).andReturn(NO);

    result = [archiver removeArchiveType:$(LTTextureArchiveTypeUncompressedMat)
                                  inPath:@"archive" error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(LTErrorCodeFileRemovalFailed);
    expect(LTFileExistsInTemporaryPath(@"archive.plist")).to.beFalsy();
    expect(LTFileExistsInTemporaryPath(@"archive.mat")).to.beTruthy();
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
    [fileManager removeItemAtPath:LTTemporaryPath(@"a.1.mat") error:nil];
    [fileManager removeItemAtPath:LTTemporaryPath(@"a.2.mat") error:nil];
    [fileManager removeItemAtPath:LTTemporaryPath(@"b.2.mat") error:nil];
    [fileManager removeItemAtPath:LTTemporaryPath(@"b.3.mat") error:nil];
    [archiver performStorageMaintenance];
    expect([storage.dictionary allValues]).to.haveCountOf(2);
    expect([storage.dictionary allValues].firstObject).to.haveCountOf(1);
    expect([storage.dictionary allValues].lastObject).to.haveCountOf(1);
  });

  it(@"should remove keys containing only zombie records", ^{
    [archiver performStorageMaintenance];
    [fileManager removeItemAtPath:LTTemporaryPath(@"b.1.mat") error:nil];
    [fileManager removeItemAtPath:LTTemporaryPath(@"b.2.mat") error:nil];
    [fileManager removeItemAtPath:LTTemporaryPath(@"b.3.mat") error:nil];
    [archiver performStorageMaintenance];
    expect([storage.dictionary allValues]).to.haveCountOf(1);
    expect([storage.dictionary allValues].firstObject).to.haveCountOf(3);
  });
});

SpecEnd
