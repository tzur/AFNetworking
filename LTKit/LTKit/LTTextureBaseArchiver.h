// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// Protocol for texture archivers, providing interface for archiving the content of a texture to a
/// file and unarchving a file into a texture.
@protocol LTTextureBaseArchiver

/// Archives the given \c texture to a file in the given \c path. Returns \c YES on success or \c NO
/// while populating \c error in case of a failure.
///
/// @note The archiver must create the file at the given path in case of success.
- (BOOL)archiveTexture:(LTTexture *)texture inPath:(NSString *)path error:(NSError **)error;

/// Unarchives the file at the given \c path to the given \c texture. Returns \c YES on success or
/// \c NO while populating \c error in case of a failure.
///
/// @note The type and dimension of \c texture must match the type and dimension of the archive at
/// the given \c path.
- (BOOL)unarchiveToTexture:(LTTexture *)texture fromPath:(NSString *)path error:(NSError **)error;

/// Removes the archive at the given path, and any additional files that were created by this
/// archiver when the archive was created. Returns \c YES on success or \c NO while populating \c
/// error in case of a failure.
- (BOOL)removeArchiveInPath:(NSString *)path error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
