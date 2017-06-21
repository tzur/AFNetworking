// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRZipUnarchiver.h"

#import <ZipArchive/SSZipArchive.h>

#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRZipUnarchivingDelegate
#pragma mark -

/// Delegate for zip unarchiving operations.
@interface BZRZipUnarchivingDelegate : NSObject <SSZipArchiveDelegate>

/// Block to be reported on unarchiving progress. The unarchiving continues as long as this block
/// returns \c YES, if it returns \c NO unarchiving is marked as cancelled and no additional files
/// would be extracted.
@property (readonly, nonatomic, nullable) BZRZipArchiveProgressBlock progressBlock;

/// \c YES if the operation was cancelled.
@property (atomic) BOOL wasCancelled;

@end

@implementation BZRZipUnarchivingDelegate

- (instancetype)initWithProgressBlock:(nullable BZRZipArchiveProgressBlock)progressBlock {
  if (self = [super init]) {
    _progressBlock = progressBlock;
  }
  return self;
}

- (BOOL)zipArchiveShouldUnzipFileAtIndex:(NSInteger __unused)fileIndex
                              totalFiles:(NSInteger __unused)totalFiles
                             archivePath:(NSString __unused *)archivePath
                                fileInfo:(unz_file_info __unused)fileInfo {
  return !self.wasCancelled;
}

- (void)zipArchiveProgressEvent:(unsigned long long)loaded total:(unsigned long long)total {
  if (self.progressBlock) {
    self.wasCancelled = !self.progressBlock(@(total), @(loaded));
  }
}

@end

#pragma mark -
#pragma mark BZRZipUnarchiver
#pragma mark -

@implementation BZRZipUnarchiver

@synthesize path = _path;
@synthesize password = _password;
@synthesize archivingQueue = _archivingQueue;

- (instancetype)initWithPath:(NSString *)path password:(nullable NSString *)password
              archivingQueue:(nullable dispatch_queue_t)archivingQueue {
  if (self = [super init]) {
    _path = [path copy];
    _password = [password copy];
    _archivingQueue = archivingQueue ?:
        dispatch_queue_create("com.lightricks.bazaar.zip-unarchiver", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)unarchiveFilesToPath:(NSString *)path progress:(nullable BZRZipArchiveProgressBlock)progress
                  completion:(LTSuccessOrErrorBlock)completion {
  LTParameterAssert(completion, @"Completion block must not be nil");

  // No weakify here due to importance of holding self until the block completion.
  dispatch_async(self.archivingQueue, ^{
    BZRZipUnarchivingDelegate *delegate =
        [[BZRZipUnarchivingDelegate alloc] initWithProgressBlock:progress];

    NSError *error;
    BOOL success = [SSZipArchive unzipFileAtPath:self.path toDestination:path preserveAttributes:YES
                                       overwrite:YES password:self.password error:&error
                                        delegate:delegate];
    if (!success) {
      if (delegate.wasCancelled) {
        error = [NSError bzr_errorWithCode:BZRErrorCodeArchivingCancelled archivePath:self.path
                    failingArchiveItemPath:nil underlyingError:nil
                               description:@"Unarchiving was cancelled"];
      } else {
        error = [NSError lt_errorWithCode:BZRErrorCodeUnarchivingFailed path:self.path
                          underlyingError:error];
      }
    }

    completion(success, error);
  });
}

@end

NS_ASSUME_NONNULL_END
