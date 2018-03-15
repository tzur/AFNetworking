// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "NSFileManager+TinCan.h"

#import <LTKit/NSFileManager+LTKit.h>

#import "NSErrorCodes+TinCan.h"
#import "NSURL+TinCan.h"
#import "TINMessage.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSFileManager (TinCan)

- (BOOL)tin_writeMessage:(id<NSSecureCoding>)message toURL:(NSURL *)url
                   error:(NSError *__autoreleasing *)error {
  if (![url isFileURL]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeInvalidArgument
                             description:@"%@ must be a file url", url];
    }
    return NO;
  }

  auto directoryURL = [url URLByDeletingLastPathComponent];
  NSError *internalError;
  auto success = [self createDirectoryAtURL:directoryURL withIntermediateDirectories:YES
                                 attributes:nil error:&internalError];
  if (!success) {
    if (error) {
      *error = internalError;
    }
    return NO;
  }

  auto data = [self tin_securelyCodedDataFromMessage:message];
  success = [self lt_writeData:data toFile:nn(url.path) options:NSDataWritingAtomic
                         error:&internalError];
  if (!success) {
    if (error) {
      *error = internalError;
    }
    return NO;
  }

  return YES;
}

- (NSData *)tin_securelyCodedDataFromMessage:(id<NSSecureCoding>)message {
  auto mutableData = [NSMutableData data];
  auto archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:mutableData];
  archiver.requiresSecureCoding = YES;
  [archiver encodeObject:message forKey:NSKeyedArchiveRootObjectKey];
  [archiver finishEncoding];
  return [mutableData copy];
}

- (nullable TINMessage *)tin_readMessageFromURL:(NSURL *)url
                                          error:(NSError *__autoreleasing *)error {
  if (!url.isFileURL || !url.path) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeInvalidArgument
                             description:@"%@ must be file url", url];
    }
    return nil;
  }

  NSError *internalError;
  auto _Nullable data = [self lt_dataWithContentsOfFile:nn(url.path) options:0
                                                  error:&internalError];
  if (!data) {
    if (error) {
      *error = internalError;
    }
    return nil;
  }

  auto unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:nn(data)];
  TINMessage * _Nullable message = [unarchiver decodeObjectOfClass:TINMessage.class
                                                            forKey:NSKeyedArchiveRootObjectKey];
  if (!message) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed
                             description:@"Error occurred when reading from %@", url];
    }
    return nil;
  }

  return message;
}

- (BOOL)tin_removeAllMessagesWithAppGroupID:(NSString *)appGroupID scheme:(NSString *)scheme
                                      error:(NSError *__autoreleasing *)error {
  auto _Nullable messagesDirectoryURL = [NSURL tin_messagesDirectoryURLWithAppGroup:appGroupID
                                                                             scheme:scheme];
  if (!messagesDirectoryURL) {
    if (error) {
      *error = [NSError lt_errorWithCode:TINErrorCodeAppGroupAccessFailed];
    }
    return NO;
  }
  return [self removeItemAtURL:nn(messagesDirectoryURL) error:error];
}

@end

NS_ASSUME_NONNULL_END
