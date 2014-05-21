// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

@class LTTexture;

/// Protocol to be implemented by objects that are capable of archiving texture contents. The
/// archiving process should store data that will allow restoring the contents back. The trivial
/// implementation is to store the contents to a file or other storage mechanism, but more
/// sophisticated archivers may reduce store time and space by storing only a location of the
/// texture on disk or a URL, in case that the texture can be completely restored from that
/// location.
@protocol LTTextureContentsArchiver <NSSecureCoding, NSObject>

/// Stores the texture or metadata about the texture that allows restoring the same texture using
/// the \c -[LTTextureContentsArchiver unarchiveToTexture:error:] method. Returns an opaque \c
/// NSData object to give back to \-[LTTextureContentsArchiver unarchiveToTexture:error:] to restore
/// the texture. If the archiving failed, \c nil will be returned and the given \c error, if not \c
/// nil, will be populated.
- (NSData *)archiveTexture:(LTTexture *)texture error:(NSError **)error;

/// Loads the previously stored texture using the given opaque \c NSData object. The texture must be
/// of the same size, format and precision of the loaded image. Returns \c YES if texture storage
/// has been successfully loaded to the given \c texture, otherwise \c error, if not \c nil, will be
/// populated.
- (BOOL)unarchiveData:(NSData *)data toTexture:(LTTexture *)texture error:(NSError **)error;

@end

/// Retrieves a set of \c Class objects of all the classes which implement the \c
/// LTTextureContentsArchiver protocol.
NSSet *LTTextureContentsArchivers();
