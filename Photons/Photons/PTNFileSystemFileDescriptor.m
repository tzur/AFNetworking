// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNFileSystemFileDescriptor.h"

#import <AVFoundation/AVFoundation.h>
#import <LTKit/LTPath.h>
#import <LTKit/LTUTICache.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "NSString+UTI.h"
#import "NSURL+FileSystem.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFileSystemFileDescriptor ()

/// Path of the descriptor.
@property (strong, nonatomic) LTPath *path;

/// Date the file represented by this descriptor was originally created.
@property (strong, nonatomic, nullable) NSDate *creationDate;

/// Date the file represented by this descriptor was last modified.
@property (strong, nonatomic, nullable) NSDate *modificationDate;

/// \c YES if duration was already fetched \c NO otherwise.
@property (nonatomic) BOOL fetchedDuration;

@end

@implementation PTNFileSystemFileDescriptor

@synthesize duration = _duration;

- (instancetype)initWithPath:(LTPath *)path {
  return [self initWithPath:path creationDate:nil modificationDate:nil];
}

- (instancetype)initWithPath:(LTPath *)path creationDate:(nullable NSDate *)creationDate
            modificationDate:(nullable NSDate *)modificationDate {
  if (self = [super init]) {
    self.path = path;
    self.creationDate = creationDate;
    self.modificationDate = modificationDate;
  }
  return self;
}

- (NSURL *)ptn_identifier {
  return [NSURL ptn_fileSystemAssetURLWithPath:self.path];
}

- (nullable NSString *)localizedTitle {
  return self.path.relativePath.lastPathComponent;
}

- (PTNDescriptorCapabilities)descriptorCapabilities {
  return PTNDescriptorCapabilityNone;
}

- (PTNAssetDescriptorCapabilities)assetDescriptorCapabilities {
  return PTNAssetDescriptorCapabilityNone;
}

- (nullable NSString *)filename {
  return self.path.path.lastPathComponent;
}

- (NSSet<NSString *> *)descriptorTraits {
  NSMutableSet<NSString *> *traits = [NSMutableSet set];
  NSSet<NSString *> *videoFilesExtensions = [PTNFileSystemFileDescriptor videoFilesExtensions];
  NSString *fileExtension = [self.path.url.pathExtension lowercaseString];
  if ([videoFilesExtensions containsObject:fileExtension]) {
    [traits addObject:kPTNDescriptorTraitAudiovisualKey];
  }

  NSString *uti = [[LTUTICache sharedCache] preferredUTIForFileExtension:fileExtension];
  if ([uti ptn_isRawImageUTI]) {
    [traits addObject:kPTNDescriptorTraitRawKey];
  }
  if ([uti ptn_isGIFUTI]) {
    [traits addObject:kPTNDescriptorTraitGIFKey];
  }
  return traits;
}

+ (NSSet<NSString *> *)videoFilesExtensions {
  static NSSet<NSString *> *extensions;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSArray<NSString *> *UTIs = [AVURLAsset audiovisualTypes];
    NSMutableSet<NSString *> *filenameExtensions = [NSMutableSet set];
    for (NSString *UTI in UTIs) {
      NSArray<NSString *> *fileExtensions =
          [PTNFileSystemFileDescriptor fileExtensionsForUTI:[UTI lowercaseString]];
      [filenameExtensions addObjectsFromArray:fileExtensions];
    }
    extensions = filenameExtensions;
  });

  return extensions;
}

+ (NSArray<NSString *> *)fileExtensionsForUTI:(NSString *)UTI {
  CFArrayRef _Nullable extensions =
      UTTypeCopyAllTagsWithClass((__bridge CFStringRef)UTI, kUTTagClassFilenameExtension);
  if (!extensions) {
    return @[];
  }

  return (__bridge_transfer NSArray *)extensions;
}

- (NSTimeInterval)duration {
  if (![[self descriptorTraits] containsObject:kPTNDescriptorTraitAudiovisualKey]) {
    return 0;
  }

  if (self.fetchedDuration) {
    return _duration;
  }

  self.fetchedDuration = YES;
  AVAsset *asset = [AVAsset assetWithURL:self.path.url];
  CMTime assetDuration = asset.duration;
  _duration = CMTIME_IS_NUMERIC(assetDuration) ? CMTimeGetSeconds(assetDuration) : 0.0;

  return _duration;
}

- (nullable NSString *)artist {
  return nil;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, path: %@, created: %@, last modified: %@>",
          self.class, self, self.path, self.creationDate ?: @"N/A",
          self.modificationDate ?: @"N/A"];
}

- (BOOL)isEqual:(PTNFileSystemFileDescriptor *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  BOOL equalCreationDate = (self.creationDate == object.creationDate) ||
       [self.creationDate isEqualToDate:object.creationDate];
  BOOL equalModificationDate = (self.modificationDate == object.modificationDate) ||
       [self.modificationDate isEqualToDate:object.modificationDate];

  return [self.path isEqual:object.path] && equalCreationDate && equalModificationDate;
}

- (NSUInteger)hash {
  return self.path.hash ^ self.creationDate.hash ^ self.modificationDate.hash;
}

@end

NS_ASSUME_NONNULL_END
