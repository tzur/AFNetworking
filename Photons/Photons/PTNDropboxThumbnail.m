// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxThumbnail.h"

NS_ASSUME_NONNULL_BEGIN

/// Available Dropbox thumbnail size types.
LTEnumImplement(NSUInteger, PTNDropboxThumbnailType,
  /// 32x32.
  PTNDropboxThumbnailTypeExtraSmall,
  /// 64x64.
  PTNDropboxThumbnailTypeSmall,
  /// 128x128.
  PTNDropboxThumbnailTypeMedium,
  /// 640x480.
  PTNDropboxThumbnailTypeLarge,
  /// 1024x768.
  PTNDropboxThumbnailTypeExtraLarge
);

@implementation PTNDropboxThumbnailType (Additions)

- (NSString *)sizeName {
  switch (self.value) {
    case PTNDropboxThumbnailTypeExtraSmall:
      return @"xs";
    case PTNDropboxThumbnailTypeSmall:
      return @"s";
    case PTNDropboxThumbnailTypeMedium:
      return @"m";
    case PTNDropboxThumbnailTypeLarge:
      return @"l";
    case PTNDropboxThumbnailTypeExtraLarge:
      return @"xl";
  }
}

- (CGSize)size {
  switch (self.value) {
    case PTNDropboxThumbnailTypeExtraSmall:
      return CGSizeMake(32, 32);
    case PTNDropboxThumbnailTypeSmall:
      return CGSizeMake(64, 64);
    case PTNDropboxThumbnailTypeMedium:
      return CGSizeMake(128, 128);
    case PTNDropboxThumbnailTypeLarge:
      return CGSizeMake(640, 480);
    case PTNDropboxThumbnailTypeExtraLarge:
      return CGSizeMake(1024, 768);
  }
}

@end

NS_ASSUME_NONNULL_END
