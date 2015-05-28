// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

@class LTTexture, LTTextureArchiveType;

/// Protocol for a key-value storage used by the \c LTTextureArchiver.
@protocol LTTextureArchiverStorage <NSObject>

/// Loads the value for the key specified by \c key and returns it, or \c nil on failure.
- (id)objectForKeyedSubscript:(NSString *)key;

/// Associates \c object with the specified \c key. Both \c key and \c object must not be \c nil.
/// Will raise an exception on failure. After a successful invocation of this method a following
/// \c objectForKeyedSubscript:key will return an object which is equal to \c object.
///
/// Note that a copy of \c object may be created.
- (void)setObject:(id<NSCopying>)object forKeyedSubscript:(NSString *)key;

/// Deletes the object attached to the key specified by \c key. Should raise an exception on
/// failure. It must hold that after a successful invocation of this method invocation of
/// \c objectForKeyedSubscript:key will fail.
- (void)removeObjectForKey:(NSString *)key;

/// Returns a new array of \c NSStrings containing the stored keys, or an empty array if the storage
/// has no entries.
///
/// @note The order of the elements in the array is not defined.
- (NSArray *)allKeys;

@end

/// Archives texture's contents to a persistent file. This is optimized to minimize the data
/// actually stored, for example by avoiding storing the contents of textures filled by a single
/// color, or storing the contents of multiple identical textures only once (in a manner transparent
/// to the user). The storage is used to keep track multiple references of identical textures that
/// were stored, and should be persistent in case any of the archived textures are persistent as
/// as well. One can use inpersistent storage in case all the archived textures are discarded at
/// certain points, and discard the storage at that point too.
///
/// In case the storage is discarded or corrupted, the archiver can end up storing the content of
/// identical textures more than once, but won't affect the ability to load textures that were
/// previously archived.
///
/// In case the files of an archived texture are deleted not through the archiver the storage can
/// end up having zombie records but this will not affect the ability to load other textures (even
/// ones identical to the texture that was deleted). This does not depend on which texture was
/// deleted (one can not by mistake delete the "real" copy of the content shared by multiple
/// identical archived textures).
///
/// @note all paths provided to the public methods of the archiver are relative to the base
/// directory given upon initialization.
///
/// @note the current implementation does not accept mipmap textures, and will assert in case such a
/// texture is provided as the source to archive or target to unarchive into.
@interface LTTextureArchiver : NSObject

/// Initializes the archiver with the given \c storage and the documents directory of the app as its
/// base directory.
- (instancetype)initWithStorage:(id<LTTextureArchiverStorage>)storage;

/// Initializes the archiver with the given \c storage and the given directory as the base directory
/// for all relative paths provided to it.
- (instancetype)initWithStorage:(id<LTTextureArchiverStorage>)storage
                  baseDirectory:(NSString *)baseDirectory NS_DESIGNATED_INITIALIZER;

/// Creates an archive of the given \c type in the given \c path, storing the given \c texture.
/// Returns \c YES in case of success, or \c NO while populating \c error in case of failure.
///
/// @note This method will not overwrite an existing archive, and will return error instead.
- (BOOL)archiveTexture:(LTTexture *)texture inPath:(NSString *)path
       withArchiveType:(LTTextureArchiveType *)type error:(NSError **)error;

/// Loads the texture archive of the given \c type in the given \c path into the given \c texture,
/// whose properties must match the properties of the archived texture. Returns \c YES in case of
/// success, or \c NO while populating \c error in case of failure.
- (BOOL)unarchiveToTexture:(LTTexture *)texture fromPath:(NSString *)path
           withArchiveType:(LTTextureArchiveType *)type error:(NSError **)error;

/// Loads the texture archive of the given \c type in the given \c path into a newly allocated
/// texture. Returns \c nil while populating \c error in case of failure.
- (LTTexture *)unarchiveFromPath:(NSString *)path withArchiveType:(LTTextureArchiveType *)type
                           error:(NSError **)error;

/// Removes the archive of the given \c type in the given \c path. Returns \c YES in case of success
/// or \c NO while populating \c error in case of failure.
///
/// @note In case of failure it is possible that the archive is left in an inconsistent state and
/// the behavior in case of trying to unarchive it or remove it again is undefined.
- (BOOL)removeArchiveType:(LTTextureArchiveType *)type inPath:(NSString *)path
                    error:(NSError **)error;

/// Cleans up the storage by removing records referring to files that does not exist and keys that
/// do not refer to any existing file.
- (void)performStorageMaintenance;

/// Base directory of the archiver. All paths given as arguments to the archiver are treated as
/// relative to it.
@property (readonly, nonatomic) NSString *baseDirectory;

@end

NS_ASSUME_NONNULL_END
