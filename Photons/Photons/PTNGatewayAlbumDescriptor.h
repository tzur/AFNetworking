// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/// Album descriptor for a gateway album. The gateway album is used to describe virtual album with a
/// custom localized title and image, referencing another album when fetched.
@interface PTNGatewayAlbumDescriptor : NSObject <PTNAlbumDescriptor>

/// Initializes with \c identifier as the \c ptn_identifier of this descriptor, \c localizedTitle,
/// \c image as a static image representing this descriptor's proxied album and \c albumSignal as
/// the signal that returns the proxied album.
///
/// @note \c identifier must be a valid Gateway URL.
- (instancetype)initWithIdentifier:(NSURL *)identifier localizedTitle:(NSString *)localizedTitle
                             image:(UIImage *)image albumSignal:(RACSignal *)albumSignal;

/// Image of album associated with this descriptor.
@property (readonly, nonatomic) UIImage *image;

/// Signal of album proxied by this gateway descriptor.
@property (readonly, nonatomic) RACSignal *albumSignal;

@end

NS_ASSUME_NONNULL_END
