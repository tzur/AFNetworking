// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Available Dropbox thumbnail size types.
LTEnumDeclare(NSUInteger, PTNDropboxThumbnailType,
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

/// Additional fields for the \c PTNDropboxThumbnailType, enabling easy mapping to information
/// relevant in the Dropbox domain.
@interface PTNDropboxThumbnailType (Additions)

/// Name of this Dropbox thumbnail type according to the Dropbox SDK.
@property (readonly, nonatomic) NSString *sizeName;

/// Size of this Dropbox thumbnail type according to the Dropbox SDK.
@property (readonly, nonatomic) CGSize size;

@end

NS_ASSUME_NONNULL_END
