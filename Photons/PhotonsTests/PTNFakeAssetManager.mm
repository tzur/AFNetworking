// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFakeAssetManager.h"

#import <AVFoundation/AVFoundation.h>
#import <LTKit/NSArray+Functional.h>

#import "PTNAVAssetFetchOptions.h"
#import "PTNAlbumChangeset.h"
#import "PTNAudiovisualAsset.h"
#import "PTNDescriptor.h"
#import "PTNImageAsset.h"
#import "PTNImageDataAsset.h"
#import "PTNImageFetchOptions.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"

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

@implementation PTNAVAssetRequest

- (instancetype)initWithDescriptor:(nullable id<PTNDescriptor>)descriptor
                           options:(nullable PTNAVAssetFetchOptions *)options {
  if (self = [super init]) {
    _descriptor = descriptor;
    _options = options;
  }
  return self;
}

@end

@implementation PTNImageDataRequest

- (instancetype)initWithAssetDescriptor:(nullable id<PTNDescriptor>)descriptor {
  if (self = [super init]) {
    _descriptor = descriptor;
  }
  return self;
}

@end

@implementation PTNAVPreviewRequest

- (instancetype)initWithDescriptor:(nullable id<PTNDescriptor>)descriptor
                           options:(nullable PTNAVAssetFetchOptions *)options {
  if (self = [super init]) {
    _descriptor = descriptor;
    _options = options;
  }
  return self;
}

@end

@implementation PTNAVDataRequest

- (instancetype)initWithDescriptor:(nullable id<PTNDescriptor>)descriptor {
  if (self = [super init]) {
    _descriptor = descriptor;
  }
  return self;
}

@end

@interface PTNFakeAssetManager ()

/// Mapping of \c PTNImageRequest to the \c RACSubject returned for an image request with those
/// parameters.
@property (readonly, nonatomic) NSMapTable<PTNImageRequest *, RACSubject *> *imageRequests;

/// Mapping of \c PTNAVAssetRequest to the \c RACSubject returned for a AVAsset request with those
/// parameters.
@property (readonly, nonatomic) NSMapTable<PTNAVAssetRequest *, RACSubject *> *avRequests;

/// Mapping of \c PTNAVPreviewRequest to the \c RACSubject returned for a AV preview request with
/// those parameters.
@property (readonly, nonatomic) NSMapTable<PTNAVPreviewRequest *, RACSubject *> *avPreviewRequests;

/// Mapping of \c PTNAVDataRequest to the \c RACSubject returned for a AV data request with
/// those parameters.
@property (readonly, nonatomic) NSMapTable<PTNAVDataRequest *, RACSubject *> *avDataRequests;

/// Mapping of \c PTNImageDataRequest to the \c RACSubject returned for a image data request with
/// those parameters.
@property (readonly, nonatomic) NSMapTable<PTNImageDataRequest *, RACSubject *> *imageDataRequests;

/// Mapping of \c NSURL to the \c RACSubject returned an asset request with that url.
@property (readonly, nonatomic) NSMutableDictionary<NSURL *, RACSubject *> *descriptorRequests;

/// Mapping of \c NSURL to the \c RACSubject returned an album request with that url.
@property (readonly, nonatomic) NSMutableDictionary<NSURL *, RACSubject *> *albumRequests;

@end

@implementation PTNFakeAssetManager

- (instancetype)init {
  if (self = [super init]) {
    _imageRequests = [NSMapTable strongToStrongObjectsMapTable];
    _avRequests = [NSMapTable strongToStrongObjectsMapTable];
    _avPreviewRequests = [NSMapTable strongToStrongObjectsMapTable];
    _avDataRequests = [NSMapTable strongToStrongObjectsMapTable];
    _imageDataRequests = [NSMapTable strongToStrongObjectsMapTable];
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

- (RACSignal *)fetchAVAssetWithDescriptor:(id<PTNDescriptor>)descriptor
                                  options:(PTNAVAssetFetchOptions *)options {
  PTNAVAssetRequest *request = [[PTNAVAssetRequest alloc] initWithDescriptor:descriptor
                                                                     options:options];
  if (![self.avRequests objectForKey:request]) {
    [self.avRequests setObject:[RACSubject subject] forKey:request];
  }

  return [self.avRequests objectForKey:request];
}

- (RACSignal *)fetchImageDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  PTNImageDataRequest *request =
      [[PTNImageDataRequest alloc] initWithAssetDescriptor:descriptor];
  if (![self.imageDataRequests objectForKey:request]) {
    [self.imageDataRequests setObject:[RACSubject subject] forKey:request];
  }

  return [self.imageDataRequests objectForKey:request];
}

- (RACSignal *)fetchAVPreviewWithDescriptor:(id<PTNDescriptor>)descriptor
                                    options:(PTNAVAssetFetchOptions *)options {
  PTNAVPreviewRequest *request = [[PTNAVPreviewRequest alloc] initWithDescriptor:descriptor
                                                                         options:options];
  if (![self.avPreviewRequests objectForKey:request]) {
    [self.avPreviewRequests setObject:[RACSubject subject] forKey:request];
  }

  return [self.avPreviewRequests objectForKey:request];
}

#pragma mark -
#pragma mark AV data fetching
#pragma mark -

- (RACSignal<PTNProgress<id<PTNAVDataAsset>> *>*)
    fetchAVDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  PTNAVDataRequest *request = [[PTNAVDataRequest alloc] initWithDescriptor:descriptor];
  if (![self.avDataRequests objectForKey:request]) {
    [self.avDataRequests setObject:[RACSubject subject] forKey:request];
  }

  return [self.avDataRequests objectForKey:request];
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
#pragma mark AVAsset Serving
#pragma mark -

- (void)serveAVAssetRequest:(PTNAVAssetRequest *)request
               withProgress:(NSArray<NSNumber *> *)progress
                 videoAsset:(id<PTNAudiovisualAsset>)videoAsset {
  NSArray *progressObjects = [[progress lt_map:^PTNProgress *(NSNumber *progressValue) {
    return [[PTNProgress alloc] initWithProgress:progressValue];
  }] arrayByAddingObject:[[PTNProgress alloc] initWithResult:videoAsset]];

  [self serveAVAssetRequest:request withProgressObjects:progressObjects then:nil];
}

- (void)serveAVAssetRequest:(PTNAVAssetRequest *)request
               withProgress:(NSArray<NSNumber *> *)progress finallyError:(NSError *)error {
  NSArray *progressObjects = [progress lt_map:^PTNProgress *(NSNumber *progressValue) {
    return [[PTNProgress alloc] initWithProgress:progressValue];
  }];

  [self serveAVAssetRequest:request withProgressObjects:progressObjects then:error];
}

- (void)serveAVAssetRequest:(PTNAVAssetRequest *)request
        withProgressObjects:(NSArray<PTNProgress *> *)progress then:(nullable NSError *)error {
  for (RACSubject *signal in [self requestsMatchingAVAssetRequest:request]) {
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

- (NSArray<RACSubject *> *)requestsMatchingAVAssetRequest:(PTNAVAssetRequest *)request {
  return [[self.avRequests.keyEnumerator.rac_sequence
      filter:^BOOL(PTNAVAssetRequest *r) {
        return (request.descriptor == nil ||
            [request.descriptor isEqual:r.descriptor]) &&
            (request.options == nil ||
            [request.options isEqual:r.options]);
      }]
      map:^RACSubject *(PTNAVAssetRequest *r) {
        return [self.avRequests objectForKey:r];
      }].array;
}

#pragma mark -
#pragma mark Image data serving
#pragma mark -

- (void)serveImageDataRequest:(PTNImageDataRequest *)imageDataRequest
                 withProgress:(NSArray<NSNumber *> *)progress
               imageDataAsset:(id<PTNImageDataAsset>)imageDataAsset {
  NSArray *progressObjects = [[progress lt_map:^PTNProgress *(NSNumber *progressValue) {
    return [[PTNProgress alloc] initWithProgress:progressValue];
  }] arrayByAddingObject:[[PTNProgress alloc] initWithResult:imageDataAsset]];

  [self serveImageDataRequest:imageDataRequest withProgressObjects:progressObjects then:nil];
}

- (void)serveImageDataRequest:(PTNImageDataRequest *)imageDataRequest
                 withProgress:(NSArray<NSNumber *> *)progress finallyError:(NSError *)error {
  NSArray *progressObjects = [progress lt_map:^PTNProgress *(NSNumber *progressValue) {
    return [[PTNProgress alloc] initWithProgress:progressValue];
  }];

  [self serveImageDataRequest:imageDataRequest withProgressObjects:progressObjects then:error];
}

- (void)serveImageDataRequest:(PTNImageDataRequest *)imageDataRequest
          withProgressObjects:(NSArray<PTNProgress *> *)progress then:(nullable NSError *)error {
  for (RACSubject *signal in [self requestsMatchingImageDataRequest:imageDataRequest]) {
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

- (NSArray<RACSubject *> *)requestsMatchingImageDataRequest:
    (PTNImageDataRequest *)imageDataRequest {
  return [[self.imageDataRequests.keyEnumerator.rac_sequence
    filter:^BOOL(PTNImageDataRequest *request) {
      return (imageDataRequest.descriptor == nil ||
              [imageDataRequest.descriptor isEqual:request.descriptor]);
    }]
    map:^RACSubject *(PTNImageDataRequest *request) {
      return [self.imageDataRequests objectForKey:request];
    }].array;
}

#pragma mark -
#pragma mark AV preview serving
#pragma mark -

- (void)serveAVPreviewRequest:(PTNAVPreviewRequest *)request
                 withProgress:(NSArray<NSNumber *> *)progress
                   playerItem:(AVPlayerItem *)playerItem {
  NSArray *progressObjects = [[progress lt_map:^PTNProgress *(NSNumber *progressValue) {
    return [[PTNProgress alloc] initWithProgress:progressValue];
  }] arrayByAddingObject:[[PTNProgress alloc] initWithResult:playerItem]];

  [self serveAVPreviewAssetRequest:request withProgressObjects:progressObjects then:nil];
}

- (void)serveAVPreviewRequest:(PTNAVPreviewRequest *)request
                 withProgress:(NSArray<NSNumber *> *)progress finallyError:(NSError *)error {
  NSArray *progressObjects = [progress lt_map:^PTNProgress *(NSNumber *progressValue) {
    return [[PTNProgress alloc] initWithProgress:progressValue];
  }];

  [self serveAVPreviewAssetRequest:request withProgressObjects:progressObjects then:error];

}

- (void)serveAVPreviewAssetRequest:(PTNAVPreviewRequest *)request
               withProgressObjects:(NSArray<PTNProgress *> *)progress
                              then:(nullable NSError *)error {
  for (RACSubject *signal in [self requestsMatchingAVPreviewRequest:request]) {
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

- (NSArray<RACSubject *> *)requestsMatchingAVPreviewRequest:(PTNAVPreviewRequest *)previewRequest {
  return [[self.avPreviewRequests.keyEnumerator.rac_sequence
      filter:^BOOL(PTNAVPreviewRequest *request) {
        return (previewRequest.descriptor == nil ||
            [previewRequest.descriptor isEqual:request.descriptor]) &&
            (previewRequest.options == nil ||
            [previewRequest.options isEqual:request.options]);
      }]
      map:^RACSubject *(PTNAVPreviewRequest *request) {
        return [self.avPreviewRequests objectForKey:request];
      }].array;
}

#pragma mark -
#pragma mark AV data serving
#pragma mark -

- (void)serveAVDataRequest:(PTNAVDataRequest *)avDataRequest
              withProgress:(NSArray<NSNumber *> *)progress
               avDataAsset:(id<PTNAVDataAsset>)avDataAsset {
  NSArray *progressObjects = [[progress lt_map:^PTNProgress *(NSNumber *progressValue) {
    return [[PTNProgress alloc] initWithProgress:progressValue];
  }] arrayByAddingObject:[[PTNProgress alloc] initWithResult:avDataAsset]];

  [self serveAVDataRequest:avDataRequest withProgressObjects:progressObjects then:nil];
}

- (void)serveAVDataRequest:(PTNAVDataRequest *)avDataRequest
              withProgress:(NSArray<NSNumber *> *)progress finallyError:(NSError *)error {
  NSArray *progressObjects = [progress lt_map:^PTNProgress *(NSNumber *progressValue) {
    return [[PTNProgress alloc] initWithProgress:progressValue];
  }];

  [self serveAVDataRequest:avDataRequest withProgressObjects:progressObjects then:error];
}

- (void)serveAVDataRequest:(PTNAVDataRequest *)avDataRequest
       withProgressObjects:(NSArray<PTNProgress *> *)progress then:(nullable NSError *)error {
  for (RACSubject *signal in [self requestsMatchingAVDataRequest:avDataRequest]) {
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

- (NSArray<RACSubject *> *)requestsMatchingAVDataRequest:(PTNAVDataRequest *)avDataRequest {
  return [[self.avDataRequests.keyEnumerator.rac_sequence
    filter:^BOOL(PTNAVDataRequest *request) {
      return (avDataRequest.descriptor == nil ||
              [avDataRequest.descriptor isEqual:request.descriptor]);
    }]
    map:^RACSubject *(PTNAVDataRequest *request) {
      return [self.avDataRequests objectForKey:request];
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
