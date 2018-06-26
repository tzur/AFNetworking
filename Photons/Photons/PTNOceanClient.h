// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <LTKit/LTPath.h>
#import <LTKit/LTValueObject.h>

#import "PTNProgress.h"

NS_ASSUME_NONNULL_BEGIN

@class AFHTTPSessionManager, FBRHTTPClient, LTPath, PTNOceanAssetDescriptor,
    PTNOceanAssetSearchResponse, PTNOceanAssetSource, PTNOceanAssetType;

/// Value class containing parameters for searching assets in Ocean.
@interface PTNOceanSearchParameters : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c type, \c source, \c phrase and \c page.
- (instancetype)initWithType:(PTNOceanAssetType *)type source:(PTNOceanAssetSource *)source
                      phrase:(NSString *)phrase page:(NSUInteger)page;

/// The type of the assets to search for.
@property (readonly, nonatomic) PTNOceanAssetType *type;

/// The Ocean source to search for assets in.
@property (readonly, nonatomic) PTNOceanAssetSource *source;

/// The search term to search for.
@property (readonly, nonatomic) NSString *phrase;

/// The page number of the search result. Pages of 1-based.
@property (readonly, nonatomic) NSUInteger page;

@end

/// Value class containing parameters for fetching assets descriptor in Ocean.
@interface PTNOceanAssetFetchParameters : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c type, \c source and \c identifier.
- (instancetype)initWithType:(PTNOceanAssetType *)type source:(PTNOceanAssetSource *)source
                  identifier:(NSString *)identifier;

/// The type of the assets to fetch.
@property (readonly, nonatomic) PTNOceanAssetType *type;

/// The source to fetch the asset descriptor from.
@property (readonly, nonatomic) PTNOceanAssetSource *source;

/// The identifier of the asset to fetch.
@property (readonly, nonatomic) NSString *identifier;

@end

/// Client for Ocean server, providing stock images and videos.
///
/// There are two ways to fetch assets descriptors from Ocean. The first is using the
/// \c searchWithParameters: methods, which returns the descriptors of the assets of the search
/// result. The second way is using the \c fetchAssetDescriptorWithParameters: method, which returns
/// the asset descriptor by using the identifier of the asset that was previously returned using
/// the search method.
///
/// The descriptors contain various URLs to concrete assets. In order to download them, this class
/// provides two methods: \c downloadDataWithURL: which downloads the data in-memory and returns it,
/// and \c downloadFileWithURL: which downloads the data to a temporary file and by that reducing
/// the memory footprint.
@interface PTNOceanClient : NSObject

/// Initializes with the default \c FBRHTTPClient for \c client. \c sessionManager is initialized
/// with background \c NSURLSessionConfiguration.
- (instancetype)init;

/// Initializes with \c oceanClient to handle data exchange with Ocean's server. \c dataClient to
/// fetch relatively small amount of data like image assets to \c NSData. Downloading files is done
/// with \c sessionManager, in order to enable downloading file in when the app is not in
/// foreground.
- (instancetype)initWithOceanClient:(FBRHTTPClient *)oceanClient
                         dataClient:(FBRHTTPClient *)dataClient
    sessionManager:(AFHTTPSessionManager *)sessionManager NS_DESIGNATED_INITIALIZER;

/// Searches for assets using the given \c parameters. The returned result represents a single page
/// of the search result.
///
/// The returned signal sends a single value on an arbitrary thread and completes. The signal errs
/// if an error occurs while searching.
- (RACSignal<PTNOceanAssetSearchResponse *> *)
    searchWithParameters:(PTNOceanSearchParameters *)parameters;

/// Fetches the asset descriptor of a single asset using the given \c parameters.
///
/// @note The result returned from  \c searchWithParameters: already contains the descriptors for
/// the assets in the search result.
///
/// The returned signal sends a single value on an arbitrary thread and completes. The signal errs
/// if an error occurs while fetching the asset descriptor.
- (RACSignal<PTNOceanAssetDescriptor *> *)
    fetchAssetDescriptorWithParameters:(PTNOceanAssetFetchParameters *)parameters;

/// Downloads the contents of the given \c URL and returns it as \c NSData and UTI string.
///
/// The returned signal sends \c PTNProgress objects on an arbitrary thread, completes once the
/// final result is sent and errs if an error occurred while downloading.
///
/// @note The UTI string is nullable.
- (RACSignal<PTNProgress<RACTwoTuple<NSData *, NSString *> *> *> *)downloadDataWithURL:(NSURL *)url;

/// Downloads the contents of the given \c URL to a temporary file and returns its path. The
/// temporary file guaranteed to exist until the app exits.
///
/// The returned signal sends \c PTNProgress objects on an arbitrary thread, completes once the
/// final result is sent and errs if an error occurred while downloading.
///
/// The returned path is in the temporary directory.
- (RACSignal<PTNProgress<LTPath *> *> *)downloadFileWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
