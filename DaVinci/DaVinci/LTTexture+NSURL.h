// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTTexture.h>

NS_ASSUME_NONNULL_BEGIN

@class LTImageLoader;

/// Category augmenting the \c LTTexture class with convenience methods for creation of textures
/// according to a given \c NSURL.
@interface LTTexture (NSURL)

/// Returns a texture retrieved or created according to the given \c url. If the \c url does not
/// specify a URL of the \c NSURL+DaVinci category for which an appropriate texture can be created,
/// the \c absoluteString of the given \c url is assumed to be a valid input string for the
/// \c imageNamed method of the given \c imageLoader which is then used to retrieve the image.
+ (nullable LTTexture *)dvn_textureForURL:(NSURL *)url imageLoader:(LTImageLoader *)imageLoader;

/// Returns a texture retrieved or created according to the given \c url.  If the \c url does not
/// specify a URL of the \c NSURL+DaVinci category for which an appropriate texture can be created,
/// the \c absoluteString of the given \c url is assumed to be a valid input string for the
/// \c imageNamed method of the \c sharedInstance of \c LTImageLoader which is then used to retrieve
/// the image.
+ (nullable LTTexture *)dvn_textureForURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
