// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheFakeCacheAwareAssetManager.h"

#import "PTNDescriptor.h"
#import "PTNImageFetchOptions.h"
#import "PTNResizingStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNCacheFakeCacheAwareAssetManager ()

/// Object responsible for supplying canonical URLs for image request parameters.
@property (readonly, nonatomic) id canonicalURLManager;

/// Mapping of \c <PTNImageRequest *, NSString *> pairs to the \c RACSubject returned for an image
/// asset validation request with that \c PTNImageRequest and entity tag pair.
@property (readonly, nonatomic) NSMapTable<RACTuple *, RACSubject *> *imageValidationRequests;

/// Mapping of \c <NSURL *, NSString *> pairs to the \c RACSubject returned for an asset validation
/// request with that URL and entity tag pair.
@property (readonly, nonatomic) NSMutableDictionary<RACTuple *, RACSubject *>
    *descriptorValidationRequests;

/// Mapping of \c <NSURL *, NSString *> pairs to the \c RACSubject returned for an album validation
/// request with that URL and entity tag pair.
@property (readonly, nonatomic) NSMutableDictionary<RACTuple *, RACSubject *>
    *albumValidationRequests;

@end

@implementation PTNCacheFakeCacheAwareAssetManager

- (instancetype)init {
  if (self = [super init]) {
    _canonicalURLManager = OCMProtocolMock(@protocol(PTNCacheAwareAssetManager));
    _imageValidationRequests = [NSMapTable strongToStrongObjectsMapTable];
    _descriptorValidationRequests = [NSMutableDictionary dictionary];
    _albumValidationRequests = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark -
#pragma mark PTNCacheAwarreAssetManager
#pragma mark -

- (RACSignal *)validateAlbumWithURL:(NSURL *)url entityTag:(nullable NSString *)entityTag {
  RACTuple *urlWithEtag = RACTuplePack(url, entityTag);

  if (!self.albumValidationRequests[urlWithEtag]) {
    self.albumValidationRequests[urlWithEtag] = [RACSubject subject];
  }

  return self.albumValidationRequests[urlWithEtag];
}

- (RACSignal *)validateDescriptorWithURL:(NSURL *)url entityTag:(nullable NSString *)entityTag {
  RACTuple *urlWithEtag = RACTuplePack(url, entityTag);

  if (!self.descriptorValidationRequests[urlWithEtag]) {
    self.descriptorValidationRequests[urlWithEtag] = [RACSubject subject];
  }

  return self.descriptorValidationRequests[urlWithEtag];
}

- (RACSignal *)validateImageWithDescriptor:(id<PTNDescriptor>)descriptor
                          resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                   options:(PTNImageFetchOptions *)options
                                 entityTag:(nullable NSString *)entityTag {
  PTNImageRequest *request = [[PTNImageRequest alloc] initWithDescriptor:descriptor
                                                        resizingStrategy:resizingStrategy
                                                                 options:options];
  RACTuple *requestWithEtag = RACTuplePack(request, entityTag);

  if (![self.imageValidationRequests objectForKey:requestWithEtag]) {
    [self.imageValidationRequests setObject:[RACSubject subject] forKey:requestWithEtag];
  }

  return [self.imageValidationRequests objectForKey:requestWithEtag];
}

- (nullable NSURL *)canonicalURLForDescriptor:(id<PTNDescriptor>)descriptor
                             resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                      options:(PTNImageFetchOptions *)options {
  return [self.canonicalURLManager canonicalURLForDescriptor:descriptor
                                            resizingStrategy:resizingStrategy
                                                     options:options];
}

#pragma mark -
#pragma mark Canonical URL
#pragma mark -

- (void)setCanonicalURL:(NSURL *)url forImageRequest:(PTNImageRequest *)request {
  OCMStub([self.canonicalURLManager canonicalURLForDescriptor:request.descriptor ?: OCMOCK_ANY
      resizingStrategy:request.resizingStrategy ?: OCMOCK_ANY
      options:request.options ?: OCMOCK_ANY]).andReturn(url);
}

#pragma mark -
#pragma mark Image Serving
#pragma mark -

- (void)serveValidateImageWithRequest:(PTNImageRequest *)request entityTag:(NSString *)etag
                         withValidity:(BOOL)valid {
  NSArray<RACSubject *> *matchingValidationRequests =
      [self validationRequestsMatchingImageRequest:request entityTag:etag];
  for (RACSubject *subject in matchingValidationRequests) {
    [subject sendNext:@(valid)];
    [subject sendCompleted];
  }
}

- (NSArray<RACSubject *> *)validationRequestsMatchingImageRequest:(PTNImageRequest *)imageRequest
                                                        entityTag:(NSString *)etag {
  return [[[self.imageValidationRequests.keyEnumerator.rac_sequence
      reduceEach:^id(PTNImageRequest *request, NSString __unused *etag) {
        return request;
      }]
      filter:^BOOL(PTNImageRequest *request) {
        return (imageRequest.descriptor == nil ||
            [imageRequest.descriptor isEqual:request.descriptor]) &&
            (imageRequest.resizingStrategy == nil ||
            [imageRequest.resizingStrategy isEqual:request.resizingStrategy]) &&
            (imageRequest.options == nil ||
            [imageRequest.options isEqual:request.options]);
      }]
      map:^id(PTNImageRequest *request) {
        return [self.imageValidationRequests objectForKey:RACTuplePack(request, etag)];
      }].array;
}

#pragma mark -
#pragma mark Album Serving
#pragma mark -

- (void)serveValidateAlbumWithURL:(NSURL *)url entityTag:(NSString *)etag withValidity:(BOOL)valid {
  RACSubject *subject = self.albumValidationRequests[RACTuplePack(url, etag)];
  [subject sendNext:@(valid)];
  [subject sendCompleted];
}

#pragma mark -
#pragma mark Descriptor Serving
#pragma mark -

- (void)serveValidateDescriptorWithURL:(NSURL *)url entityTag:(NSString *)etag
                          withValidity:(BOOL)valid {
  RACSubject *subject = self.descriptorValidationRequests[RACTuplePack(url, etag)];
  [subject sendNext:@(valid)];
  [subject sendCompleted];
}

@end

NS_ASSUME_NONNULL_END
