// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNDescriptor;

/// Mapping of Photons identifiers as \c NSURL objects to \c PTNDescriptor conforming objects.
typedef NSDictionary<NSURL *, id<PTNDescriptor>> PTNDescriptorMap;

/// Asset manager that backs and proxies an internal underlying \c PTNAssetManager while
/// intercepting given selected content and injecting other content in its place. An example use
/// case for this manager is to intercept descriptors of assets with active editing sessions,
/// replacing them with the descriptors of the edited sessions themselves.
///
/// @note This asset manager will send updates whenever an asset or album is updated in itself or
/// when the interception mapping is updated and the intercepted \c PTNDescriptor is in the
/// original asset or album fetch.
///
/// @note This asset manager supports all assets supported by its underlying asset manager and
/// proxies any additional unaltered methods from the \c PTNAssetManager protocol to it. Optional
/// methods are supported if supported by the underlying manager.
///
/// @note All intercepting assets in an interception mapping must be unique. Mapping multiple
/// descriptors to the same asset will result in undefined behavior.
@interface PTNInterceptingAssetManager : NSObject <PTNAssetManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c assetManager as the underlying \c PTNAssetManager to proxy and
/// \c interceptedDescriptors as a signal of \c PTNDescriptorMap objects that represent the latest
/// interception mapping. Errors on \c interceptedDescriptors are ignored and if it completes the
/// latest value will be used. \c assetManager must support operations on all of the \c NSURL
/// objects and \c PTNDescriptor objects sent by \c interceptedDescriptors.
- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager
              interceptedDescriptors:(RACSignal *)interceptedDescriptors NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
