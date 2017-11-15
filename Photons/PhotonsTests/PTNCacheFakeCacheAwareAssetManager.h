// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheAwareAssetManager.h"
#import "PTNFakeAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

/// Extension of \c PTNFakeAssetManager that supports the added methods required by a
/// \c PTNCahceAwareAssetManager.
@interface PTNCacheFakeCacheAwareAssetManager : PTNFakeAssetManager <PTNCacheAwareAssetManager>

/// Sets \c url as the canonical URL representation of \c request. Default value is \c nil. If any
/// properties of \c imageRequest are \c nil, that property will be treated as a wildcard, matching
/// all values from that property.
- (void)setCanonicalURL:(NSURL *)url forImageRequest:(PTNImageRequest *)request;

/// Serves the all album validation requests made with given \c url and \c etag by sending the given
/// \c valid value and then completes.
- (void)serveValidateAlbumWithURL:(NSURL *)url entityTag:(NSString *)etag withValidity:(BOOL)valid;

/// Serves the all asset validation requests made with given \c url and \c etag by sending the given
/// \c valid value and then completes.
- (void)serveValidateDescriptorWithURL:(NSURL *)url entityTag:(NSString *)etag
                          withValidity:(BOOL)valid;

/// Serves the all image asset validation requests made with given \c request and \c etag by sending
/// the given \c valid value and then completes. If any properties of \c imageRequest are \c nil,
/// that property will be treated as a wildcard, matching all values from that property.
- (void)serveValidateImageWithRequest:(PTNImageRequest *)request
                            entityTag:(NSString *)etag withValidity:(BOOL)valid;

@end

NS_ASSUME_NONNULL_END
