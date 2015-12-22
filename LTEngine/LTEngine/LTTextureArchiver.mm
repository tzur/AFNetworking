// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureArchiver.h"

#import <LTKit/NSError+LTKit.h>
#import <LTKit/NSFileManager+LTKit.h>
#import <LTKit/NSObject+AddToContainer.h>

#import "LTTexture+Protected.h"
#import "LTTextureArchiveType.h"
#import "LTTextureBaseArchiver.h"
#import "LTTextureMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTTextureArchiver ()

/// Key-Value storage used to store paths of duplicated textures.
@property (strong, nonatomic) id<LTTextureArchiverStorage> storage;

/// Used for file operations by the texture archiver.
@property (strong, nonatomic) NSFileManager *fileManager;

/// Base directory of the archiver. All paths given as arguments to the archiver are treated as
/// relative to it.
@property (strong, nonatomic) NSString *baseDirectory;

@end

@implementation LTTextureArchiver

objection_requires_sel(@selector(fileManager));

- (instancetype)init {
  return nil;
}

- (instancetype)initWithStorage:(id<LTTextureArchiverStorage>)storage {
  return [self initWithStorage:storage baseDirectory:[NSFileManager lt_documentsDirectory]];
}

- (instancetype)initWithStorage:(id<LTTextureArchiverStorage>)storage
                  baseDirectory:(NSString *)baseDirectory {
  LTParameterAssert(storage);
  if (self = [super init]) {
    [self injectDependencies];
    self.storage = storage;
    self.baseDirectory = baseDirectory;
  }
  return self;
}

- (void)injectDependencies {
  [[JSObjection defaultInjector] injectDependencies:self];
}

#pragma mark -
#pragma mark Archiving
#pragma mark -

- (BOOL)archiveTexture:(LTTexture *)texture inPath:(NSString *)path
       withArchiveType:(LTTextureArchiveType *)type error:(NSError *__autoreleasing *)error {
  LTParameterAssert(texture);
  LTParameterAssert(type);
  LTParameterAssert(!texture.maxMipmapLevel);

  NSString *metadataPath = [self metadataPathForRelativePath:path];
  LTTextureMetadata *metadata = texture.metadata;
  if (![self saveMetadata:metadata inPath:metadataPath error:error]) {
    return NO;
  }

  // In case the texture is a solid color texture, no need to actually store it.
  if (!metadata.fillColor.isNull()) {
    return YES;
  }

  if (![self storeContentOfTexture:texture inPath:path withArchiveType:type error:error]) {
    if (![self.fileManager removeItemAtPath:metadataPath error:nil]) {
      LogWarning(@"Could not remove failed archive metadata: %@", metadataPath);
    }
    return NO;
  }

  return YES;
}

- (BOOL)storeContentOfTexture:(LTTexture *)texture inPath:(NSString *)path
              withArchiveType:(LTTextureArchiveType *)type error:(NSError *__autoreleasing *)error {
  NSString *storageKey = [self storageKeyForTextureMetadata:texture.metadata archiveType:type];
  NSString *contentPath = [self contentPathForType:type relativePath:path];

  if ([self.fileManager fileExistsAtPath:contentPath]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileAlreadyExists path:contentPath];
    }
    return NO;
  }

  if ([self linkContentPath:contentPath toExistingArchiveWithStorageKey:storageKey]) {
    return YES;
  }

  if (![type.archiver archiveTexture:texture inPath:contentPath error:error]) {
    [self.storage removeObjectForKey:storageKey];
    return NO;
  }

  self.storage[storageKey] = @[contentPath];
  return YES;
}

- (BOOL)linkContentPath:(NSString *)contentPath toExistingArchiveWithStorageKey:(NSString *)key {
  NSArray *existingArchives = [self existingArchivesForStorageKey:key];
  for (NSString *existingArchivePath in existingArchives) {
    NSError *linkError;
    if ([self.fileManager linkItemAtPath:existingArchivePath toPath:contentPath error:&linkError]) {
      self.storage[key] = [existingArchives arrayByAddingObject:contentPath];
      return YES;
    }

    LogWarning(@"Could not hard link %@ to %@: %@.\n This can happen in case an archived texture "
               "was deleted not using the LTTextureArchiver.",
               contentPath, existingArchivePath, linkError);
  }

  return NO;
}

- (NSString *)storageKeyForTextureMetadata:(LTTextureMetadata *)metadata
                               archiveType:(LTTextureArchiveType *)type {
  return [metadata.generationID stringByAppendingPathExtension:type.fileExtension];
}

- (NSArray *)existingArchivesForStorageKey:(NSString *)key {
  id existingArchives = self.storage[key] ?: @[];
  LTAssert([existingArchives isKindOfClass:[NSArray class]]);
  for (id archive in existingArchives) {
    LTAssert([archive isKindOfClass:[NSString class]]);
  }

  return existingArchives;
}

#pragma mark -
#pragma mark Unarchiving
#pragma mark -

- (LTTexture *)unarchiveFromPath:(NSString *)path withArchiveType:(LTTextureArchiveType *)type
                           error:(NSError *__autoreleasing *)error {
  LTParameterAssert(type);

  NSString *metadataPath = [self metadataPathForRelativePath:path];
  LTTextureMetadata *metadata = [self loadMetadataInPath:metadataPath error:error];
  if (!metadata) {
    return nil;
  }

  LTTexture *texture = [LTTexture textureWithMetadata:metadata];
  return [self unarchiveToTexture:texture fromPath:path withArchiveType:type
                         metadata:metadata error:error] ? texture : nil;
}

- (BOOL)unarchiveToTexture:(LTTexture *)texture fromPath:(NSString *)path
           withArchiveType:(LTTextureArchiveType *)type error:(NSError *__autoreleasing *)error {
  LTParameterAssert(texture);
  LTParameterAssert(type);
  LTParameterAssert(!texture.maxMipmapLevel);

  NSString *metadataPath = [self metadataPathForRelativePath:path];
  LTTextureMetadata *metadata = [self loadMetadataInPath:metadataPath error:error];
  if (!metadata) {
    return NO;
  }

  return [self unarchiveToTexture:texture fromPath:path withArchiveType:type
                         metadata:metadata error:error];
}

- (BOOL)unarchiveToTexture:(LTTexture *)texture fromPath:(NSString *)path
           withArchiveType:(LTTextureArchiveType *)type metadata:(LTTextureMetadata *)metadata
                     error:(NSError *__autoreleasing *)error {
  LTParameterAssert(texture.size == metadata.size);
  LTParameterAssert([texture.pixelFormat isEqual:metadata.pixelFormat]);

  __block BOOL success;
  texture.generationID = metadata.generationID;
  [texture performWithoutUpdatingGenerationID:^{
    if (!metadata.fillColor.isNull()) {
      [texture clearWithColor:metadata.fillColor];
      success = YES;
    } else {
      NSString *contentPath = [self contentPathForType:type relativePath:path];
      success = [type.archiver unarchiveToTexture:texture fromPath:contentPath error:error];
    }
  }];

  return success;
}

#pragma mark -
#pragma mark Deleting
#pragma mark -

- (BOOL)removeArchiveType:(LTTextureArchiveType *)type inPath:(NSString *)path
                    error:(NSError *__autoreleasing *)error {
  LTParameterAssert(type);
  LTParameterAssert(path);

  NSString *contentPath = [self contentPathForType:type relativePath:path];
  NSString *metadataPath = [self metadataPathForRelativePath:path];
  LTTextureMetadata *metadata = [self loadMetadataInPath:metadataPath error:error];
  if (!metadata ||
      (metadata.fillColor.isNull() && ![self verifyFileInPath:contentPath error:error])) {
    return NO;
  }

  BOOL succeededRemovingAllFiles = YES;
  NSError *removeError;
  NSMutableArray *errors = [NSMutableArray array];

  if (![self.fileManager removeItemAtPath:metadataPath error:&removeError]) {
    [removeError addToArray:errors];
    succeededRemovingAllFiles = NO;
  }

  if (metadata.fillColor.isNull() &&
      ![type.archiver removeArchiveInPath:contentPath error:&removeError]) {
    [removeError addToArray:errors];
    succeededRemovingAllFiles = NO;
  }

  if (errors.count && error) {
    *error = [NSError lt_errorWithCode:LTErrorCodeFileRemovalFailed underlyingErrors:errors];
  }

  NSString *storageKey = [self storageKeyForTextureMetadata:metadata archiveType:type];
  [self removeExistingArchiveInPath:contentPath forStorageKey:storageKey];
  return succeededRemovingAllFiles;
}

- (BOOL)verifyFileInPath:(NSString *)path error:(NSError *__autoreleasing *)error {
  if (![self.fileManager fileExistsAtPath:path]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound path:path];
    }
    return NO;
  }
  return YES;
}

- (void)removeExistingArchiveInPath:(NSString *)path forStorageKey:(NSString *)key {
  NSMutableArray *existingArchives = [[self existingArchivesForStorageKey:key] mutableCopy];
  [existingArchives removeObject:path];
  if (existingArchives.count) {
    self.storage[key] = [existingArchives copy];
  } else {
    [self.storage removeObjectForKey:key];
  }
}

#pragma mark -
#pragma mark Maintenance
#pragma mark -

- (void)performStorageMaintenance {
  for (NSString *key in [self.storage allKeys]) {
    NSArray *existingArchives = [self existingArchivesForStorageKey:key];
    NSMutableArray *validExistingArchives = [NSMutableArray array];
    for (NSString *existingArchive in existingArchives) {
      if ([self.fileManager fileExistsAtPath:existingArchive]) {
        [validExistingArchives addObject:existingArchive];
      }
    }

    if (validExistingArchives.count) {
      self.storage[key] = [validExistingArchives copy];
    } else {
      [self.storage removeObjectForKey:key];
    }
  }
}

#pragma mark -
#pragma mark Metadata
#pragma mark -

- (BOOL)saveMetadata:(LTTextureMetadata *)metadata inPath:(NSString *)path
               error:(NSError *__autoreleasing *)error {
  LTParameterAssert(metadata);
  LTParameterAssert(path);

  if ([self.fileManager fileExistsAtPath:path]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileAlreadyExists path:path];
    }
    return NO;
  }

  NSDictionary *json = [MTLJSONAdapter JSONDictionaryFromModel:metadata];
  if (!json || ![self.fileManager lt_writeDictionary:json toFile:path]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed];
    }
    return NO;
  }

  return YES;
}

- (LTTextureMetadata *)loadMetadataInPath:(NSString *)path error:(NSError *__autoreleasing *)error {
  LTParameterAssert(path);

  if (![self.fileManager fileExistsAtPath:path]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound path:path];
    }
    return nil;
  }

  NSDictionary *jsonDictionary = [self.fileManager lt_dictionaryWithContentsOfFile:path];
  if (!jsonDictionary) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:path];
    }
    return nil;
  }

  NSError *mantleError;
  LTTextureMetadata *metadata = [MTLJSONAdapter modelOfClass:[LTTextureMetadata class]
                                          fromJSONDictionary:jsonDictionary error:&mantleError];
  if (!metadata && error) {
    *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed underlyingError:mantleError];
  }
  return metadata;
}

#pragma mark -
#pragma mark Paths
#pragma mark -

static NSString * const kMetadataExtension = @"plist";

- (NSString *)metadataPathForRelativePath:(NSString *)path {
  return [[self fullPathFromRelativePath:path] stringByAppendingPathExtension:kMetadataExtension];
}

- (NSString *)contentPathForType:(LTTextureArchiveType *)type relativePath:(NSString *)path {
  LTParameterAssert(type);
  return [[self fullPathFromRelativePath:path] stringByAppendingPathExtension:type.fileExtension];
}

- (NSString *)fullPathFromRelativePath:(NSString *)path {
  LTParameterAssert(path);
  return [self.baseDirectory stringByAppendingPathComponent:path];
}

@end

NS_ASSUME_NONNULL_END
