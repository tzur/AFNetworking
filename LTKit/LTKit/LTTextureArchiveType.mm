// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureArchiveType.h"

#import "LTTextureJpegArchiver.h"
#import "LTTextureUncompressedMatArchiver.h"

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, LTTextureArchiveType,
  LTTextureArchiveTypeUncompressedMat,
  LTTextureArchiveTypeJPEG
);

@implementation LTTextureArchiveType (LTTextureArchiveType)

static NSArray * const kArchivers = @[
  [LTTextureUncompressedMatArchiver class],
  [LTTextureJpegArchiver class]
];

- (id<LTTextureBaseArchiver>)archiver {
  return [[kArchivers[self.value] alloc] init];
}

static NSArray * const kFileExtensions = @[
  @"mat",
  @"jpg"
];

- (NSString *)fileExtension {
  return kFileExtensions[self.value];
}

@end

NS_ASSUME_NONNULL_END
