// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "TINMessageFactory.h"

#import <LTKit/NSDictionary+Operations.h>
#import <LTKit/NSFileManager+LTKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "NSErrorCodes+TinCan.h"
#import "NSURL+TinCan.h"
#import "TINMessage+UserInfo.h"

/// Available file operations.
LTEnumImplement(NSUInteger, TINMessageFileOperation,
  /// File should be moved to a new location.
  TINMessageFileOperationMove,
  /// File should be copied to a new location.
  TINMessageFileOperationCopy
);

NS_ASSUME_NONNULL_BEGIN

// Returns the preferred file extension for the given \c uti. On error returns \c nil and sets the
// given \c error.
static NSString * _Nullable TINMessageFactoryExtensionFromUTI(NSString *uti,
                                                              NSError **error) {
  auto extensionRef = UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)uti,
                                                      kUTTagClassFilenameExtension);
  auto _Nullable extension = (__bridge_transfer NSString * _Nullable)extensionRef;
  if (!extension) {
    if (error) {
      *error = [NSError lt_errorWithCode:TINErrorCodeInvalidUTI description:@"UTI: %@", uti];
    }
    return nil;
  }

  return extension;
}

@implementation TINMessageFactory

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithSourceScheme:(NSString *)sourceScheme
                         fileManager:(NSFileManager *)fileManager
                          appGroupID:(NSString *)appGroupID {
  if (self = [super init]) {
    _sourceScheme = sourceScheme;
    _fileManager = fileManager;
    _appGroupID = appGroupID;
  }
  return self;
}

+ (instancetype)messageFactoryWithSourceScheme:(NSString *)sourceScheme {
  return [[self alloc] initWithSourceScheme:sourceScheme
                                fileManager:[NSFileManager defaultManager]
                                 appGroupID:kTINAppGroupID];
}

+ (instancetype)messageFactoryWithSourceScheme:(NSString *)sourceScheme
                                   fileManager:(NSFileManager *)fileManager {
  return [[self alloc] initWithSourceScheme:sourceScheme fileManager:fileManager
                                 appGroupID:kTINAppGroupID];
}

+ (instancetype)messageFactoryWithSourceScheme:(NSString *)sourceScheme
                                   fileManager:(NSFileManager *)fileManager
                                    appGroupID:(NSString *)appGroupID {
  return [[self alloc] initWithSourceScheme:sourceScheme fileManager:fileManager
                                 appGroupID:appGroupID];
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (nullable TINMessage *)messageWithTargetScheme:(NSString *)targetScheme
                                           block:(TINMessageUserInfoProviderBlock)block
                                           error:(NSError *__autoreleasing *)error {
  auto messageID = [NSUUID UUID];
  auto _Nullable messageDirectory = [NSURL tin_messageDirectoryURLWithAppGroup:self.appGroupID
                                                                        scheme:targetScheme
                                                                    identifier:messageID];
  if (!messageDirectory) {
    if (error) {
      *error = [NSError lt_errorWithCode:TINErrorCodeAppGroupAccessFailed
                             description:@"Application Group ID: %@", self.appGroupID];
    }
    return nil;
  }

  NSError *blockError;
  auto _Nullable userInfo = block(nn(messageDirectory), &blockError);
  if (blockError) {
    if (error) {
      *error = blockError;
    }
    return nil;
  }
  if (!userInfo) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed description:@"Block "
                "returned nil without reporting an error"];
    }
    return nil;
  }

  return [TINMessage messageWithAppGroupID:self.appGroupID sourceScheme:self.sourceScheme
                              targetScheme:targetScheme identifier:messageID userInfo:nn(userInfo)];
}

- (nullable TINMessage *)messageWithTargetScheme:(NSString *)targetScheme
    userInfo:(NSDictionary<NSString *, id<NSSecureCoding>> *)info data:(NSData *)data
    uti:(NSString *)uti error:(NSError *__autoreleasing *)error {
  return [self messageWithTargetScheme:targetScheme
                                 block:^NSDictionary * _Nullable(NSURL *messageDirectory,
                                                                 NSError **blockError) {
    NSError *underlyingError;
    auto success = [self.fileManager createDirectoryAtURL:nn(messageDirectory)
                              withIntermediateDirectories:YES attributes:nil
                                                    error:&underlyingError];
    if (!success) {
      if (blockError) {
        *blockError = underlyingError;
      }
      return nil;
    }

    auto _Nullable extension = TINMessageFactoryExtensionFromUTI(uti, &underlyingError);
    if (!extension) {
      if (blockError) {
        *blockError = underlyingError;
      }
      return nil;
    }

    auto fileName = [[NSUUID UUID].UUIDString stringByAppendingPathExtension:nn(extension)];
    auto _Nullable fileURL = [messageDirectory URLByAppendingPathComponent:fileName];
    if (!fileURL) {
      if (blockError) {
        *blockError = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                                    description:@"Failed getting file url for message "
                       "directory: %@", messageDirectory];
      }
      return nil;
    }

    success = [self.fileManager lt_writeData:data toFile:nn(fileURL.path)
                                     options:NSDataWritingAtomic error:&underlyingError];
    if (!success) {
      if (blockError) {
        *blockError = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                                underlyingError:underlyingError description:@"Failed writing "
                       "data to file %@", fileURL];
      }
      return nil;
    }
    return [info lt_merge:@{kTINMessageFileNamesKey: @[fileName]}];
  } error:error];
}

- (nullable TINMessage *)messageWithTargetScheme:(NSString *)targetScheme
    userInfo:(NSDictionary<NSString *, id<NSSecureCoding>> *)info image:(UIImage *)image
    error:(NSError *__autoreleasing *)error {
  auto _Nullable imageData = UIImagePNGRepresentation(image);
  if (!imageData) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Failed creating data from image"];
    }
    return nil;
  }

  return [self messageWithTargetScheme:targetScheme userInfo:info data:nn(imageData)
                                   uti:(__bridge NSString *)kUTTypePNG error:error];
}

- (nullable TINMessage *)messageWithTargetScheme:(NSString *)targetScheme
    userInfo:(NSDictionary<NSString *, id<NSSecureCoding>> *)info fileURL:(NSURL *)fileURL
    operation:(TINMessageFileOperation *)operation
    error:(NSError *__autoreleasing *)error {
  if (!fileURL.path || ![self.fileManager lt_fileExistsAtPath:nn(fileURL.path)]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound url:fileURL];
    }
    return nil;
  }

  return [self messageWithTargetScheme:targetScheme
                                 block:^NSDictionary * _Nullable(NSURL *messageDirectory,
                                                                 NSError **blockError) {
    if (!messageDirectory.path) {
      return nil;
    }

    NSError *underlyingError;
    if (![self.fileManager createDirectoryAtURL:nn(messageDirectory)
                    withIntermediateDirectories:YES attributes:nil error:&underlyingError]) {
      if (blockError) {
        *blockError = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                                underlyingError:underlyingError description:@"Failed creating "
                       "directory %@", messageDirectory];
      }
      return nil;
    }
    auto fileBaseName = [NSUUID UUID].UUIDString;
    auto fileName = fileURL.pathExtension ?
        [fileBaseName stringByAppendingPathExtension:nn(fileURL.pathExtension)] : fileBaseName;
    auto targetFileURL = [NSURL fileURLWithPath:[nn(messageDirectory.path)
                                                 stringByAppendingPathComponent:fileName]];

    BOOL success = NO;
    switch (operation.value) {
      case TINMessageFileOperationMove:
        success = [self.fileManager moveItemAtURL:fileURL toURL:nn(targetFileURL)
                                            error:&underlyingError];
        break;
      case TINMessageFileOperationCopy:
        success = [self.fileManager copyItemAtURL:fileURL toURL:nn(targetFileURL)
                                            error:&underlyingError];
        break;
    }
    if (!success) {
      if (blockError) {
        *blockError = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                                underlyingError:underlyingError description:@"Failed performing %@ "
                       "operation for file %@", operation.name, fileURL];
      }
      return nil;
    }
    return [info lt_merge:@{kTINMessageFileNamesKey: @[fileName]}];
  } error:error];
}

@end

NS_ASSUME_NONNULL_END
