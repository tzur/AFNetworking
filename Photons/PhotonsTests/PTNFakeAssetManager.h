// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAlbum, PTNImageAsset, PTNImageDataAsset, PTNVideoAsset;

@class PTNAlbumChangeset, PTNImageFetchOptions, PTNProgress, PTNVideoFetchOptions;

/// Value object representing an image request with all of the required parameters for it.
@interface PTNImageRequest : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c descriptor, \c resizingStrategy and \c options.
- (instancetype)initWithDescriptor:(nullable id<PTNDescriptor>)descriptor
                  resizingStrategy:(nullable id<PTNResizingStrategy>)resizingStrategy
                           options:(nullable PTNImageFetchOptions *)options
    NS_DESIGNATED_INITIALIZER;

/// Descriptor used for the image request.
@property (readonly, nonatomic, nullable) id<PTNDescriptor> descriptor;

/// Resizing stategy used for the image request.
@property (readonly, nonatomic, nullable) id<PTNResizingStrategy> resizingStrategy;

/// Fetch options used for the image request.
@property (readonly, nonatomic, nullable) PTNImageFetchOptions *options;

@end

/// Value object representing a video request with all of the required parameters for it.
@interface PTNVideoRequest : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c descriptor and \c options.
- (instancetype)initWithDescriptor:(nullable id<PTNDescriptor>)descriptor
                           options:(nullable PTNVideoFetchOptions *)options
    NS_DESIGNATED_INITIALIZER;

/// Descriptor used for the video request.
@property (readonly, nonatomic, nullable) id<PTNDescriptor> descriptor;

/// Fetch options used for the video request.
@property (readonly, nonatomic, nullable) PTNVideoFetchOptions *options;

@end

/// Value object representing an image data request with the required parameter for it.
@interface PTNImageDataRequest : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c descriptor.
- (instancetype)initWithAssetDescriptor:(nullable id<PTNDescriptor>)descriptor
    NS_DESIGNATED_INITIALIZER;

/// Descriptor used for the image data request.
@property (readonly, nonatomic, nullable) id<PTNDescriptor> descriptor;

@end

/// Fake \c PTNAssetManager implementation used for testing.
@interface PTNFakeAssetManager : NSObject <PTNAssetManager>

#pragma mark -
#pragma mark Image Serving
#pragma mark -

/// Serves the given \c imageRequest by sending the given \c progress reports (array of \c NSNumber
/// values), followed by the given \c imageAsset, all wrapped in a \c PTNProgress objects and then
/// completes. If any properties of \c imageRequest are \c nil, that property will be treated as a
/// wildcard, matching all values from that property.
- (void)serveImageRequest:(PTNImageRequest *)imageRequest
             withProgress:(NSArray<NSNumber *> *)progress imageAsset:(id<PTNImageAsset>)imageAsset;

/// Serves the given \c imageRequest by sending the given \c progress reports (array of \c NSNumber
/// values) all wrapped in a \c PTNProgress objects, and finally the given \c error. If any
/// properties of \c imageRequest are \c nil, that property will be treated as a wildcard, matching
/// all values from that property.
- (void)serveImageRequest:(PTNImageRequest *)imageRequest
             withProgress:(NSArray<NSNumber *> *)progress finallyError:(NSError *)error;

/// Serves the given \c imageRequest by sending the given \c progress reports (array of
/// \c PTNProgress objects) and completes. If any properties of \c imageRequest are \c nil, that
/// property will be treated as a wildcard, matching all values from that property.
- (void)serveImageRequest:(PTNImageRequest *)imageRequest
      withProgressObjects:(NSArray<PTNProgress *> *)progress;

/// Serves the given \c imageRequest by sending the given \c progress reports (array of
/// \c PTNProgress objects) and finally the given \c error. If any properties of \c imageRequest are
/// \c nil, that property will be treated as a wildcard, matching all values of that property.
- (void)serveImageRequest:(PTNImageRequest *)imageRequest
      withProgressObjects:(NSArray<PTNProgress *> *)progress finallyError:(NSError *)error;

#pragma mark -
#pragma mark Video Serving
#pragma mark -

/// Serves the given \c videoRequest by sending the given \c progress reports (array of \c NSNumber
/// values), followed by the given \c videoAsset, all wrapped in a \c PTNProgress objects and then
/// completes. If any properties of \c videoRequest are \c nil, that property will be treated as a
/// wildcard, matching all values from that property.
- (void)serveVideoRequest:(PTNVideoRequest *)videoRequest
             withProgress:(NSArray<NSNumber *> *)progress videoAsset:(id<PTNVideoAsset>)videoAsset;

/// Serves the given \c videoRequest by sending the given \c progress reports (array of \c NSNumber
/// values) all wrapped in a \c PTNProgress objects, and finally the given \c error. If any
/// properties of \c videoRequest are \c nil, that property will be treated as a wildcard, matching
/// all values from that property.
- (void)serveVideoRequest:(PTNVideoRequest *)videoRequest
             withProgress:(NSArray<NSNumber *> *)progress finallyError:(NSError *)error;

#pragma mark -
#pragma mark Image Data Serving
#pragma mark -

/// Serves the given \c imageDataRequest by sending the given \c progress reports (array of
/// \c NSNumber values), followed by the given \c imageDataRequest, all wrapped in a \c PTNProgress
/// objects and then completes. If any properties of \c imageDataRequest are \c nil, that property
/// will be treated as a wildcard, matching all values from that property.
- (void)serveImageDataRequest:(PTNImageDataRequest *)imageDataRequest
                 withProgress:(NSArray<NSNumber *> *)progress
               imageDataAsset:(id<PTNImageDataAsset>)imageDataAsset;

/// Serves the given \c imageDataRequest by sending the given \c progress reports (array of
/// \c NSNumber values) all wrapped in a \c PTNProgress objects, and finally the given \c error. If
/// any properties of \c imageDataRequest are \c nil, that property will be treated as a wildcard,
/// matching all values from that property.
- (void)serveImageDataRequest:(PTNImageDataRequest *)imageDataRequest
                 withProgress:(NSArray<NSNumber *> *)progress finallyError:(NSError *)error;

#pragma mark -
#pragma mark Descriptor Serving
#pragma mark -

/// Serves the descriptor requested with \c url with \c descriptor.
- (void)serveDescriptorURL:(NSURL *)url withDescriptor:(id<PTNDescriptor>)descriptor;

/// Serves the descriptor requested with \c url with \c error.
- (void)serveDescriptorURL:(NSURL *)url withError:(NSError *)error;

#pragma mark -
#pragma mark Album Serving
#pragma mark -

/// Serves the album requested with \c url with \c album as the \c afterAlbum of a
/// /c PTNAlbumChangeset object.
- (void)serveAlbumURL:(NSURL *)url withAlbum:(id<PTNAlbum>)album;

/// Serves the album requested with \c url with \c albumChangeset.
- (void)serveAlbumURL:(NSURL *)url withAlbumChangeset:(PTNAlbumChangeset *)albumChangeset;

/// Serves the album requested with \c url with \c error.
- (void)serveAlbumURL:(NSURL *)url withError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
