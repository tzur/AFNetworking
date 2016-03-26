// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureArchiveType.h"

#import "LTTextureIZArchiver.h"
#import "LTTextureJpegArchiver.h"
#import "LTTextureUncompressedMatArchiver.h"

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, LTTextureArchiveType,
  LTTextureArchiveTypeUncompressedMat,
  LTTextureArchiveTypeJPEG,
  LTTextureArchiveTypeIZ
);

@implementation LTTextureArchiveType (LTTextureArchiveType)

static NSArray * const kArchivers = @[
  [LTTextureUncompressedMatArchiver class],
  [LTTextureJpegArchiver class],
  [LTTextureIZArchiver class]
];

- (id<LTTextureBaseArchiver>)archiver {
  return [[kArchivers[self.value] alloc] init];
}

static NSArray * const kFileExtensions = @[
  @"mat",
  @"jpg",
  @"iz"
];

- (NSString *)fileExtension {
  return kFileExtensions[self.value];
}

@end

NS_ASSUME_NONNULL_END
