// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

@class LTPath;

NS_ASSUME_NONNULL_BEGIN

/// Protocol for asset that is represented by \c NSData, enabling fetching of data and writing it to
/// file.
@protocol PTNDataAsset <NSObject>

/// Fetches the data backed by this asset. The returned signal sends a single \c NSData object on an
/// arbitrary thread, and completes. If data can't be fetched the signal errs instead.
- (RACSignal<NSData *> *)fetchData;

/// Write the data backed by this asset to file at \c path using \c fileManager. The returned signal
/// completes once this asset's data has been written in its entirety. Writing is taking place on an
/// arbitrary thread. If data writing fails the signals errs instead.
- (RACSignal *)writeToFileAtPath:(LTPath *)path usingFileManager:(NSFileManager *)fileManager;

/// The uniform type identifier of the asset or \c nil if UTI was not specified.
///
/// @see https://developer.apple.com/library/content/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html
@property (readonly, nonatomic, nullable) NSString *uniformTypeIdentifier;

@end

NS_ASSUME_NONNULL_END
