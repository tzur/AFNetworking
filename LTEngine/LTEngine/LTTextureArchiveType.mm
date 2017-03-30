// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureArchiveType.h"

#import "LTTextureIZArchiver.h"
#import "LTTextureJpegArchiver.h"
#import "LTTextureLZ4Archiver.h"
#import "LTTextureOpenExrArchiver.h"
#import "LTTextureUncompressedMatArchiver.h"

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, LTTextureArchiveType,
  LTTextureArchiveTypeUncompressedMat,
  LTTextureArchiveTypeJPEG,
  LTTextureArchiveTypeIZ,
  LTTextureArchiveTypeLZ4,
  LTTextureArchiveTypeOpenExr
);

@implementation LTTextureArchiveType (LTTextureArchiveType)

static NSArray * const kArchivers = @[
  [LTTextureUncompressedMatArchiver class],
  [LTTextureJpegArchiver class],
  [LTTextureIZArchiver class],
  [LTTextureLZ4Archiver class],
  [LTTextureOpenExrArchiver class]
];

- (id<LTTextureBaseArchiver>)archiver {
  return [[kArchivers[self.value] alloc] init];
}

static NSArray * const kFileExtensions = @[
  @"mat",
  @"jpg",
  @"iz",
  @"lz4",
  @"exr"
];

- (NSString *)fileExtension {
  return kFileExtensions[self.value];
}

@end

NS_ASSUME_NONNULL_END
