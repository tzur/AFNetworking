// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFakeAssetManager.h"

#import <LTKit/NSArray+Functional.h>

#import "PTNAlbumChangeset.h"
#import "PTNDescriptor.h"
#import "PTNImageAsset.h"
#import "PTNImageFetchOptions.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"
#import "PTNVideoAsset.h"
#import "PTNVideoFetchOptions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNImageRequest

/// Initializes with \c descriptor, \c resizingStrategy and \c options.
- (instancetype)initWithDescriptor:(nullable id<PTNDescriptor>)descriptor
                  resizingStrategy:(nullable id<PTNResizingStrategy>)resizingStrategy
                           options:(nullable PTNImageFetchOptions *)options {
  if (self = [super init]) {
    _descriptor = descriptor;
    _resizingStrategy = resizingStrategy;
    _options = options;
  }
  return self;
}

@end

@implementation PTNVideoRequest

- (instancetype)initWithDescriptor:(nullable id<PTNDescriptor>)descriptor
                           options:(nullable PTNVideoFetchOptions *)options {
  if (self = [super init]) {
    _descriptor = descriptor;
    _options = options;
  }
  return self;
}

@end

@interface PTNFakeAssetManager ()

/// Mapping of \c PTNImageRequest to the \c RACSubject returned for an image request with those
/// parameters.
@property (readonly, nonatomic) NSMapTable<PTNImageRequest *, RACSubject *> *imageRequests;

/// Mapping of \c PTNVideoRequest to the \c RACSubject returned for a video request with those
/// parameters.
@property (readonly, nonatomic) NSMapTable<PTNVideoRequest *, RACSubject *> *videoRequests;

/// Mapping of \c NSURL to the \c RACSubject returned an asset request with that url.
@property (readonly, nonatomic) NSMutableDictionary<NSURL *, RACSubject *> *descriptorRequests;

/// Mapping of \c NSURL to the \c RACSubject returned an album request with that url.
@property (readonly, nonatomic) NSMutableDictionary<NSURL *, RACSubject *> *albumRequests;

@end

@implementation PTNFakeAssetManager

- (instancetype)init {
  if (self = [super init]) {
    _imageRequests = [NSMapTable strongToStrongObjectsMapTable];
    _videoRequests = [NSMapTable strongToStrongObjectsMapTable];
    _descriptorRequests = [NSMutableDictionary dictionary];
    _albumRequests = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark -
#pragma mark PTNAssetManager
#pragma mark -

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  if (!self.albumRequests[url]) {
    self.albumRequests[url] = [RACSubject subject];
  }

  return self.albumRequests[url];
}

- (RACSignal *)fetchDescriptorWithURL:(NSURL *)url {
  if (!self.descriptorRequests[url]) {
    self.descriptorRequests[url] = [RACSubject subject];
  }

  return self.descriptorRequests[url];
}

- (RACSignal *)fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
                       resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                options:(PTNImageFetchOptions *)options {
  PTNImageRequest *request = [[PTNImageRequest alloc] initWithDescriptor:descriptor
                                                        resizingStrategy:resizingStrategy
                                                                 options:options];
  if (![self.imageRequests objectForKey:request]) {
    [self.imageRequests setObject:[RACSubject subject] forKey:request];
  }

  return [self.imageRequests objectForKey:request];
}

- (RACSignal *)fetchVideoWithDescriptor:(id<PTNDescriptor>)descriptor
                                options:(PTNVideoFetchOptions *)options {
  PTNVideoRequest *request = [[PTNVideoRequest alloc] initWithDescriptor:descriptor
                                                                 options:options];
  if (![self.videoRequests objectForKey:request]) {
    [self.videoRequests setObject:[RACSubject subject] forKey:request];
  }

  return [self.videoRequests objectForKey:request];
}

#pragma mark -
#pragma mark Image Serving
#pragma mark -

- (void)serveImageRequest:(PTNImageRequest *)imageRequest
             withProgress:(NSArray<NSNumber *> *)progress imageAsset:(id<PTNImageAsset>)imageAsset {
  NSArray *progressObjects = [[progress.rac_sequence map:^id(NSNumber *progressValue) {
    return [[PTNProgress alloc] initWithProgress:progressValue];
  }].array arrayByAddingObject:[[PTNProgress alloc] initWithResult:imageAsset]];

  [self serveImageRequest:imageRequest withProgressObjects:progressObjects];
}

- (void)serveImageRequest:(PTNImageRequest *)imageRequest
             withProgress:(NSArray<NSNumber *> *)progress finallyError:(NSError *)error {
  NSArray *progressObjects = [progress.rac_sequence map:^id(NSNumber *progressValue) {
    return [[PTNProgress alloc] initWithProgress:progressValue];
  }].array;

  [self serveImageRequest:imageRequest withProgressObjects:progressObjects finallyError:error];
}

- (void)serveImageRequest:(PTNImageRequest *)imageRequest
      withProgressObjects:(NSArray<PTNProgress *> *)progress {
  [self serveImageRequest:imageRequest withProgressObjects:progress then:nil];
}

- (void)serveImageRequest:(PTNImageRequest *)imageRequest
      withProgressObjects:(NSArray<PTNProgress *> *)progress finallyError:(NSError *)error {
  [self serveImageRequest:imageRequest withProgressObjects:progress then:error];
}

- (void)serveImageRequest:(PTNImageRequest *)imageRequest
      withProgressObjects:(NSArray<PTNProgress *> *)progress then:(nullable NSError *)error {
  for (RACSubject *signal in [self requestsMatchingImageRequest:imageRequest]) {
    for (PTNProgress *progressObject in progress) {
      [signal sendNext:progressObject];
    }

    if (error) {
      [signal sendError:error];
    } else {
      [signal sendCompleted];
    }
  }
}

- (NSArray<RACSubject *> *)requestsMatchingImageRequest:(PTNImageRequest *)imageRequest {
  return [[self.imageRequests.keyEnumerator.rac_sequence
      filter:^BOOL(PTNImageRequest *request) {
        return (imageRequest.descriptor == nil ||
            [imageRequest.descriptor isEqual:request.descriptor]) &&
            (imageRequest.resizingStrategy == nil ||
            [imageRequest.resizingStrategy isEqual:request.resizingStrategy]) &&
            (imageRequest.options == nil ||
            [imageRequest.options isEqual:request.options]);
      }]
      map:^id(PTNImageRequest *request) {
        return [self.imageRequests objectForKey:request];
      }].array;
}

#pragma mark -
#pragma mark Video Serving
#pragma mark -

- (void)serveVideoRequest:(PTNVideoRequest *)videoRequest
             withProgress:(NSArray<NSNumber *> *)progress videoAsset:(id<PTNVideoAsset>)videoAsset {
  NSArray *progressObjects = [[progress lt_map:^PTNProgress *(NSNumber *progressValue) {
    return [[PTNProgress alloc] initWithProgress:progressValue];
  }] arrayByAddingObject:[[PTNProgress alloc] initWithResult:videoAsset]];

  [self serveVideoRequest:videoRequest withProgressObjects:progressObjects then:nil];
}

- (void)serveVideoRequest:(PTNVideoRequest *)videoRequest
             withProgress:(NSArray<NSNumber *> *)progress finallyError:(NSError *)error {
  NSArray *progressObjects = [progress lt_map:^PTNProgress *(NSNumber *progressValue) {
    return [[PTNProgress alloc] initWithProgress:progressValue];
  }];

  [self serveVideoRequest:videoRequest withProgressObjects:progressObjects then:error];
}

- (void)serveVideoRequest:(PTNVideoRequest *)videoRequest
      withProgressObjects:(NSArray<PTNProgress *> *)progress then:(nullable NSError *)error {
  for (RACSubject *signal in [self requestsMatchingVideoRequest:videoRequest]) {
    for (PTNProgress *progressObject in progress) {
      [signal sendNext:progressObject];
    }

    if (error) {
      [signal sendError:error];
    } else {
      [signal sendCompleted];
    }
  }
}

- (NSArray<RACSubject *> *)requestsMatchingVideoRequest:(PTNVideoRequest *)videoRequest {
  return [[self.videoRequests.keyEnumerator.rac_sequence
      filter:^BOOL(PTNVideoRequest *request) {
        return (videoRequest.descriptor == nil ||
            [videoRequest.descriptor isEqual:request.descriptor]) &&
            (videoRequest.options == nil ||
            [videoRequest.options isEqual:request.options]);
      }]
      map:^RACSubject *(PTNVideoRequest *request) {
        return [self.videoRequests objectForKey:request];
      }].array;
}

#pragma mark -
#pragma mark Descriptor Serving
#pragma mark -

- (void)serveDescriptorURL:(NSURL *)url withDescriptor:(id<PTNDescriptor>)descriptor {
  [self.descriptorRequests[url] sendNext:descriptor];
}

- (void)serveDescriptorURL:(NSURL *)url withError:(NSError *)error {
  [self.descriptorRequests[url] sendError:error];
}

#pragma mark -
#pragma mark Album Serving
#pragma mark -

- (void)serveAlbumURL:(NSURL *)url withAlbum:(id<PTNAlbum>)album {
  [self serveAlbumURL:url withAlbumChangeset:[PTNAlbumChangeset changesetWithAfterAlbum:album]];
}

- (void)serveAlbumURL:(NSURL *)url withAlbumChangeset:(PTNAlbumChangeset *)albumChangeset {
  [self.albumRequests[url] sendNext:albumChangeset];
}

- (void)serveAlbumURL:(NSURL *)url withError:(NSError *)error {
  [self.albumRequests[url] sendError:error];
}

@end

NS_ASSUME_NONNULL_END
