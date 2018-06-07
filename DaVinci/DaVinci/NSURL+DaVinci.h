// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting the \c NSURL class with convenience methods for creation of URLs specific to
/// DaVinci. In particular, the category adds methods for creation of URLs determining certain
/// texture instances, so-called "texture URLs". The texture instances can be used by instances of
/// \c DVNBrushModel subclasses.
@interface NSURL (DaVinci)

/// Scheme used for all URLs specific to DaVinci.
+ (NSString *)dvn_scheme;

/// URL for the source texture.
+ (NSURL *)dvn_urlOfSourceTexture;

/// URL for the edge avoidance texture.
+ (NSURL *)dvn_urlOfEdgeAvoidanceTexture;

/// URL for a 1x1 single-channel white texture.
+ (NSURL *)dvn_urlOfOneByOneWhiteSingleChannelByteTexture;

/// URL for a 1x1 RGBA white texture.
+ (NSURL *)dvn_urlOfOneByOneWhiteNonPremultipliedRGBAByteTexture;

@end

NS_ASSUME_NONNULL_END
