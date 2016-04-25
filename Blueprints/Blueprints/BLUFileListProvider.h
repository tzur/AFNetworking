// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@class BLUNode, NSFileManager;

/// Class that provides a \c BLUNodeCollection where each node in it represents a file in the file
/// system that matches the search criteria given by the client. For each such file, a given mapping
/// block is applied to convert its file path to a \c BLUNode.
@interface BLUFileListProvider : NSObject

/// Block that maps a \c filePath to a node.
typedef BLUNode * _Nonnull(^BLUFileListProviderMappingBlock)(NSString *filePath);

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a \c fileManager and a \c mappingBlock that maps matching file paths to
/// \c BLUNode object. The block is retained by this object and by signals returned from it.
- (instancetype)initWithFileManager:(NSFileManager *)fileManager
                       mappingBlock:(BLUFileListProviderMappingBlock)mappingBlock
    NS_DESIGNATED_INITIALIZER;

/// Returns a signal of \c BLUNodeCollection that represent files in \c baseDirectory whose names
/// matches the given \c predicate. The given \c predicate is evaluated on an \c NSString of the
/// file name that is being matched. The signal then completes. If \c recursively is \c YES, the
/// directory will be searched recursively.
///
/// If an error occurred while searching the directory, the signal will err.
- (RACSignal *)nodesForFilesInBaseDirectory:(NSString *)baseDirectory
                                recursively:(BOOL)recursively
                                  predicate:(NSPredicate *)predicate;

@end

NS_ASSUME_NONNULL_END
