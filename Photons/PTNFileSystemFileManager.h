// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Protocol describing a file system file manager enabling querying of various file metadata at
/// different paths.
@protocol PTNFileSystemFileManager <NSObject>

/// Returns an \c NSArray of \c NSURLs identifying the the directory entries. If this method returns
/// \c nil, an \c NSError will be returned by reference in the \c error parameter. If the directory
/// contains no entries, this method will return the empty array. When an array is specified for
/// the \c keys parameter, the specified property values will be pre-fetched and cached with each
/// enumerated \c URL. This method should always do a shallow enumeration of the specified
/// directory (i.e. it always acts as if \c NSDirectoryEnumerationSkipsSubdirectoryDescendants has
/// been specified). If you wish to only receive the \c URLs and no other attributes, then pass \c 0
/// for \c options and an empty \c NSArray for \c keys. If you wish to have the property caches of
/// the vended \c URLs pre-populated with a default set of attributes, then pass \c 0 for \c options
/// and \c nil for \c keys. For a list of keys you can specify, see
/// https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSURL_Class/index.html#//apple_ref/doc/constant_group/Common_File_System_Resource_Keys
- (nullable NSArray<NSURL *> *)contentsOfDirectoryAtURL:(NSURL *)url
                             includingPropertiesForKeys:(nullable NSArray<NSString *> *)keys
                                                options:(NSDirectoryEnumerationOptions)mask
                                                  error:(NSError *_Nullable *)error;

/// \c YES if \c path is a path to an existing file. File at \c path is a directory file if both the
/// return value and \c isDirectory are \c YES.
- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(nullable BOOL *)isDirectory;

@end

NS_ASSUME_NONNULL_END
