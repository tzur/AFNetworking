// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRZipArchiveFactory.h"

#import "BZRZipArchiver.h"
#import "BZRZipUnarchiver.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRZipArchiveFactory

- (nullable id<BZRZipArchiver>)zipArchiverAtPath:(NSString *)path
                                    withPassword:(nullable NSString *)password
                                           error:(NSError * __autoreleasing *)error {
  return [BZRZipArchiver zipArchiverWithPath:path password:password error:error];
}

- (nullable id<BZRZipUnarchiver>)zipUnarchiverAtPath:(NSString *)path
                                        withPassword:(nullable NSString *)password
                                               error:(NSError * __autoreleasing * __unused)error {
  return [[BZRZipUnarchiver alloc] initWithPath:path password:password archivingQueue:nil];
}

@end

NS_ASSUME_NONNULL_END
