// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDescriptor.h"
#import "PTNImageAsset.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNResizingStrategy;

@class PTNImageFetchOptions;

/// Block returning \c RACSignal sending \c PTNImageAsset based on the given \c resizingStrategy and
/// \c options.
typedef RACSignal * _Nonnull(^PTNGatewayImageSignalBlock)(id<PTNResizingStrategy> resizingStrategy,
                                                          PTNImageFetchOptions *options);

/// Album descriptor for a gateway album. The gateway album is used to describe virtual album with a
/// custom localized title and image, referencing another album when fetched. As a
/// \c PTNAlbumDescriptor the receiver supports no capabilites and has no traits.
@interface PTNGatewayAlbumDescriptor : NSObject <PTNAlbumDescriptor>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c identifier as the \c ptn_identifier of this descriptor, \c localizedTitle,
/// \c image as a static image representing this descriptor's proxied album and \c albumSignal as
/// the signal that returns the proxied album's \c PTNAlbumChangeset.
///
/// @note \c identifier must be a valid Gateway URL.
- (instancetype)initWithIdentifier:(NSURL *)identifier localizedTitle:(NSString *)localizedTitle
                             image:(UIImage *)image albumSignal:(RACSignal *)albumSignal;

/// Initializes with \c identifier as the \c ptn_identifier of this descriptor, \c localizedTitle,
/// \c imageSignal as a signal that returns a \c PTNImageAsset object representing this descriptor's
/// proxied album and \c albumSignal as the signal that returns the proxied album's
/// \c PTNAlbumChangeset.
///
/// @note \c identifier must be a valid Gateway URL.
- (instancetype)initWithIdentifier:(NSURL *)identifier localizedTitle:(NSString *)localizedTitle
                       imageSignal:(RACSignal *)imageSignal
                       albumSignal:(RACSignal *)albumSignal;

/// Initializes with \c identifier as the \c ptn_identifier of this descriptor, \c localizedTitle,
/// \c imageSignalBlock as a block returning a signal that returns a \c PTNImageAsset object
/// representing this descriptor's proxied album with the given \c resizingStrategy and \c options
/// and \c albumSignal as the signal that returns the proxied album's \c PTNAlbumChangeset.
///
/// @note \c identifier must be a valid Gateway URL.
- (instancetype)initWithIdentifier:(NSURL *)identifier localizedTitle:(NSString *)localizedTitle
                  imageSignalBlock:(PTNGatewayImageSignalBlock)imageSignalBlock
                       albumSignal:(RACSignal *)albumSignal NS_DESIGNATED_INITIALIZER;

/// Signal of image associated with this descriptor.
@property (readonly, nonatomic) PTNGatewayImageSignalBlock imageSignalBlock;

/// Signal of album proxied by this gateway descriptor.
@property (readonly, nonatomic) RACSignal *albumSignal;

@end

NS_ASSUME_NONNULL_END
