// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

@protocol LTTextureBaseArchiver;

/// Available archive types for \c LTTextures.
LTEnumDeclare(NSUInteger, LTTextureArchiveType,
  /// Archives the texture as an uncompressed mat.
  LTTextureArchiveTypeUncompressedMat,
  /// Archives the texture as a jpeg.
  /// The texture must be of byte-precision, and its alpha channel will be ignored (textures with
  /// \c usingAlphaChannel of \c YES cannot be archived using this type).
  LTTextureArchiveTypeJPEG,
  /// Archives the texture in the ImageZero format.
  /// The texture must be RGBA8, and its alpha channel will be ignored (textures with
  /// \c usingAlphaChannel of \c YES cannot be archived using this type).
  LTTextureArchiveTypeIZ
);

/// Category providing methods returning \c LTTextureBaseArchiver instances according to the archive
/// type.
@interface LTTextureArchiveType (LTTextureArchiveType)

/// Returns the archiver that should be used to archive/unarchive this type.
- (id<LTTextureBaseArchiver>)archiver;

/// Returns the file extension associated with this type.
- (NSString *)fileExtension;

@end

NS_ASSUME_NONNULL_END
