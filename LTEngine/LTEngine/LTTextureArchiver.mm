// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureArchiver.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSError+LTKit.h>
#import <LTKit/NSFileManager+LTKit.h>
#import <LTKit/NSObject+AddToContainer.h>

#import "LTGLPixelFormat.h"
#import "LTOpenCVHalfFloat.h"
#import "LTTexture+Protected.h"
#import "LTTextureArchiveMetadata.h"
#import "LTTextureArchiveType.h"
#import "LTTextureBaseArchiver.h"
#import "LTTextureMetadata.h"
#import "LTTextureRepository.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTTextureArchiver ()

/// Key-Value storage used to store paths of duplicated textures.
@property (strong, nonatomic) id<LTTextureArchiverStorage> storage;

/// Used for file operations by the texture archiver.
@property (strong, nonatomic) NSFileManager *fileManager;

/// Texture repository that can act as a cache for unarchiving textures.
@property (strong, nonatomic) LTTextureRepository *textureRepository;

@end

@implementation LTTextureArchiver

objection_initializer(initWithStorage:textureRepository:);
objection_requires_sel(@selector(fileManager));

- (instancetype)init {
  return nil;
}

- (instancetype)initWithStorage:(id<LTTextureArchiverStorage>)storage
              textureRepository:(LTTextureRepository *)textureRepository {
  LTParameterAssert(storage);
  if (self = [super init]) {
    [self injectDependencies];
    self.storage = storage;
    _textureRepository = textureRepository;
  }
  return self;
}

- (void)injectDependencies {
  [[JSObjection defaultInjector] injectDependencies:self];
}

#pragma mark -
#pragma mark Archiving
#pragma mark -

- (BOOL)archiveTexture:(LTTexture *)texture inPath:(LTPath *)path
       withArchiveType:(LTTextureArchiveType *)type error:(NSError *__autoreleasing *)error {
  LTParameterAssert(texture);
  LTParameterAssert(type);
  LTParameterAssert(!texture.maxMipmapLevel);

  if (![self createArchiveFolderAtPath:path error:error]) {
    return NO;
  }

  LTTextureMetadata *textureMetadata = texture.metadata;
  LTTextureArchiveMetadata *archiveMetadata = [[LTTextureArchiveMetadata alloc]
                                               initWithArchiveType:type
                                               textureMetadata:textureMetadata];
  if (![self saveMetadata:archiveMetadata inPath:path error:error]) {
    [self removeFailedArchiveFolderAtPath:path];
    return NO;
  }

  // In case the texture is a solid color texture, no need to actually store it.
  if (!textureMetadata.fillColor.isNull()) {
    return YES;
  }

  if (![self storeContentOfTexture:texture inPath:path withArchiveType:type error:error]) {
    [self removeFailedArchiveFolderAtPath:path];
    return NO;
  }

  [self.textureRepository addTexture:texture];
  return YES;
}

- (BOOL)createArchiveFolderAtPath:(LTPath *)path error:(NSError *__autoreleasing *)error {
  if ([self.fileManager fileExistsAtPath:path.path]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileAlreadyExists path:path.path];
    }
    return NO;
  }

  NSError *createError;
  if (![self.fileManager createDirectoryAtPath:path.path withIntermediateDirectories:NO
                                    attributes:nil error:&createError]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed path:path.path
                         underlyingError:createError];
    }
    return NO;
  }

  return YES;
}

- (void)removeFailedArchiveFolderAtPath:(LTPath *)path {
  NSError *error;
  if (![self.fileManager removeItemAtPath:path.path error:&error]) {
    LogWarning(@"Could not remove failed archive folder '%@': %@", path.path, error ?: @"");
  }
}

- (BOOL)storeContentOfTexture:(LTTexture *)texture inPath:(LTPath *)path
              withArchiveType:(LTTextureArchiveType *)type error:(NSError *__autoreleasing *)error {
  LTAssert([self.fileManager lt_directoryExistsAtPath:path.path],
           @"Archive folder must exist prior to trying to store its content: %@", path.path);

  NSString *storageKey = [self storageKeyForTextureMetadata:texture.metadata archiveType:type];
  if ([self linkContentInPath:path toExistingArchiveWithStorageKey:storageKey]) {
    [self addExistingArchiveInPath:path forStorageKey:storageKey];
    return YES;
  }

  if (![self archiveContentOfTexture:texture inPath:path withArchiveType:type error:error]) {
    return NO;
  }

  [self setExistingArchives:@[path] forStorageKey:storageKey];
  return YES;
}

- (NSString *)storageKeyForTextureMetadata:(LTTextureMetadata *)metadata
                               archiveType:(LTTextureArchiveType *)type {
  return [metadata.generationID stringByAppendingPathExtension:type.fileExtension];
}

- (BOOL)linkContentInPath:(LTPath *)path toExistingArchiveWithStorageKey:(NSString *)key {
  // While trying to link the content to an existing archive, invalid archives are removed from the
  // storage as an optimization, to avoid trying to link over and over records that do not exist.
  NSArray<LTPath *> *existingArchives = [self existingArchivesForStorageKey:key];
  NSMutableArray<LTPath *> *invalidArchives = [NSMutableArray array];
  for (LTPath *existingArchive in existingArchives) {
    if ([self linkContentInPath:path toExistingArchiveAtPath:existingArchive]) {
      break;
    } else {
      [invalidArchives addObject:existingArchive];
    }
  }

  if (invalidArchives.count) {
    [self removeExistingArchives:invalidArchives forStorageKey:key];
  }

  return invalidArchives.count != existingArchives.count;
}

- (BOOL)linkContentInPath:(LTPath *)path toExistingArchiveAtPath:(LTPath *)existingPath {
  NSError *listError;
  NSArray<NSString *> *existingArchiveFiles =
      [self filenamesOfArchiveAtPath:existingPath includeMetadata:NO error:&listError];

  if (!existingArchiveFiles.count) {
    LogWarning(@"Invalid contents of %@: %@.\n This can happen in case an archived texture "
               "was deleted not using the LTTextureArchiver.", existingPath, listError ?: @"");
    return NO;
  }

  NSMutableArray<NSString *> *linkedPaths = [NSMutableArray array];
  for (NSString *existingFile in existingArchiveFiles) {
    NSString *filename = existingFile.lastPathComponent;
    NSString *source = [existingPath.path stringByAppendingPathComponent:filename];
    NSString *target = [path.path stringByAppendingPathComponent:filename];

    NSError *linkError;
    if (![self.fileManager linkItemAtPath:source toPath:target error:&linkError]) {
      LogWarning(@"Could not hard link %@ to %@: %@.\n This can happen in case an archived texture "
                 "was deleted not using the LTTextureArchiver.",
                 target, existingFile, linkError ?: @"");
      break;
    }

    [linkedPaths addObject:target];
  }

  if (linkedPaths.count != existingArchiveFiles.count) {
    NSError *removeError;
    for (NSString *linkedPath in linkedPaths) {
      if (![self.fileManager removeItemAtPath:linkedPath error:&removeError]) {
        LogWarning(@"Could not cleanup %@ after failure to hard link existing content: %@",
                   linkedPath, removeError ?: @"");
      }
    }
    return NO;
  }

  return YES;
}

- (nullable NSArray<NSString *> *)filenamesOfArchiveAtPath:(LTPath *)path
                                           includeMetadata:(BOOL)includeMetadata
                                                     error:(NSError *__autoreleasing *)error {
  NSArray<NSString *> *filenames =
      [self.fileManager contentsOfDirectoryAtPath:path.path error:error];
  if (!filenames) {
    return nil;
  }

  NSMutableArray<NSString *> *paths = [NSMutableArray array];
  for (NSString *filename in filenames) {
    if (includeMetadata || ![filename isEqualToString:kMetadataFilename]) {
      [paths addObject:[path.path stringByAppendingPathComponent:filename]];
    }
  }
  return paths;
}

- (BOOL)archiveContentOfTexture:(LTTexture *)texture inPath:(LTPath *)path
                withArchiveType:(LTTextureArchiveType *)type
                          error:(NSError *__autoreleasing *)error {
  NSString *contentPath =
      [self contentPathForArchiveFolderPath:path fileExtension:type.fileExtension];

  NSError *archiverError;
  if (![type.archiver archiveTexture:texture inPath:contentPath error:&archiverError]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed path:contentPath
                         underlyingError:archiverError];
    }
    return NO;
  }

  return YES;
}

#pragma mark -
#pragma mark Unarchiving To Texture
#pragma mark -

- (nullable LTTexture *)unarchiveTextureFromPath:(LTPath *)path
                                           error:(NSError *__autoreleasing *)error {
  LTTextureArchiveMetadata *archiveMetadata = [self metadataFromPath:path error:error];
  if (!archiveMetadata) {
    return nil;
  }

  LTTexture *texture = [LTTexture textureWithMetadata:archiveMetadata.textureMetadata];
  return [self unarchiveToTexture:texture fromPath:path withArchiveType:archiveMetadata.archiveType
                         metadata:archiveMetadata.textureMetadata error:error] ? texture : nil;
}

- (BOOL)unarchiveToTexture:(LTTexture *)texture fromPath:(LTPath *)path
                     error:(NSError *__autoreleasing *)error {
  LTParameterAssert(texture);
  LTParameterAssert(!texture.maxMipmapLevel);

  LTTextureArchiveMetadata *archiveMetadata = [self metadataFromPath:path error:error];
  if (!archiveMetadata) {
    return NO;
  }

  NSString *archivedGenerationId = archiveMetadata.textureMetadata.generationID;
  if ([texture.generationID isEqualToString:archivedGenerationId]) {
    return YES;
  }

  return [self unarchiveToTexture:texture fromPath:path withArchiveType:archiveMetadata.archiveType
                         metadata:archiveMetadata.textureMetadata error:error];
}

- (BOOL)unarchiveToTexture:(LTTexture *)texture fromPath:(LTPath *)path
           withArchiveType:(LTTextureArchiveType *)type metadata:(LTTextureMetadata *)metadata
                     error:(NSError *__autoreleasing *)error {
  LTParameterAssert(texture.size == metadata.size);
  LTParameterAssert([texture.pixelFormat isEqual:metadata.pixelFormat]);

  [self.textureRepository addTexture:texture];
  NSString *generationID = metadata.generationID;
  LTTexture *cachedTexture = [self.textureRepository textureWithGenerationID:generationID];
  if (cachedTexture) {
    [cachedTexture cloneTo:texture];
    return YES;
  }

  __block BOOL success = YES;
  texture.generationID = metadata.generationID;
  [texture performWithoutUpdatingGenerationID:^{
    if (!metadata.fillColor.isNull()) {
      [texture clearColor:metadata.fillColor];
    } else {
      NSString *contentPath =
          [self contentPathForArchiveFolderPath:path fileExtension:type.fileExtension];
      success = [type.archiver unarchiveToTexture:texture fromPath:contentPath error:error];
    }
  }];

  return success;
}

#pragma mark -
#pragma mark Unarchiving To Image
#pragma mark -

- (nullable UIImage *)unarchiveImageFromPath:(LTPath *)path
                                       error:(NSError *__autoreleasing *)error {
  LTTextureArchiveMetadata *archiveMetadata = [self metadataFromPath:path error:error];
  if (!archiveMetadata) {
    return nil;
  }

  LTTextureMetadata *textureMetadata = archiveMetadata.textureMetadata;
  if (![self canCreateImageForTextureMetadata:textureMetadata path:path error:error]) {
    return nil;
  }

  NSMutableData *data = [self dataForMatWithMetadata:textureMetadata];
  cv::Mat4b mat = [self matWithData:data metadata:textureMetadata];

  if (!textureMetadata.fillColor.isNull()) {
    mat.setTo((cv::Vec4b)textureMetadata.fillColor);
  } else {
    LTTextureArchiveType *type = archiveMetadata.archiveType;
    NSString *contentPath =
        [self contentPathForArchiveFolderPath:path fileExtension:type.fileExtension];
    if (![type.archiver unarchiveToMat:&mat fromPath:contentPath error:error]) {
      return nil;
    }
  }

  return [self imageWithData:data metadata:archiveMetadata.textureMetadata];
}

- (BOOL)canCreateImageForTextureMetadata:(LTTextureMetadata *)metadata path:(LTPath *)path
                                   error:(NSError *__autoreleasing *)error {
  if ([metadata.pixelFormat isEqual:$(LTGLPixelFormatRGBA8Unorm)]) {
    return YES;
  }

  if (error) {
    *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                           description:@"Could not create UIImage from %@: invalid pixel format %@",
              path.path, metadata.pixelFormat.name];
  }
  return NO;
}

- (NSMutableData *)dataForMatWithMetadata:(LTTextureMetadata *)metadata {
  LTParameterAssert(metadata.pixelFormat.matType == CV_8UC4);
  NSUInteger length = metadata.size.height * metadata.size.width * cv::Mat4b().elemSize();
  return [NSMutableData dataWithLength:length];
}

- (cv::Mat4b)matWithData:(NSMutableData *)data metadata:(LTTextureMetadata *)metadata {
  LTParameterAssert(metadata.pixelFormat.matType == CV_8UC4);
  return cv::Mat(metadata.size.height, metadata.size.width,
                 metadata.pixelFormat.matType, data.mutableBytes);
}

- (UIImage *)imageWithData:(NSData *)data metadata:(LTTextureMetadata *)metadata {
  LTParameterAssert([metadata.pixelFormat isEqual:$(LTGLPixelFormatRGBA8Unorm)]);
  lt::Ref<CGDataProviderRef> provider(CGDataProviderCreateWithCFData((__bridge CFDataRef)data));

  size_t bitsPerComponent = 8;
  size_t bitsPerPixel = 4 * bitsPerComponent;
  size_t bytesPerRow = 4 * metadata.size.width;
  CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault;
  lt::Ref<CGColorSpaceRef> colorSpace(CGColorSpaceCreateDeviceRGB());
  lt::Ref<CGImageRef> imageRef(CGImageCreate(metadata.size.width, metadata.size.height,
                                             bitsPerComponent, bitsPerPixel, bytesPerRow,
                                             colorSpace.get(), bitmapInfo, provider.get(), NULL,
                                             YES, kCGRenderingIntentDefault));

  return [UIImage imageWithCGImage:imageRef.get()];
}

#pragma mark -
#pragma mark Deleting
#pragma mark -

- (BOOL)removeArchiveInPath:(LTPath *)path error:(NSError *__autoreleasing *)error {
  LTParameterAssert(path);

  LTTextureArchiveMetadata *archiveMetadata = [self metadataFromPath:path error:error];
  if (!archiveMetadata) {
    return NO;
  }

  LTTextureMetadata *textureMetadata = archiveMetadata.textureMetadata;

  if (textureMetadata.fillColor.isNull()) {
    LTTextureArchiveType *type = archiveMetadata.archiveType;
    NSString *storageKey = [self storageKeyForTextureMetadata:textureMetadata archiveType:type];
    [self removeExistingArchives:@[path] forStorageKey:storageKey];
  }

  NSError *removeError;
  if (![self.fileManager removeItemAtPath:path.path error:&removeError]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileRemovalFailed path:path.path
                         underlyingError:removeError];
    }
    return NO;
  }

  return YES;
}

#pragma mark -
#pragma mark Duplicating
#pragma mark -

- (BOOL)duplicateTextureFromPath:(LTPath *)fromPath toPath:(LTPath *)toPath
                           error:(NSError *__autoreleasing *)error {
  if (![self createArchiveFolderAtPath:toPath error:error]) {
    return NO;
  }

  LTTextureArchiveMetadata *archiveMetadata = [self metadataFromPath:fromPath error:error];
  if (!archiveMetadata) {
    return NO;
  }

  if (![self saveMetadata:archiveMetadata inPath:toPath error:error]) {
    [self removeFailedArchiveFolderAtPath:toPath];
    return NO;
  }

  // In case the texture is a solid color texture, no need to actually store it.
  if (!archiveMetadata.textureMetadata.fillColor.isNull()) {
    return YES;
  }

  NSString *storageKey = [self storageKeyForTextureMetadata:archiveMetadata.textureMetadata
                                                archiveType:archiveMetadata.archiveType];
  if (![self linkContentInPath:toPath toExistingArchiveWithStorageKey:storageKey]) {
    [self removeFailedArchiveFolderAtPath:toPath];
    return NO;
  }
  [self addExistingArchiveInPath:toPath forStorageKey:storageKey];

  return YES;
}

#pragma mark -
#pragma mark Maintenance
#pragma mark -

- (void)performStorageMaintenance {
  for (NSString *key in [self.storage allKeys]) {
    NSArray<LTPath *> *existingArchives = [self existingArchivesForStorageKey:key];
    NSMutableArray<LTPath *> *invalidArchives = [NSMutableArray array];

    for (LTPath *existingArchive in existingArchives) {
      if (![self isValidArchiveInPath:existingArchive]) {
        LogWarning(@"Removing zombie record in texture cache: %@", existingArchive);
        [self.fileManager removeItemAtPath:existingArchive.path error:nil];
        [invalidArchives addObject:existingArchive];
      }
    }

    [self removeExistingArchives:invalidArchives forStorageKey:key];
  }
}

- (BOOL)isValidArchiveInPath:(LTPath *)path {
  NSArray<NSString *> *filenames =
      [self.fileManager contentsOfDirectoryAtPath:path.path error:nil];

  BOOL hasMetadata = [filenames containsObject:kMetadataFilename];
  BOOL hasContent = [self filenamesContainContentFilename:filenames];

  return hasMetadata && hasContent;
}

- (BOOL)filenamesContainContentFilename:(nullable NSArray<NSString *> *)filenames {
  return [filenames indexOfObjectPassingTest:^BOOL(NSString *file, NSUInteger, BOOL *) {
    return [[file stringByDeletingPathExtension] isEqualToString:kContentFilename];
  }] != NSNotFound;
}

#pragma mark -
#pragma mark Storage
#pragma mark -

- (void)addExistingArchiveInPath:(LTPath *)path forStorageKey:(NSString *)key {
  NSMutableArray<LTPath *> *mutableArchives =
      [[self existingArchivesForStorageKey:key] mutableCopy];

  [mutableArchives addObject:path];
  [self setExistingArchives:mutableArchives forStorageKey:key];
}

- (void)removeExistingArchives:(NSArray<LTPath *> *)archives forStorageKey:(NSString *)key {
  NSMutableArray<LTPath *> *mutableArchives =
      [[self existingArchivesForStorageKey:key] mutableCopy];

  [mutableArchives removeObjectsInArray:archives];
  [self setExistingArchives:mutableArchives forStorageKey:key];
}

- (NSArray<LTPath *> *)existingArchivesForStorageKey:(NSString *)key {
  NSMutableArray<LTPath *> *existingArchives = [NSMutableArray array];
  for (NSString *encodedExistingArchivePath in self.storage[key]) {
    LTPath *path = [LTPath pathWithRelativeURL:[NSURL URLWithString:encodedExistingArchivePath]];
    [path addToArray:existingArchives];
  }

  return [existingArchives copy];
}

- (void)setExistingArchives:(NSArray<LTPath *> *)existingArchives forStorageKey:(NSString *)key {
  NSMutableArray<NSString *> *encodedPaths = [NSMutableArray array];
  for (LTPath *path in existingArchives) {
    [path.relativeURL.absoluteString addToArray:encodedPaths];
  }

  if (encodedPaths.count) {
    self.storage[key] = [encodedPaths copy];
  } else {
    [self.storage removeObjectForKey:key];
  }
}

#pragma mark -
#pragma mark Metadata
#pragma mark -

- (BOOL)saveMetadata:(LTTextureArchiveMetadata *)metadata inPath:(LTPath *)path
               error:(NSError *__autoreleasing *)error {
  LTParameterAssert(metadata);
  LTParameterAssert(path);
  LTAssert([self.fileManager lt_directoryExistsAtPath:path.path]);

  NSString *metadataPath = [self metadataPathForArchiveFolderPath:path];
  if ([self.fileManager fileExistsAtPath:metadataPath]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileAlreadyExists path:metadataPath];
    }
    return NO;
  }

  NSDictionary *json = [MTLJSONAdapter JSONDictionaryFromModel:metadata];
  if (!json) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed
                             description:@"Failed to serialize texture metadata"];
    }
    return NO;
  }

  if (![self.fileManager lt_writeDictionary:json toFile:metadataPath error:error]) {
    return NO;
  }

  return YES;
}

- (nullable LTTextureArchiveMetadata *)metadataFromPath:(LTPath *)path
                                                  error:(NSError *__autoreleasing *)error {
  LTParameterAssert(path);

  NSString *metadataPath = [self metadataPathForArchiveFolderPath:path];
  if (![self.fileManager fileExistsAtPath:metadataPath]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound path:metadataPath];
    }
    return nil;
  }

  NSDictionary *dictionary =
      [self.fileManager lt_dictionaryWithContentsOfFile:metadataPath error:error];
  if (!dictionary) {
    return nil;
  }

  NSError *mantleError;
  LTTextureArchiveMetadata *metadata = [MTLJSONAdapter modelOfClass:[LTTextureArchiveMetadata class]
                                                 fromJSONDictionary:dictionary error:&mantleError];
  if (!metadata) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:metadataPath
                         underlyingError:mantleError];
    }
    return nil;
  }

  NSError *metadataError = [self verifyArchiveMetadata:metadata];
  if (metadataError) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:metadataPath
                         underlyingError:metadataError];
    }
    return nil;
  }

  return metadata;
}

- (nullable NSError *)verifyArchiveMetadata:(LTTextureArchiveMetadata *)metadata {
  if (!metadata.archiveType) {
    return [NSError lt_errorWithCode:LTErrorCodeFileReadFailed description:@"Missing archive type"];
  }

  if (!metadata.textureMetadata) {
    return [NSError lt_errorWithCode:LTErrorCodeFileReadFailed
                         description:@"Missing texture metadata"];
  }

  return nil;
}

#pragma mark -
#pragma mark Paths
#pragma mark -

/// Name of the metadata file of an archive.
static NSString * const kMetadataFilename = @"metadata.plist";

- (NSString *)metadataPathForArchiveFolderPath:(LTPath *)path {
  return [path.path stringByAppendingPathComponent:kMetadataFilename];
}

/// Name of the content file of an archive, without an extension that will be defined according to
/// the type of archiver that is used to generate the content.
static NSString * const kContentFilename = @"content";

- (NSString *)contentPathForArchiveFolderPath:(LTPath *)path fileExtension:(NSString *)extension {
  NSString *filename = [kContentFilename stringByAppendingPathExtension:extension];
  return [path.path stringByAppendingPathComponent:filename];
}

@end

NS_ASSUME_NONNULL_END
