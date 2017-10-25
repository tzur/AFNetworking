// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class LTPath;

@protocol BZRFileArchiver;

/// Manages the content of in-app store products. It provides methods to extract product's content
/// from downloaded archives, delete the content of products, ask whether a content of a product is
/// available and get URLs to content of products.
@interface BZRProductContentManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c fileManager and \c fileArchiver set to a new instance of
/// \c BZRZipFileArchiver.
///
/// @see initWithFileManager:fileArchiver:
- (instancetype)initWithFileManager:(NSFileManager *)fileManager;

/// Initializes with \c fileManager, used for interaction with files and directories, and with
/// \c fileArchiver, used to extract content archives.
- (instancetype)initWithFileManager:(NSFileManager *)fileManager
                       fileArchiver:(id<BZRFileArchiver>)fileArchiver NS_DESIGNATED_INITIALIZER;

/// Extracts the content from \c archivePath to the directory of the product specified by
/// \c productIdentifier and returns the path to the directory.
///
/// Returns a signal that creates a content directory for the product specified by
/// \c productIdentifier. If content already exists in the directory, it will be removed. After
/// creating the directory, it extracts the content from \c archivePath and sends the bundle that
/// points to the content directory if the extraction was successful. Then the signal completes.
/// The signal errs if there was an error while removing the old directory, creating the directory
/// or extracting the content from the archive file.
- (RACSignal<NSBundle *> *)extractContentOfProduct:(NSString *)productIdentifier
                                       fromArchive:(LTPath *)archivePath;

/// Extracts the content from \c archivePath to a directory named \c directoryName within the
/// directory of the product specified by \c productIdentifier.
///
/// Returns a signal that has the same behavior as \c extractContentOfProduct:fromArchive:, but
/// extracts the content to a nested directory named \c directoryName.
- (RACSignal<NSBundle *> *)extractContentOfProduct:(NSString *)productIdentifier
                                       fromArchive:(LTPath *)archivePath
                                     intoDirectory:(NSString *)directoryName;

/// Deletes the content of a specific product.
///
/// Returns a signal that deletes the content of the product specified by \c productIdentifier, by
/// by removing the product's content directory and completes. The signal errs if the deletion has
/// failed.
- (RACSignal *)deleteContentDirectoryOfProduct:(NSString *)productIdentifier;

/// Returns the path to the content directory of product with the given \c productIdentifier or
/// \c nil if the content for that product does not exist.
- (nullable LTPath *)pathToContentDirectoryOfProduct:(NSString *)productIdentifier;

@end

NS_ASSUME_NONNULL_END
