// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

/// Mapping between an \c NSURL scheme and a \c PTNAssetManager that supports \c NSURL objects with
/// that scheme.
typedef NSDictionary<NSString *, id<PTNAssetManager>> PTNSchemeToManagerMap;

/// Asset manager that backs and multiplexes several other \c PTNAssetManager objects.
/// Multiplexing is done according to URL schemes. Any fetch requests to this asset manager are
/// forwarded to one of the internal asset managers in \c schemeToManagerMap according to the given
/// scheme mapping. Unsupported schemes will return an erroneous signal with the
/// \c PTNErrorCodeUnrecognizedURLScheme error code.
@interface PTNMultiplexerAssetManager : NSObject <PTNAssetManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c mapping mapping URL scheme to a \c PTNAssetManager instance that handles
/// that scheme.
- (instancetype)initWithSources:(PTNSchemeToManagerMap *)mapping NS_DESIGNATED_INITIALIZER;

/// Mapping between URL schemes this manager supports and the \c PTNAssetManagers that handle them.
@property (readonly, nonatomic) PTNSchemeToManagerMap *mapping;

@end

NS_ASSUME_NONNULL_END
