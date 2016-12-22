// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNFileSystemFileDescriptor.h"

#import <LTKit/LTPath.h>

#import "NSURL+FileSystem.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFileSystemFileDescriptor ()

/// Path of the descriptor.
@property (strong, nonatomic) LTPath *path;

/// Date the file represented by this descriptor was originally created.
@property (strong, nonatomic, nullable) NSDate *creationDate;

/// Date the file represented by this descriptor was last modified.
@property (strong, nonatomic, nullable) NSDate *modificationDate;

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

- (NSSet<NSString *> *)descriptorTraits {
  return [NSSet set];
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
