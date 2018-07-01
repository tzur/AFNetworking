// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WHSProjectStorage.h"

#import <LTKit/NSFileManager+LTKit.h>

#import "NSError+WHSProjectStorage.h"
#import "WHSProjectUpdateRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (WHSProjectStorage)

/// Returns \c YES if a file or directory exists at the given \c path. Else returns \c NO and
/// \c error is populated with \c LTErrorCodeFileNotFound.
- (BOOL)fileExistsAtPath:(NSString *)path error:(NSError **)error;

@end

@implementation NSFileManager (WHSProjectStorage)

- (BOOL)fileExistsAtPath:(NSString *)path error:(NSError *__autoreleasing *)error {
  if ([self fileExistsAtPath:path]) {
    return YES;
  }
  if (error) {
    *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound path:path];
  }
  return NO;
}

@end

@interface NSURL (WHSProjectStorage)

/// URL of the assets directory inside the project or step directory that this URL points to.
@property (readonly, nonatomic) NSURL *whs_assetsURL;

/// URL of the data directory inside the project or step directory that this URL points to.
@property (readonly, nonatomic) NSURL *whs_dataURL;

/// URL of the metadata file inside the project directory that this URL points to.
@property (readonly, nonatomic) NSURL *whs_metadataURL;

/// URL of the steps IDs file inside the project directory that this URL points to.
@property (readonly, nonatomic) NSURL *whs_stepsIDsURL;

/// URL of the user data file inside the project or step directory that this URL points to.
@property (readonly, nonatomic) NSURL *whs_userDataURL;

@end

@implementation NSURL (WHSProjectStorage)

- (NSURL *)whs_assetsURL {
  return nn([self URLByAppendingPathComponent:@"assets" isDirectory:YES]);
}

- (NSURL *)whs_dataURL {
  return nn([self URLByAppendingPathComponent:@"data" isDirectory:YES]);
}

- (NSURL *)whs_metadataURL {
  return nn([self.whs_dataURL URLByAppendingPathComponent:@"matadata" isDirectory:NO]);
}

- (NSURL *)whs_stepsIDsURL {
    return nn([self.whs_dataURL URLByAppendingPathComponent:@"stepsIDs" isDirectory:NO]);
}

- (NSURL *)whs_userDataURL {
    return nn([self.whs_dataURL URLByAppendingPathComponent:@"userData" isDirectory:NO]);
}

@end

LTEnumImplement(NSUInteger, WHSProjectSortProperty,
  WHSProjectModificationDate,
  WHSProjectCreationDate
);

@implementation WHSProjectSortProperty (Properties)

- (NSURLResourceKey)URLResourceKey {
  switch (self.value) {
    case WHSProjectModificationDate:
      return NSURLContentModificationDateKey;
    case WHSProjectCreationDate:
      return NSURLCreationDateKey;
  }
}

@end

@interface WHSProjectStorage ()

/// Used for file system operations.
@property (readonly, nonatomic) NSFileManager *fileManager;

/// weak pointers to the storage observers. Observers are the keys of the \c NSMapTable in order to
/// keep the pointers weak and automatically remove them when deallocated. The values of the map are
/// not used.
@property (readonly, nonatomic) NSMapTable<id<WHSProjectStorageObserver>, NSNull *> *observers;

@end

@implementation WHSProjectStorage

/// Number of bytes required in order to represent an \c NSUUID object in a binary format.
static const NSUInteger kWHSBytesInUUID = sizeof(uuid_t);

/// Key for the step cursor in a project metadata dictionary.
static NSString * const kWHSStepCursorKey = @"stepCursor";

/// Key for the bundle ID in a project metadata dictionary.
static NSString * const kWHSBundleIDKey = @"bundleID";

- (instancetype)init {
  auto bundleID = [NSBundle mainBundle].bundleIdentifier;
  auto libraryURL = [NSURL fileURLWithPath:[NSFileManager lt_libraryDirectory]];
  auto baseURL = nn([libraryURL URLByAppendingPathComponent:@"Warehouse" isDirectory:YES]);
  return [self initWithBundleID:bundleID baseURL:baseURL];
}

- (instancetype)initWithBundleID:(NSString *)bundleID baseURL:(NSURL *)baseURL {
  if (self = [super init]) {
    _observers = [NSMapTable weakToStrongObjectsMapTable];
    _bundleID = bundleID;
    _baseURL = baseURL;
    _fileManager = [NSFileManager defaultManager];
    [self.fileManager createDirectoryAtURL:self.baseURL withIntermediateDirectories:YES
                                attributes:nil error:nil];
  }
  return self;
}

- (nullable NSUUID *)createProjectWithError:(NSError *__autoreleasing *)error {
  auto projectID = [NSUUID UUID];
  auto projectCreated = [self createStorageForProject:projectID error:error];
  if (!projectCreated) {
    if (error) {
      *error = [NSError whs_errorCreatingProjectWithID:projectID underlyingError:*error];
    }
    return nil;
  }
  [self notifyProjectCreated:projectID];
  return projectID;
}

- (BOOL)createStorageForProject:(NSUUID *)projectID error:(NSError *__autoreleasing *)error {
  auto projectURL = [self URLOfProject:projectID];
  auto dataDirectoryCreated = [self.fileManager createDirectoryAtURL:projectURL.whs_dataURL
                                         withIntermediateDirectories:YES attributes:nil
                                                               error:error];
  if (!dataDirectoryCreated) {
    return NO;
  }
  auto metadata = @{kWHSStepCursorKey: @0, kWHSBundleIDKey: self.bundleID};
  auto stepsIDs = @[];
  auto userData = @{};
  auto dataUpdated = [self writeDataOfProject:projectID withMetadata:metadata stepsIDs:stepsIDs
                                     userData:userData error:error];
  if (!dataUpdated) {
    [self.fileManager removeItemAtURL:projectURL error:nil];
    return NO;
  }
  auto assetsDirectoryCreated = [self.fileManager createDirectoryAtURL:projectURL.whs_assetsURL
                                           withIntermediateDirectories:YES attributes:nil
                                                                 error:error];
  if (!assetsDirectoryCreated) {
    [self.fileManager removeItemAtURL:projectURL error:nil];
    return NO;
  }
  return YES;
}

- (nullable NSArray<NSUUID *> *)projectsIDsSortedBy:(WHSProjectSortProperty *)sortProperty
                                         descending:(BOOL)descending
                                              error:(NSError *__autoreleasing *)error {
  auto _Nullable sortedURLs = [self projectsURLsSortedBy:sortProperty descending:descending
                                                   error:error];
  if (!sortedURLs) {
    if (error) {
      *error = [NSError whs_errorFetchingProjectsIDsSortedBy:sortProperty underlyingError:*error];
    }
    return nil;
  }
  return [sortedURLs lt_map:^NSUUID *(NSURL *projectURL) {
    return [[NSUUID alloc] initWithUUIDString:nn(projectURL.lastPathComponent)];
  }];
}

- (nullable NSArray<NSURL *> *)projectsURLsSortedBy:(WHSProjectSortProperty *)sortProperty
                                         descending:(BOOL)descending
                                              error:(NSError *__autoreleasing *)error {
  NSURLResourceKey sortingResourceKey = sortProperty.URLResourceKey;
  auto _Nullable URLs = [self.fileManager
                         contentsOfDirectoryAtURL:self.baseURL
                         includingPropertiesForKeys:@[sortingResourceKey]
                         options:NSDirectoryEnumerationSkipsHiddenFiles error:error];
  if (!URLs) {
    return nil;
  }

  return [URLs sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    NSDate *date1;
    NSDate *date2;
    if (![(NSURL*)obj1 getResourceValue:&date1 forKey:sortingResourceKey error:nil] ||
        ![(NSURL*)obj2 getResourceValue:&date2 forKey:sortingResourceKey error:nil]) {
      return NSOrderedSame;
    }
    if ([date1 timeIntervalSince1970] < [date2 timeIntervalSince1970]) {
      return descending ? NSOrderedDescending : NSOrderedAscending;
    } else {
      return descending ? NSOrderedAscending : NSOrderedDescending;
    }
  }];
}

- (nullable WHSProjectSnapshot *)fetchSnapshotOfProjectWithID:(NSUUID *)projectID
                                                      options:(WHSProjectFetchOptions)fetchOptions
                                                        error:(NSError *__autoreleasing *)error {
  auto projectURL = [self URLOfProject:projectID];
  auto _Nullable projectAttributes = [self.fileManager attributesOfItemAtPath:nn(projectURL.path)
                                                                        error:error];
  if (!projectAttributes) {
    [self assignErrorFetchingProject:projectID to:error];
    return nil;
  }
  auto modificationDate = projectAttributes.fileModificationDate;
  auto creationDate = projectAttributes.fileCreationDate;
  auto size = projectAttributes.fileSize;

  auto assetsURL = projectURL.whs_assetsURL;
  if (![self.fileManager fileExistsAtPath:nn(assetsURL.path) error:error]) {
    [self assignErrorFetchingProject:projectID to:error];
    return nil;
  }

  auto _Nullable metadata = [self metadataOfProject:projectID error:error];
  if (!metadata) {
    [self assignErrorFetchingProject:projectID to:error];
    return nil;
  }

  auto stepCursor = ((NSNumber *)metadata[kWHSStepCursorKey]).unsignedIntegerValue;
  NSString *bundleID = metadata[kWHSBundleIDKey];

  NSArray<NSUUID *> * _Nullable stepsIDs;
  if (fetchOptions & WHSProjectFetchOptionsFetchStepsIDs) {
    stepsIDs = [self stepsIDsOfProject:projectID error:error];
    if (!stepsIDs) {
      [self assignErrorFetchingProject:projectID to:error];
      return nil;
    }
  }

  NSDictionary<NSString *, id> * _Nullable userData;
  if (fetchOptions & WHSProjectFetchOptionsFetchUserData) {
    userData = [self userDataFromURL:projectURL error:error];
    if (!userData) {
      [self assignErrorFetchingProject:projectID to:error];
      return nil;
    }
  }

  return [[WHSProjectSnapshot alloc] initWithID:projectID bundleID:bundleID
                                   creationDate:creationDate modificationDate:modificationDate
                                           size:size stepsIDs:stepsIDs stepCursor:stepCursor
                                       userData:userData assetsURL:nn(assetsURL)];
}

- (void)assignErrorFetchingProject:(NSUUID *)projectID to:(NSError *__autoreleasing *)error {
  if (error) {
    *error = [NSError whs_errorFetchingProjectWithID:projectID underlyingError:*error];
  }
}

- (BOOL)deleteProjectWithID:(NSUUID *)projectID error:(NSError *__autoreleasing *)error {
  auto projectURL = [self URLOfProject:projectID];
  if (![self.fileManager fileExistsAtPath:nn(projectURL.path)]) {
    [self assignErrorDeletingProject:projectID to:error];
    return NO;
  }

  auto _Nullable tempURL = [self createTempURLWithError:error];
  if (!tempURL) {
    [self assignErrorDeletingProject:projectID to:error];
    return NO;
  }
  @onExit {
    [self.fileManager removeItemAtURL:nn(tempURL) error:nil];
  };
  // Uses \c NSFileManager method that atomically replaces directory content to delete the project
  // content (by replacing with an empty directory). This is done in order to avoid partially
  // deleted project in case of unexpected termination.
  auto contentMoved = [self.fileManager replaceItemAtURL:projectURL withItemAtURL:nn(tempURL)
                                          backupItemName:nil options:0 resultingItemURL:nil
                                                   error:error];
  if (!contentMoved) {
    [self assignErrorDeletingProject:projectID to:error];
    return NO;
  }
  [self.fileManager removeItemAtURL:projectURL error:nil];
  [self notifyProjectDeleted:projectID];
  return YES;
}

- (void)assignErrorDeletingProject:(NSUUID *)projectID to:(NSError *__autoreleasing *)error {
  if (error) {
    *error = [NSError whs_errorDeletingProjectWithID:projectID underlyingError:*error];
  }
}

- (BOOL)updateProjectWithRequest:(WHSProjectUpdateRequest *)request
                           error:(NSError *__autoreleasing *)error {
  auto projectID = request.projectID;
  NSDictionary<NSString *, id> * _Nullable metadata;
  NSArray<NSUUID *> * _Nullable stepsIDs;
  NSArray<NSUUID *> * _Nullable stepsIDsCreated = @[];

  if (request.stepCursor || request.stepIDsToDelete.count || request.stepsContentToAdd.count) {
    metadata = [self metadataOfProject:projectID error:error];
    if (!metadata) {
      [self assignErrorUpdatingProjectWithRequest:request to:error];
      return NO;
    }
    stepsIDs = [self stepsIDsOfProject:projectID error:error];
    if (!stepsIDs) {
      [self assignErrorUpdatingProjectWithRequest:request to:error];
      return NO;
    }
    auto requestValid = [self validateUpdateRequest:request metadata:nn(metadata)
                                           stepsIDs:nn(stepsIDs) error:error];
    if (!requestValid) {
      return NO;
    }
    stepsIDsCreated = [self createStepsFrom:request.stepsContentToAdd inProject:projectID
                                      error:error];
    if (!stepsIDsCreated) {
      [self assignErrorUpdatingProjectWithRequest:request to:error];
      return NO;
    }

    stepsIDs = [self addStepsIDs:nn(stepsIDsCreated) toStepsIDs:nn(stepsIDs) metadata:nn(metadata)];
    stepsIDs = [self removeStepsIDs:request.stepIDsToDelete fromStepsIDs:nn(stepsIDs)];
    if (request.stepCursor) {
      metadata = [self changeStepCursorTo:nn(request.stepCursor) inMetadata:nn(metadata)];
    }
  }

  auto dataWritten = [self writeDataOfProject:projectID withMetadata:metadata stepsIDs:stepsIDs
                                     userData:request.userData error:error];
  if (!dataWritten) {
    [self removeContentOfSteps:nn(stepsIDsCreated) fromProject:projectID];
    [self assignErrorUpdatingProjectWithRequest:request to:error];
    return NO;
  }

  [self removeContentOfSteps:request.stepIDsToDelete fromProject:projectID];

  for (WHSStepContent *stepContent in request.stepsContentToAdd) {
    if (!stepContent.assetsSourceURL) {
      continue;
    }
    [self.fileManager removeItemAtURL:nn(stepContent.assetsSourceURL) error:nil];
  }

  [self notifyProjectUpdated:projectID];
  return YES;
}

- (void)assignErrorUpdatingProjectWithRequest:(WHSProjectUpdateRequest *)request
                                           to:(NSError *__autoreleasing *)error {
  if (error) {
    *error = [NSError whs_errorUpdatingProjectWithRequest:request underlyingError:*error];
  }
}

- (BOOL)writeDataOfProject:(NSUUID *)projectID
              withMetadata:(nullable NSDictionary<NSString *, id> *)metadata
                  stepsIDs:(nullable NSArray<NSUUID *> *)stepsIDs
                  userData:(nullable NSDictionary<NSString *, id> *)userData
                     error:(NSError *__autoreleasing *)error {
  auto projectURL = [self URLOfProject:projectID];
  auto _Nullable tempURL = [self createTempURLWithError:error];
  if (!tempURL) {
    return NO;
  }
  @onExit {
    [self.fileManager removeItemAtURL:nn(tempURL) error:nil];
  };
  auto dataSource = tempURL.whs_dataURL;
  auto dataSourceCreated = [self.fileManager createDirectoryAtURL:dataSource
                                      withIntermediateDirectories:YES attributes:nil error:error];
  if (!dataSourceCreated) {
    return NO;
  }

  auto metadataWritten = [self writeMetadata:metadata fromProjectURL:projectURL to:nn(tempURL)
                                       error:error];
  if (!metadataWritten) {
    return NO;
  }
  auto stepsIDsWritten = [self writeStepsIDs:stepsIDs fromProjectURL:projectURL to:nn(tempURL)
                                       error:error];
  if (!stepsIDsWritten) {
    return NO;
  }
  auto userDataWritten = [self writeUserData:userData fromProjectURL:projectURL to:nn(tempURL)
                                       error:error];
  if (!userDataWritten) {
    return NO;
  }

  auto dataDestination = projectURL.whs_dataURL;
  auto dataWritten = [self.fileManager replaceItemAtURL:dataDestination withItemAtURL:dataSource
                                         backupItemName:nil options:0 resultingItemURL:nil
                                                  error:error];
  return dataWritten;
}

- (BOOL)writeMetadata:(nullable NSDictionary<NSString *, id> *)metadata
       fromProjectURL:(NSURL *)projectURL to:(NSURL *)URL error:(NSError *__autoreleasing *)error {
  if (!metadata) {
    return [self.fileManager copyItemAtURL:projectURL.whs_metadataURL toURL:URL.whs_metadataURL
                                     error:error];
  }
  return [self.fileManager lt_writeDictionary:nn(metadata) toFile:nn(URL.whs_metadataURL.path)
                                       format:NSPropertyListBinaryFormat_v1_0 error:error];
}

- (BOOL)writeStepsIDs:(nullable NSArray<NSUUID *> *)stepsIDs fromProjectURL:(NSURL *)projectURL
                   to:(NSURL *)URL error:(NSError *__autoreleasing *)error {
  if (!stepsIDs) {
    return [self.fileManager copyItemAtURL:projectURL.whs_stepsIDsURL toURL:URL.whs_stepsIDsURL
                                     error:error];
  }
  auto stepsData = [[NSMutableData alloc] initWithCapacity:stepsIDs.count * kWHSBytesInUUID];
  for (NSUInteger i = 0; i < stepsIDs.count; ++i) {
    uuid_t UUID;
    [stepsIDs[i] getUUIDBytes:UUID];
    [stepsData replaceBytesInRange:NSMakeRange(i * kWHSBytesInUUID, kWHSBytesInUUID)
                         withBytes:UUID];
  }
  return [stepsData writeToURL:URL.whs_stepsIDsURL options:0 error:error];
}

- (BOOL)writeUserData:(nullable NSDictionary<NSString *, id> *)userData
       fromProjectURL:(NSURL *)projectURL to:(NSURL *)URL error:(NSError *__autoreleasing *)error {
  if (!userData) {
    return [self.fileManager copyItemAtURL:projectURL.whs_userDataURL toURL:URL.whs_userDataURL
                                     error:error];
  }
  return [self.fileManager lt_writeDictionary:nn(userData) toFile:nn(URL.whs_userDataURL.path)
                                       format:NSPropertyListBinaryFormat_v1_0 error:error];
}

- (nullable NSDictionary<NSString *, id> *)metadataOfProject:(NSUUID *)projectID
                                                       error:(NSError *__autoreleasing *)error {
  auto metadataPath = nn([self URLOfProject:projectID].whs_metadataURL.path);
  return [self.fileManager lt_dictionaryWithContentsOfFile:metadataPath error:error];
}

- (nullable NSArray<NSUUID *> *)stepsIDsOfProject:(NSUUID *)projectID
                                            error:(NSError *__autoreleasing *)error {
  auto stepsIDsURL = [self URLOfProject:projectID].whs_stepsIDsURL;
  auto _Nullable stepsData = [NSData dataWithContentsOfURL:stepsIDsURL options:0 error:error];
  if (!stepsData) {
    return nil;
  }
  auto numberOfSteps = stepsData.length / kWHSBytesInUUID;
  NSMutableArray *stepsIDs = [[NSMutableArray alloc] init];
  for (NSUInteger i = 0; i < numberOfSteps; ++i) {
    uuid_t UUID;
    [stepsData getBytes:UUID range:NSMakeRange(i * kWHSBytesInUUID, kWHSBytesInUUID)];
    [stepsIDs addObject:[[NSUUID alloc] initWithUUIDBytes:UUID]];
  }
  return stepsIDs;
}

- (BOOL)validateUpdateRequest:(WHSProjectUpdateRequest *)request
                     metadata:(NSDictionary<NSString *, id> *)metadata
                     stepsIDs:(NSArray<NSUUID *> *)stepsIDs
                        error:(NSError *__autoreleasing *)error {
  auto currentStepCursor = (NSNumber *)metadata[kWHSStepCursorKey];
  auto newStepCursor = request.stepCursor ?: currentStepCursor;
  auto numberOfStepsToAdd = request.stepsContentToAdd.count;
  auto numberOfStepsDelta = numberOfStepsToAdd - request.stepIDsToDelete.count;
  auto newNumberOfSteps = stepsIDs.count + numberOfStepsDelta;
  auto isValid = newStepCursor.unsignedIntegerValue <= newNumberOfSteps;
  if (isValid) {
    return YES;
  }
  if (error) {
    auto description = [NSString stringWithFormat:@"Given update request is not valid beacuse the "\
                        "step cursor after the update (%lu) is larger than the number of steps "\
                        "after the update (%lu). request: %@",
                        (unsigned long)newStepCursor.unsignedIntegerValue,
                        (unsigned long)newNumberOfSteps, request];
    *error = [NSError whs_errorWithCode:LTErrorCodeInvalidArgument
                    associatedProjectID:request.projectID description:@"%@", description];
  }
  return NO;
}

- (nullable NSArray<NSUUID *> *)createStepsFrom:(NSArray<WHSStepContent *> *)stepsContent
                                      inProject:(NSUUID *)projectID
                                          error:(NSError *__autoreleasing *)error {
  auto stepsIDsCreated = [[NSMutableArray<NSUUID *> alloc] init];
  for (NSUInteger i = 0; i < stepsContent.count; ++i) {
    auto stepID = [NSUUID UUID];
    auto stepURL = [self URLOfStep:stepID inProject:projectID];
    auto stepCreated = [self.fileManager createDirectoryAtURL:stepURL.whs_dataURL
                                  withIntermediateDirectories:YES attributes:nil error:error];
    if (!stepCreated) {
      [self removeContentOfSteps:stepsIDsCreated fromProject:projectID];
      return nil;
    }
    auto userDataUpdated = [self.fileManager lt_writeDictionary:stepsContent[i].userData
                                                         toFile:nn(stepURL.whs_userDataURL.path)
                                                         format:NSPropertyListBinaryFormat_v1_0
                                                          error:error];
    if (!userDataUpdated) {
      [self removeContentOfSteps:stepsIDsCreated fromProject:projectID];
      return nil;
    }
    auto _Nullable stepAssetsSourceURL = stepsContent[i].assetsSourceURL;
    NSURL * _Nullable emptyURL;
    if (!stepAssetsSourceURL) {
      emptyURL = [self createTempURLWithError:error];
      if (!emptyURL) {
        [self removeContentOfSteps:stepsIDsCreated fromProject:projectID];
        return nil;
      }
    }
    @onExit {
      if (emptyURL) {
        [self.fileManager removeItemAtURL:nn(emptyURL) error:nil];
      }
    };
    if (![self copyAssetsOfProject:projectID step:stepID from:nn(stepAssetsSourceURL ?: emptyURL)
                             error:error])
    {
      [self removeContentOfSteps:stepsIDsCreated fromProject:projectID];
      return nil;
    }
    [stepsIDsCreated addObject:stepID];
  }
  return stepsIDsCreated;
}

- (BOOL)copyAssetsOfProject:(NSUUID *)projectID step:(NSUUID *)stepID from:(NSURL *)sourceURL
                      error:(NSError *__autoreleasing *)error {
  auto destination = [self URLOfStep:stepID inProject:projectID].whs_assetsURL;
  return [self.fileManager copyItemAtURL:sourceURL toURL:destination error:error];
}

- (NSArray<NSUUID *> *)addStepsIDs:(NSArray<NSUUID *> *)stepsIDsToAdd
                        toStepsIDs:(NSArray<NSUUID *> *)stepsIDs
                          metadata:(NSDictionary<NSString *, id> *)metadata {
  auto stepCursor = ((NSNumber *)metadata[kWHSStepCursorKey]).unsignedIntegerValue;
  auto addingRange = NSMakeRange(stepCursor, stepsIDsToAdd.count);
  NSMutableArray<NSUUID *> *updatedStepsIDs = stepsIDs.mutableCopy;
  [updatedStepsIDs insertObjects:stepsIDsToAdd
                       atIndexes:[NSIndexSet indexSetWithIndexesInRange:addingRange]];
  return updatedStepsIDs;
}

- (NSArray<NSUUID *> *)removeStepsIDs:(NSArray<NSUUID *> *)stepsIDsToDelete
                         fromStepsIDs:(NSArray<NSUUID *> *)stepsIDs {
  return [stepsIDs lt_filter:^BOOL(NSUUID *step) {
    return ![stepsIDsToDelete containsObject:step];
  }];
}

- (NSDictionary<NSString *, id> *)changeStepCursorTo:(NSNumber *)stepCursor
                                          inMetadata:(NSDictionary<NSString *, id> *)metadata {
  NSMutableDictionary *updatedMetadata = metadata.mutableCopy;
  if (stepCursor) {
    updatedMetadata[kWHSStepCursorKey] = stepCursor;
  }
  return updatedMetadata;
}

- (void)removeContentOfSteps:(NSArray<NSUUID *> *)stepIDs fromProject:(NSUUID *)projectID {
  for (NSUUID *stepID in stepIDs) {
    [self.fileManager removeItemAtURL:[self URLOfStep:stepID inProject:projectID] error:nil];
  }
}

- (nullable NSUUID *)duplicateProjectWithID:(NSUUID *)projectID
                                      error:(NSError *__autoreleasing *)error {
  auto duplicatedID = [NSUUID UUID];
  auto _Nullable tempURL = [self createTempURLWithError:error];
  if (!tempURL) {
    [self assignErrorDuplicatingProject:projectID to:error];
    return nil;
  }
  @onExit {
    [self.fileManager removeItemAtURL:nn(tempURL) error:nil];
  };
  auto tempProjectURL = [tempURL URLByAppendingPathComponent:duplicatedID.UUIDString];
  auto contentCopied = [self.fileManager copyItemAtURL:[self URLOfProject:projectID]
                                                 toURL:tempProjectURL error:error];
  if (!contentCopied) {
    [self assignErrorDuplicatingProject:projectID to:error];
    return nil;
  }

  auto duplicated = [self.fileManager replaceItemAtURL:[self URLOfProject:duplicatedID]
                                         withItemAtURL:tempProjectURL backupItemName:nil options:0
                                      resultingItemURL:nil error:error];
  if (!duplicated) {
    [self assignErrorDuplicatingProject:projectID to:error];
    return nil;
  }
  [self notifyProjectDuplicated:projectID to:duplicatedID];
  return duplicatedID;
}

- (nullable NSURL *)createTempURLWithError:(NSError *__autoreleasing *)error {
  auto URL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
  return [self.fileManager URLForDirectory:NSItemReplacementDirectory inDomain:NSUserDomainMask
                         appropriateForURL:URL create:YES error:error];
}

- (void)assignErrorDuplicatingProject:(NSUUID *)projectID
                                   to:(NSError *__autoreleasing *)error {
  if (error) {
    *error = [NSError whs_errorDuplicatingProjectWithID:projectID underlyingError:*error];
  }
}

- (nullable WHSStep *)fetchStepWithID:(NSUUID *)stepID fromProjectWithID:(NSUUID *)projectID
                                error:(NSError *__autoreleasing *)error {
  auto stepURL = [self URLOfStep:stepID inProject:projectID];
  if (![self.fileManager fileExistsAtPath:nn(stepURL.path)]) {
    [self assignErrorFetchingStep:stepID fromProject:projectID to:error];
    return nil;
  }
  auto _Nullable userData = [self userDataFromURL:stepURL error:error];
  if (!userData) {
    [self assignErrorFetchingStep:stepID fromProject:projectID to:error];
    return nil;
  }
  return [[WHSStep alloc] initWithID:stepID projectID:projectID userData:nn(userData)
                           assetsURL:stepURL.whs_assetsURL];
}

- (NSURL *)URLOfStep:(NSUUID *)stepID inProject:(NSUUID *)projectID {
    auto stepsURL = [[self URLOfProject:projectID] URLByAppendingPathComponent:@"steps"
                                                                   isDirectory:YES];
    return nn([stepsURL URLByAppendingPathComponent:stepID.UUIDString isDirectory:YES]);
}

- (void)assignErrorFetchingStep:(NSUUID *)stepID fromProject:(NSUUID *)projectID
                             to:(NSError *__autoreleasing *)error {
  if (error) {
    *error = [NSError whs_errorFetchingStepWithID:stepID fromProjectWithID:projectID
                                  underlyingError:*error];
  }
}

- (nullable NSDictionary<NSString *, id> *)userDataFromURL:(NSURL *)URL
                                                     error:(NSError *__autoreleasing *)error {
  return [self.fileManager lt_dictionaryWithContentsOfFile:nn(URL.whs_userDataURL.path)
                                                     error:error];
}

- (BOOL)setCreationDate:(NSDate *)creationDate toProjectWithID:(NSUUID *)projectID
                  error:(NSError *__autoreleasing *)error {
  auto attributesChanges = @{NSFileCreationDate: creationDate};
  auto dateSet = [self.fileManager setAttributes:attributesChanges
                                    ofItemAtPath:nn([self URLOfProject:projectID].path)
                                           error:error];
  if (!dateSet && error) {
    *error = [NSError whs_errorSettingCreationDate:creationDate toProjectWithID:projectID
                                   underlyingError:*error];
  }
  return dateSet;
}

- (BOOL)setModificationDate:(NSDate *)modificationDate toProjectWithID:(NSUUID *)projectID
                      error:(NSError *__autoreleasing *)error {
  auto attributesChanges = @{NSFileModificationDate: modificationDate};
  auto dateSet =  [self.fileManager setAttributes:attributesChanges
                                     ofItemAtPath:nn([self URLOfProject:projectID].path)
                                            error:error];
  if (!dateSet && error) {
    *error = [NSError whs_errorSettingModificationDate:modificationDate toProjectWithID:projectID
                                       underlyingError:*error];
  }
  return dateSet;
}

- (NSURL *)URLOfProject:(NSUUID *)projectID {
    return nn([self.baseURL URLByAppendingPathComponent:projectID.UUIDString isDirectory:YES]);
}

- (void)addObserver:(id<WHSProjectStorageObserver>)observer {
  [self.observers setObject:[NSNull null] forKey:observer];
}

- (void)removeObserver:(id<WHSProjectStorageObserver>)observer {
  [self.observers removeObjectForKey:observer];
}

- (void)notifyProjectCreated:(NSUUID *)projectID {
  for (id<WHSProjectStorageObserver> observer in self.observers) {
    if ([observer respondsToSelector:@selector(storage:createdProjectWithID:)]) {
      [observer storage:self createdProjectWithID:projectID];
    }
  }
}

- (void)notifyProjectUpdated:(NSUUID *)projectID {
  for (id<WHSProjectStorageObserver> observer in self.observers) {
    if ([observer respondsToSelector:@selector(storage:updatedProjectWithID:)]) {
      [observer storage:self updatedProjectWithID:projectID];
    }
  }
}

- (void)notifyProjectDeleted:(NSUUID *)projectID {
  for (id<WHSProjectStorageObserver> observer in self.observers) {
    if ([observer respondsToSelector:@selector(storage:deletedProjectWithID:)]) {
      [observer storage:self deletedProjectWithID:projectID];
    }
  }
}

- (void)notifyProjectDuplicated:(NSUUID *)sourceProjectID
                             to:(NSUUID *)destinationProjectID {
  for (id<WHSProjectStorageObserver> observer in self.observers) {
    if ([observer respondsToSelector:@selector(storage:duplicatedProjectWithID:destinationID:)]) {
      [observer storage:self duplicatedProjectWithID:sourceProjectID
          destinationID:destinationProjectID];
    }
  }
}

@end

NS_ASSUME_NONNULL_END
