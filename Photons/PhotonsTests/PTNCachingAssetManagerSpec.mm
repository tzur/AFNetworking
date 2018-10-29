// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCachingAssetManager.h"

#import <LTKit/LTProgress.h>

#import "NSURL+PTNCache.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNCacheAwareAssetManager.h"
#import "PTNCacheFakeCacheAwareAssetManager.h"
#import "PTNCacheInfo.h"
#import "PTNCacheProxy.h"
#import "PTNCacheResponse.h"
#import "PTNDataAssetCache.h"
#import "PTNDescriptor.h"
#import "PTNImageAsset.h"
#import "PTNImageFetchOptions.h"
#import "PTNIncrementalChanges.h"
#import "PTNResizingStrategy.h"
#import "PTNTestUtils.h"

SpecBegin(PTNCachingAssetManager)

__block id<PTNDataAssetCache> cache;
__block PTNCacheFakeCacheAwareAssetManager *underlyingAssetManager;
__block PTNCachingAssetManager *assetManager;
__block NSURL *url;
__block PTNCacheInfo *freshCacheInfo;
__block PTNCacheInfo *staleCacheInfo;

beforeEach(^{
  cache = OCMProtocolMock(@protocol(PTNDataAssetCache));
  underlyingAssetManager = [[PTNCacheFakeCacheAwareAssetManager alloc] init];

  assetManager = [[PTNCachingAssetManager alloc] initWithAssetManager:underlyingAssetManager
                                                                cache:cache];

  url = [NSURL URLWithString:@"http://www.foo.com"];
  freshCacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:1000 entityTag:@"fresh"];
  staleCacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:0 responseTime:[NSDate distantPast]
                                              entityTag:@"stale"];
});

context(@"asset fetching", ^{
  __block id<PTNDescriptor> descriptor;
  __block id<PTNDescriptor> cachedDescriptor;

  beforeEach(^{
    descriptor = PTNCreateDescriptor(url, nil, 0, nil);
    cachedDescriptor = PTNCreateDescriptor(nil, nil, 0, nil);
  });

  it(@"should return values from underlying asset manager when no cached value is available", ^{
    OCMStub([cache cachedDescriptorForURL:url]).andReturn([RACSignal return:nil]);
    LLSignalTestRecorder *values = [[assetManager fetchDescriptorWithURL:url] testRecorder];

    [underlyingAssetManager serveDescriptorURL:url withDescriptor:descriptor];

    expect(values).will.sendValues(@[descriptor]);
  });

  it(@"should forward errors from underlying asset manager when no cached value is available", ^{
    OCMStub([cache cachedDescriptorForURL:url]).andReturn([RACSignal return:nil]);
    LLSignalTestRecorder *values = [[assetManager fetchDescriptorWithURL:url] testRecorder];

    [underlyingAssetManager serveDescriptorURL:url withError:[NSError lt_errorWithCode:1337]];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == 1337;
    });
  });

  it(@"should return values from cache when fresh", ^{
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedDescriptor
                                                                        info:freshCacheInfo];
    OCMStub([cache cachedDescriptorForURL:url]).andReturn([RACSignal return:cacheResponse]);

    expect([assetManager fetchDescriptorWithURL:url]).will.sendValues(@[cachedDescriptor]);
  });

  it(@"should return values from underlying asset manager when cache errs", ^{
    OCMStub([cache cachedDescriptorForURL:url])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);

    LLSignalTestRecorder *values = [[assetManager fetchDescriptorWithURL:url] testRecorder];
    [underlyingAssetManager serveDescriptorURL:url withDescriptor:descriptor];

    expect(values).will.sendValues(@[descriptor]);
  });

  it(@"should validate cache responses when stale and fetch origin if invalid", ^{
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedDescriptor
                                                                        info:staleCacheInfo];
    OCMStub([cache cachedDescriptorForURL:url]).andReturn([RACSignal return:cacheResponse]);

    LLSignalTestRecorder *values = [[assetManager fetchDescriptorWithURL:url] testRecorder];
    [underlyingAssetManager serveValidateDescriptorWithURL:url entityTag:staleCacheInfo.entityTag
                                              withValidity:NO];
    [underlyingAssetManager serveDescriptorURL:url withDescriptor:descriptor];

    expect(values).will.sendValues(@[descriptor]);
  });

  it(@"should validate cache responses when stale and return them if valid", ^{
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedDescriptor
                                                                        info:staleCacheInfo];
    OCMStub([cache cachedDescriptorForURL:url]).andReturn([RACSignal return:cacheResponse]);

    LLSignalTestRecorder *values = [[assetManager fetchDescriptorWithURL:url] testRecorder];
    [underlyingAssetManager serveDescriptorURL:url withDescriptor:descriptor];
    [underlyingAssetManager serveValidateDescriptorWithURL:url entityTag:staleCacheInfo.entityTag
                                              withValidity:YES];

    expect(values).will.matchValue(0, ^BOOL(PTNCacheProxy *proxy) {
      return proxy.underlyingObject == cachedDescriptor &&
          proxy.cacheInfo.entityTag == staleCacheInfo.entityTag &&
          proxy.cacheInfo.maxAge == staleCacheInfo.maxAge &&
          ![proxy.cacheInfo.responseTime isEqual:staleCacheInfo.responseTime];
    });
  });

  it(@"should re-cache validated responses", ^{
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedDescriptor
                                                                        info:staleCacheInfo];
    OCMStub([cache cachedDescriptorForURL:url]).andReturn([RACSignal return:cacheResponse]);

    LLSignalTestRecorder *values = [[assetManager fetchDescriptorWithURL:url] testRecorder];
    [underlyingAssetManager serveValidateDescriptorWithURL:url entityTag:staleCacheInfo.entityTag
                                              withValidity:YES];

    expect(values).will.matchValue(0, ^BOOL(PTNCacheProxy *proxy) {
      return proxy.underlyingObject == cachedDescriptor &&
          proxy.cacheInfo.entityTag == staleCacheInfo.entityTag &&
          proxy.cacheInfo.maxAge == staleCacheInfo.maxAge &&
          ![proxy.cacheInfo.responseTime isEqual:staleCacheInfo.responseTime];
    });
    OCMVerify([cache storeDescriptor:cachedDescriptor withCacheInfo:OCMOCK_ANY forURL:url]);
  });

  it(@"should return stale responses when using PTNCachePolicyReturnCacheDataElseLoad", ^{
    NSURL *fetchStaleUrl =
        [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReturnCacheDataElseLoad)];
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedDescriptor
                                                                        info:staleCacheInfo];
    OCMStub([cache cachedDescriptorForURL:fetchStaleUrl])
        .andReturn([RACSignal return:cacheResponse]);

    expect([assetManager fetchDescriptorWithURL:fetchStaleUrl])
        .will.sendValues(@[cachedDescriptor]);
  });

  it(@"should return fresh responses when using PTNCachePolicyReturnCacheDataElseLoad", ^{
    NSURL *fetchFreshUrl =
        [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReturnCacheDataElseLoad)];
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedDescriptor
                                                                        info:freshCacheInfo];
    OCMStub([cache cachedDescriptorForURL:fetchFreshUrl])
        .andReturn([RACSignal return:cacheResponse]);

    expect([assetManager fetchDescriptorWithURL:fetchFreshUrl])
        .will.sendValues(@[cachedDescriptor]);
  });

  it(@"should return from origin when missing cache using PTNCachePolicyReturnCacheDataElseLoad", ^{
    NSURL *fetchMissingCacheUrl =
        [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReturnCacheDataElseLoad)];
    OCMStub([cache cachedDescriptorForURL:fetchMissingCacheUrl]).andReturn([RACSignal return:nil]);

    auto values = [[assetManager fetchDescriptorWithURL:fetchMissingCacheUrl] testRecorder];
    [underlyingAssetManager serveDescriptorURL:fetchMissingCacheUrl withDescriptor:descriptor];

    expect(values).will.sendValues(@[descriptor]);
  });

  it(@"should ignore cache when using PTNCachePolicyReloadIgnoringLocalCacheData", ^{
    NSURL *ignoreCacheUrl =
        [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReloadIgnoringLocalCacheData)];
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedDescriptor
                                                                        info:freshCacheInfo];
    OCMStub([cache cachedDescriptorForURL:ignoreCacheUrl])
        .andReturn([RACSignal return:cacheResponse]);

    LLSignalTestRecorder *values =
        [[assetManager fetchDescriptorWithURL:ignoreCacheUrl] testRecorder];
    [underlyingAssetManager serveValidateDescriptorWithURL:ignoreCacheUrl
                                                 entityTag:freshCacheInfo.entityTag
                                              withValidity:NO];
    [underlyingAssetManager serveDescriptorURL:ignoreCacheUrl withDescriptor:descriptor];

    expect(values).will.sendValues(@[descriptor]);
  });

  it(@"should ignore missing cache when using PTNCachePolicyReloadIgnoringLocalCacheData", ^{
    NSURL *ignoreCacheUrl =
        [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReloadIgnoringLocalCacheData)];
    OCMStub([cache cachedDescriptorForURL:ignoreCacheUrl]).andReturn([RACSignal return:nil]);

    LLSignalTestRecorder *values =
        [[assetManager fetchDescriptorWithURL:ignoreCacheUrl] testRecorder];
    [underlyingAssetManager serveValidateDescriptorWithURL:ignoreCacheUrl
                                                 entityTag:freshCacheInfo.entityTag
                                              withValidity:NO];
    [underlyingAssetManager serveDescriptorURL:ignoreCacheUrl withDescriptor:descriptor];

    expect(values).will.sendValues(@[descriptor]);
  });

  context(@"PTNCachePolicyReturnCacheDataThenLoad", ^{
    __block NSURL *fetchStaleUrl;

    beforeEach(^{
      fetchStaleUrl = [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReturnCacheDataThenLoad)];
      PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedDescriptor
                                                                          info:staleCacheInfo];
      OCMStub([cache cachedDescriptorForURL:fetchStaleUrl])
          .andReturn([RACSignal return:cacheResponse]);
    });

    it(@"should return cache response followed by an origin response", ^{
      LLSignalTestRecorder *values =
          [[assetManager fetchDescriptorWithURL:fetchStaleUrl] testRecorder];

      [underlyingAssetManager serveValidateDescriptorWithURL:fetchStaleUrl
                                                   entityTag:staleCacheInfo.entityTag
                                                withValidity:NO];
      PTNCacheProxy *descriptorWithInfo =
          [[PTNCacheProxy alloc] initWithUnderlyingObject:descriptor cacheInfo:freshCacheInfo];
      [underlyingAssetManager serveDescriptorURL:fetchStaleUrl
                                  withDescriptor:(id<PTNDescriptor>)descriptorWithInfo];

      expect(values).will.sendValues(@[
        cachedDescriptor,
        descriptorWithInfo
      ]);
      OCMVerify([cache storeDescriptor:descriptor withCacheInfo:freshCacheInfo
                                forURL:fetchStaleUrl]);
    });

     it(@"should return just a cache response when it's valid", ^{
      LLSignalTestRecorder *values =
           [[assetManager fetchDescriptorWithURL:fetchStaleUrl] testRecorder];

      [underlyingAssetManager serveValidateDescriptorWithURL:fetchStaleUrl
                                                   entityTag:staleCacheInfo.entityTag
                                                withValidity:YES];

      expect(values).will.sendValues(@[cachedDescriptor]);
    });

    it(@"should return just a cache response when the origin response is cache equivalent", ^{
      LLSignalTestRecorder *values =
          [[assetManager fetchDescriptorWithURL:fetchStaleUrl] testRecorder];

      [underlyingAssetManager serveValidateDescriptorWithURL:fetchStaleUrl
                                                   entityTag:staleCacheInfo.entityTag
                                                withValidity:NO];
      [underlyingAssetManager serveDescriptorURL:fetchStaleUrl withDescriptor:cachedDescriptor];

      expect(values).will.sendValues(@[cachedDescriptor]);
    });

    it(@"should deliver updates on the original signal", ^{
      LLSignalTestRecorder *values =
          [[assetManager fetchDescriptorWithURL:fetchStaleUrl] testRecorder];

      [underlyingAssetManager serveValidateDescriptorWithURL:fetchStaleUrl
                                                   entityTag:staleCacheInfo.entityTag
                                                withValidity:NO];
      [underlyingAssetManager serveDescriptorURL:fetchStaleUrl withDescriptor:cachedDescriptor];
      [underlyingAssetManager serveDescriptorURL:fetchStaleUrl withDescriptor:descriptor];

      expect(values).will.sendValues(@[cachedDescriptor, descriptor]);
    });
  });
});

context(@"album fetching", ^{
  __block id<PTNAlbum> album;
  __block id<PTNAlbum> cachedAlbum;
  __block PTNAlbumChangeset *albumChangeset;
  __block PTNAlbumChangeset *cachedAlbumChangeset;

  beforeEach(^{
    album = PTNCreateAlbum(url, nil, nil);
    cachedAlbum = PTNCreateAlbum(nil, nil, nil);
    albumChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
    cachedAlbumChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:cachedAlbum];
  });

  it(@"should return values from underlying asset manager when no cached value is available", ^{
    OCMStub([cache cachedAlbumForURL:url]).andReturn([RACSignal return:nil]);
    LLSignalTestRecorder *values = [[assetManager fetchAlbumWithURL:url] testRecorder];

    [underlyingAssetManager serveAlbumURL:url withAlbum:album];

    expect(values).will.sendValues(@[albumChangeset]);
  });

  it(@"should forward errors from underlying asset manager when no cached value is available", ^{
    OCMStub([cache cachedAlbumForURL:url]).andReturn([RACSignal return:nil]);
    LLSignalTestRecorder *values = [[assetManager fetchAlbumWithURL:url] testRecorder];

    [underlyingAssetManager serveAlbumURL:url withError:[NSError lt_errorWithCode:1337]];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == 1337;
    });
  });

  it(@"should return values from cache when fresh", ^{
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedAlbum
                                                                        info:freshCacheInfo];
    OCMStub([cache cachedAlbumForURL:url]).andReturn([RACSignal return:cacheResponse]);

    expect([assetManager fetchAlbumWithURL:url]).will.sendValues(@[cachedAlbumChangeset]);
  });

  it(@"should return values from underlying asset manager when cache errs", ^{
    OCMStub([cache cachedAlbumForURL:url])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);

    LLSignalTestRecorder *values = [[assetManager fetchAlbumWithURL:url] testRecorder];
    [underlyingAssetManager serveAlbumURL:url withAlbum:album];

    expect(values).will.sendValues(@[albumChangeset]);
  });

  it(@"should validate cache responses when stale and fetch origin if invalid", ^{
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedAlbum
                                                                        info:staleCacheInfo];
    OCMStub([cache cachedAlbumForURL:url]).andReturn([RACSignal return:cacheResponse]);

    LLSignalTestRecorder *values = [[assetManager fetchAlbumWithURL:url] testRecorder];
    [underlyingAssetManager serveValidateAlbumWithURL:url entityTag:staleCacheInfo.entityTag
                                         withValidity:NO];
    [underlyingAssetManager serveAlbumURL:url withAlbum:album];

    expect(values).will.sendValues(@[albumChangeset]);
  });

  it(@"should validate cache responses when stale and return them if valid", ^{
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedAlbum
                                                                        info:staleCacheInfo];
    OCMStub([cache cachedAlbumForURL:url]).andReturn([RACSignal return:cacheResponse]);

    LLSignalTestRecorder *values = [[assetManager fetchAlbumWithURL:url] testRecorder];
    [underlyingAssetManager serveAlbumURL:url withAlbum:album];
    [underlyingAssetManager serveValidateAlbumWithURL:url entityTag:staleCacheInfo.entityTag
                                         withValidity:YES];

    expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *changeset) {
      PTNCacheProxy<PTNAlbum> *proxy = changeset.afterAlbum;
      return proxy.underlyingObject == cachedAlbum &&
          proxy.cacheInfo.entityTag == staleCacheInfo.entityTag &&
          proxy.cacheInfo.maxAge == staleCacheInfo.maxAge &&
          ![proxy.cacheInfo.responseTime isEqual:staleCacheInfo.responseTime];
    });
  });

  it(@"should re-cache validated responses", ^{
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedAlbum
                                                                        info:staleCacheInfo];
    OCMStub([cache cachedAlbumForURL:url]).andReturn([RACSignal return:cacheResponse]);

    LLSignalTestRecorder *values = [[assetManager fetchAlbumWithURL:url] testRecorder];
    [underlyingAssetManager serveValidateAlbumWithURL:url entityTag:staleCacheInfo.entityTag
                                         withValidity:YES];

    expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *changeset) {
      PTNCacheProxy<id<PTNAlbum>> *proxy = changeset.afterAlbum;
      return proxy.underlyingObject == cachedAlbum &&
          proxy.cacheInfo.entityTag == staleCacheInfo.entityTag &&
          proxy.cacheInfo.maxAge == staleCacheInfo.maxAge &&
          ![proxy.cacheInfo.responseTime isEqual:staleCacheInfo.responseTime];
    });
    OCMVerify([cache storeAlbum:cachedAlbum withCacheInfo:OCMOCK_ANY forURL:url]);
  });

  it(@"should return stale responses when using PTNCachePolicyReturnCacheDataElseLoad", ^{
    NSURL *fetchStaleUrl =
        [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReturnCacheDataElseLoad)];
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedAlbum
                                                                        info:staleCacheInfo];
    OCMStub([cache cachedAlbumForURL:fetchStaleUrl])
        .andReturn([RACSignal return:cacheResponse]);

    expect([assetManager fetchAlbumWithURL:fetchStaleUrl]).will.sendValues(@[cachedAlbumChangeset]);
  });

  it(@"should return fresh responses when using PTNCachePolicyReturnCacheDataElseLoad", ^{
    NSURL *fetchFreshUrl =
        [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReturnCacheDataElseLoad)];
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedAlbum
                                                                        info:freshCacheInfo];
    OCMStub([cache cachedAlbumForURL:fetchFreshUrl])
        .andReturn([RACSignal return:cacheResponse]);

    expect([assetManager fetchAlbumWithURL:fetchFreshUrl]).will.sendValues(@[cachedAlbumChangeset]);
  });

  it(@"should return from origin when missing cache using PTNCachePolicyReturnCacheDataElseLoad", ^{
    NSURL *fetchMissingCacheUrl =
        [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReturnCacheDataElseLoad)];
    OCMStub([cache cachedAlbumForURL:fetchMissingCacheUrl]).andReturn([RACSignal return:nil]);

    auto values = [[assetManager fetchAlbumWithURL:fetchMissingCacheUrl] testRecorder];
    [underlyingAssetManager serveAlbumURL:fetchMissingCacheUrl withAlbum:album];

    expect(values).will.sendValues(@[albumChangeset]);
  });

  it(@"should ignore cache when using PTNCachePolicyReloadIgnoringLocalCacheData", ^{
    NSURL *ignoreCacheUrl =
      [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReloadIgnoringLocalCacheData)];
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedAlbum
                                                                        info:freshCacheInfo];
    OCMStub([cache cachedAlbumForURL:ignoreCacheUrl])
        .andReturn([RACSignal return:cacheResponse]);

    LLSignalTestRecorder *values = [[assetManager fetchAlbumWithURL:ignoreCacheUrl] testRecorder];
    [underlyingAssetManager serveValidateAlbumWithURL:ignoreCacheUrl
                                            entityTag:freshCacheInfo.entityTag withValidity:NO];
    [underlyingAssetManager serveAlbumURL:ignoreCacheUrl withAlbum:album];

    expect(values).will.sendValues(@[albumChangeset]);
  });

  it(@"should ignore missing cache when using PTNCachePolicyReloadIgnoringLocalCacheData", ^{
    NSURL *ignoreCacheUrl =
      [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReloadIgnoringLocalCacheData)];
    OCMStub([cache cachedAlbumForURL:ignoreCacheUrl])
        .andReturn([RACSignal return:nil]);

    LLSignalTestRecorder *values = [[assetManager fetchAlbumWithURL:ignoreCacheUrl] testRecorder];
    [underlyingAssetManager serveValidateAlbumWithURL:ignoreCacheUrl
                                            entityTag:freshCacheInfo.entityTag withValidity:NO];
    [underlyingAssetManager serveAlbumURL:ignoreCacheUrl withAlbum:album];

    expect(values).will.sendValues(@[albumChangeset]);
  });

  context(@"PTNCachePolicyReturnCacheDataThenLoad", ^{
    __block NSURL *fetchStaleUrl;

    beforeEach(^{
      fetchStaleUrl = [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReturnCacheDataThenLoad)];
      PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedAlbum
                                                                          info:staleCacheInfo];
      OCMStub([cache cachedAlbumForURL:fetchStaleUrl]).andReturn([RACSignal return:cacheResponse]);
    });

    it(@"should return cache response followed by an origin response", ^{
      LLSignalTestRecorder *values = [[assetManager fetchAlbumWithURL:fetchStaleUrl] testRecorder];

      [underlyingAssetManager serveValidateAlbumWithURL:fetchStaleUrl
                                              entityTag:staleCacheInfo.entityTag withValidity:NO];

      PTNCacheProxy *albumWithInfo =
          [[PTNCacheProxy alloc] initWithUnderlyingObject:album cacheInfo:freshCacheInfo];
      [underlyingAssetManager serveAlbumURL:fetchStaleUrl withAlbum:(id<PTNAlbum>)albumWithInfo];

      expect(values).will.sendValues(@[
        cachedAlbumChangeset,
        [PTNAlbumChangeset changesetWithAfterAlbum:(id<PTNAlbum>)albumWithInfo]
      ]);
      OCMVerify([cache storeAlbum:album withCacheInfo:freshCacheInfo forURL:fetchStaleUrl]);
    });

     it(@"should return just a cache response when it's valid", ^{
      LLSignalTestRecorder *values = [[assetManager fetchAlbumWithURL:fetchStaleUrl] testRecorder];

      [underlyingAssetManager serveValidateAlbumWithURL:fetchStaleUrl
                                              entityTag:staleCacheInfo.entityTag withValidity:YES];

      expect(values).will.sendValues(@[cachedAlbumChangeset]);
    });

    it(@"should return just a cache response when the origin response is cache equivalent", ^{
      LLSignalTestRecorder *values = [[assetManager fetchAlbumWithURL:fetchStaleUrl] testRecorder];

      [underlyingAssetManager serveValidateAlbumWithURL:fetchStaleUrl
                                              entityTag:staleCacheInfo.entityTag withValidity:NO];
      [underlyingAssetManager serveAlbumURL:fetchStaleUrl withAlbum:cachedAlbum];

      expect(values).will.sendValues(@[cachedAlbumChangeset]);
    });

    it(@"should deliver updates on the original signal", ^{
      LLSignalTestRecorder *values = [[assetManager fetchAlbumWithURL:fetchStaleUrl] testRecorder];

      [underlyingAssetManager serveValidateAlbumWithURL:fetchStaleUrl
                                              entityTag:staleCacheInfo.entityTag withValidity:NO];

      PTNIncrementalChanges *changes = [PTNIncrementalChanges changesWithRemovedIndexes:nil
          insertedIndexes:[NSIndexSet indexSetWithIndex:0] updatedIndexes:nil moves:nil];
      PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithBeforeAlbum:nil
                                                                      afterAlbum:cachedAlbum
                                                                 subalbumChanges:nil
                                                                    assetChanges:changes];
      [underlyingAssetManager serveAlbumURL:fetchStaleUrl withAlbumChangeset:changeset];

      expect(values).will.sendValues(@[cachedAlbumChangeset, changeset]);
    });

    it(@"should return an origin response when not cache equivalent", ^{
      LLSignalTestRecorder *values = [[assetManager fetchAlbumWithURL:fetchStaleUrl] testRecorder];

      [underlyingAssetManager serveValidateAlbumWithURL:fetchStaleUrl
                                              entityTag:staleCacheInfo.entityTag withValidity:NO];
      [underlyingAssetManager serveAlbumURL:fetchStaleUrl withAlbum:cachedAlbum];
      [underlyingAssetManager serveAlbumURL:fetchStaleUrl withAlbum:album];

      expect(values).will.sendValues(@[cachedAlbumChangeset, albumChangeset]);
    });
  });
});

context(@"image fetching", ^{
  __block id<PTNDescriptor> descriptor;
  __block id<PTNResizingStrategy> resizingStrategy;
  __block PTNImageFetchOptions *options;
  __block PTNImageRequest *request;

  __block id<PTNImageAsset, PTNDataAsset> imageAsset;
  __block id<PTNImageAsset, PTNDataAsset> cachedImageAsset;
  __block LTProgress<id<PTNImageAsset>> *imageAssetProgress;
  __block LTProgress<id<PTNImageAsset>> *cachedImageAssetProgress;

  beforeEach(^{
    descriptor = PTNCreateDescriptor(url, nil, 0, nil);
    resizingStrategy = [PTNResizingStrategy identity];
    options = OCMClassMock([PTNImageFetchOptions class]);
    request = [[PTNImageRequest alloc] initWithDescriptor:descriptor
                                         resizingStrategy:resizingStrategy options:options];

    imageAsset = OCMProtocolMock(@protocol(PTNDataAsset));
    cachedImageAsset = OCMProtocolMock(@protocol(PTNDataAsset));
    imageAssetProgress = [[LTProgress alloc] initWithResult:imageAsset];
    cachedImageAssetProgress = [[LTProgress alloc] initWithResult:cachedImageAsset];
  });

  it(@"should return values from underlying asset manager when no cached value is available", ^{
    OCMStub([cache cachedImageAssetForURL:OCMOCK_ANY resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:nil]);

    LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptor
                                                          resizingStrategy:resizingStrategy
                                                                   options:options] testRecorder];
    [underlyingAssetManager serveImageRequest:request withProgress:@[@0.25, @0.5, @1]
                                   imageAsset:imageAsset];

    expect(values).will.sendValues(@[
      [[LTProgress alloc] initWithProgress:0.25],
      [[LTProgress alloc] initWithProgress:0.5],
      [[LTProgress alloc] initWithProgress:1],
      imageAssetProgress
    ]);
  });

  it(@"should forward errors from underlying asset manager when no cached value is available", ^{
    OCMStub([cache cachedImageAssetForURL:OCMOCK_ANY resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:nil]);

    LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptor
                                                          resizingStrategy:resizingStrategy
                                                                   options:options] testRecorder];
    [underlyingAssetManager serveImageRequest:request withProgress:@[@0.25, @0.5, @1]
                                 finallyError:[NSError lt_errorWithCode:1337]];

    expect(values).will.sendValues(@[
      [[LTProgress alloc] initWithProgress:0.25],
      [[LTProgress alloc] initWithProgress:0.5],
      [[LTProgress alloc] initWithProgress:1]
    ]);
    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == 1337;
    });
  });

  it(@"should return values from cache when fresh", ^{
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedImageAsset
                                                                        info:freshCacheInfo];
    OCMStub([cache cachedImageAssetForURL:OCMOCK_ANY resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:cacheResponse]);

    expect([assetManager fetchImageWithDescriptor:descriptor resizingStrategy:resizingStrategy
        options:options]).will.sendValues(@[cachedImageAssetProgress]);
  });

  it(@"should return values from underlying asset manager when cache errs", ^{
    OCMStub([cache cachedImageAssetForURL:OCMOCK_ANY
                         resizingStrategy:resizingStrategy])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);

    LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptor
                                                          resizingStrategy:resizingStrategy
                                                                   options:options] testRecorder];
    [underlyingAssetManager serveImageRequest:request withProgress:@[@0.25, @0.5, @1]
                                   imageAsset:imageAsset];

    expect(values).will.sendValues(@[
      [[LTProgress alloc] initWithProgress:0.25],
      [[LTProgress alloc] initWithProgress:0.5],
      [[LTProgress alloc] initWithProgress:1],
      imageAssetProgress
    ]);
  });

  it(@"should validate cache responses when stale and fetch origin if invalid", ^{
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedImageAsset
                                                                        info:staleCacheInfo];
    OCMStub([cache cachedImageAssetForURL:OCMOCK_ANY resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:cacheResponse]);

    LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptor
                                                          resizingStrategy:resizingStrategy
                                                                   options:options] testRecorder];
    [underlyingAssetManager serveValidateImageWithRequest:request entityTag:staleCacheInfo.entityTag
                                             withValidity:NO];
    [underlyingAssetManager serveImageRequest:request withProgress:@[@0.25, @0.5, @1]
                                   imageAsset:imageAsset];

    expect(values).will.sendValues(@[
      [[LTProgress alloc] initWithProgress:0.25],
      [[LTProgress alloc] initWithProgress:0.5],
      [[LTProgress alloc] initWithProgress:1],
      imageAssetProgress
    ]);
  });

  it(@"should validate cache responses when stale and return them if valid", ^{
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedImageAsset
                                                                        info:staleCacheInfo];
    OCMStub([cache cachedImageAssetForURL:OCMOCK_ANY resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:cacheResponse]);

    LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptor
                                                          resizingStrategy:resizingStrategy
                                                                   options:options] testRecorder];
    [underlyingAssetManager serveValidateImageWithRequest:request entityTag:staleCacheInfo.entityTag
                                             withValidity:YES];

    expect(values).will.matchValue(0, ^BOOL(LTProgress<PTNCacheProxy *> *progress) {
      PTNCacheProxy<id<PTNImageAsset>> *proxy = progress.result;
      return proxy.underlyingObject == cachedImageAsset &&
          proxy.cacheInfo.entityTag == staleCacheInfo.entityTag &&
          proxy.cacheInfo.maxAge == staleCacheInfo.maxAge &&
          ![proxy.cacheInfo.responseTime isEqual:staleCacheInfo.responseTime];
    });
  });

  it(@"should re-cache validated responses", ^{
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedImageAsset
                                                                        info:staleCacheInfo];
    OCMStub([cache cachedImageAssetForURL:OCMOCK_ANY resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:cacheResponse]);

    LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptor
                                                          resizingStrategy:resizingStrategy
                                                                   options:options] testRecorder];

    [underlyingAssetManager serveValidateImageWithRequest:request entityTag:staleCacheInfo.entityTag
                                             withValidity:YES];

    expect(values).will.matchValue(0, ^BOOL(LTProgress<PTNCacheProxy *> *progress) {
      PTNCacheProxy<id<PTNImageAsset>> *proxy = progress.result;
      return proxy.underlyingObject == cachedImageAsset &&
      proxy.cacheInfo.entityTag == staleCacheInfo.entityTag &&
      proxy.cacheInfo.maxAge == staleCacheInfo.maxAge &&
      ![proxy.cacheInfo.responseTime isEqual:staleCacheInfo.responseTime];
    });
    OCMVerify([cache storeImageAsset:cachedImageAsset withCacheInfo:OCMOCK_ANY forURL:OCMOCK_ANY]);
  });

  it(@"should return stale responses when using PTNCachePolicyReturnCacheDataElseLoad", ^{
    NSURL *fetchStaleUrl =
        [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReturnCacheDataElseLoad)];
    id<PTNDescriptor> descriptorWithPolicy = PTNCreateDescriptor(fetchStaleUrl, nil, 0, nil);
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedImageAsset
                                                                        info:staleCacheInfo];
    OCMStub([cache cachedImageAssetForURL:OCMOCK_ANY resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:cacheResponse]);

    expect([assetManager fetchImageWithDescriptor:descriptorWithPolicy
        resizingStrategy:resizingStrategy options:options])
        .will.sendValues(@[cachedImageAssetProgress]);
  });

  it(@"should return fresh responses when using PTNCachePolicyReturnCacheDataElseLoad", ^{
    NSURL *fetchStaleUrl =
        [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReturnCacheDataElseLoad)];
    id<PTNDescriptor> descriptorWithPolicy = PTNCreateDescriptor(fetchStaleUrl, nil, 0, nil);
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedImageAsset
                                                                        info:freshCacheInfo];
    OCMStub([cache cachedImageAssetForURL:OCMOCK_ANY resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:cacheResponse]);

    expect([assetManager fetchImageWithDescriptor:descriptorWithPolicy
        resizingStrategy:resizingStrategy options:options])
        .will.sendValues(@[cachedImageAssetProgress]);
  });

  it(@"should return from origin when missing cache using PTNCachePolicyReturnCacheDataElseLoad", ^{
    NSURL *fetchMissingCacheUrl =
        [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReturnCacheDataElseLoad)];
    id<PTNDescriptor> descriptorWithPolicy = PTNCreateDescriptor(fetchMissingCacheUrl, nil, 0, nil);
    OCMStub([cache cachedImageAssetForURL:OCMOCK_ANY resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:nil]);

    PTNImageRequest *requestWithPolicy =
        [[PTNImageRequest alloc] initWithDescriptor:descriptorWithPolicy
                                   resizingStrategy:resizingStrategy options:options];
    LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptorWithPolicy
                                                          resizingStrategy:resizingStrategy
                                                                   options:options] testRecorder];
    [underlyingAssetManager serveValidateImageWithRequest:requestWithPolicy
                                                entityTag:freshCacheInfo.entityTag
                                             withValidity:NO];
    [underlyingAssetManager serveImageRequest:requestWithPolicy withProgress:@[@0.25, @0.5, @1]
                                   imageAsset:imageAsset];

    expect(values).will.sendValues(@[
      [[LTProgress alloc] initWithProgress:0.25],
      [[LTProgress alloc] initWithProgress:0.5],
      [[LTProgress alloc] initWithProgress:1],
      imageAssetProgress
    ]);
  });

  it(@"should ignore cache when using PTNCachePolicyReloadIgnoringLocalCacheData", ^{
    NSURL *ignoreCacheUrl =
        [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReloadIgnoringLocalCacheData)];
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedImageAsset
                                                                        info:freshCacheInfo];
    OCMStub([cache cachedImageAssetForURL:OCMOCK_ANY resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:cacheResponse]);

    id<PTNDescriptor> descriptorWithPolicy = PTNCreateDescriptor(ignoreCacheUrl, nil, 0, nil);
    PTNImageRequest *requestWithPolicy =
        [[PTNImageRequest alloc] initWithDescriptor:descriptorWithPolicy
                                   resizingStrategy:resizingStrategy options:options];
    LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptorWithPolicy
                                                          resizingStrategy:resizingStrategy
                                                                   options:options] testRecorder];
    [underlyingAssetManager serveValidateImageWithRequest:requestWithPolicy
                                                entityTag:freshCacheInfo.entityTag
                                             withValidity:NO];
    [underlyingAssetManager serveImageRequest:requestWithPolicy withProgress:@[@0.25, @0.5, @1]
                                   imageAsset:imageAsset];

    expect(values).will.sendValues(@[
      [[LTProgress alloc] initWithProgress:0.25],
      [[LTProgress alloc] initWithProgress:0.5],
      [[LTProgress alloc] initWithProgress:1],
      imageAssetProgress
    ]);
  });

  it(@"should ignore cache when using PTNCachePolicyReloadIgnoringLocalCacheData", ^{
    NSURL *ignoreCacheUrl =
        [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReloadIgnoringLocalCacheData)];
    OCMStub([cache cachedImageAssetForURL:OCMOCK_ANY resizingStrategy:resizingStrategy])
        .andReturn([RACSignal return:nil]);

    id<PTNDescriptor> descriptorWithPolicy = PTNCreateDescriptor(ignoreCacheUrl, nil, 0, nil);
    PTNImageRequest *requestWithPolicy =
        [[PTNImageRequest alloc] initWithDescriptor:descriptorWithPolicy
                                   resizingStrategy:resizingStrategy options:options];
    LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptorWithPolicy
                                                          resizingStrategy:resizingStrategy
                                                                   options:options] testRecorder];
    [underlyingAssetManager serveValidateImageWithRequest:requestWithPolicy
                                                entityTag:freshCacheInfo.entityTag
                                             withValidity:NO];
    [underlyingAssetManager serveImageRequest:requestWithPolicy withProgress:@[@0.25, @0.5, @1]
                                   imageAsset:imageAsset];

    expect(values).will.sendValues(@[
      [[LTProgress alloc] initWithProgress:0.25],
      [[LTProgress alloc] initWithProgress:0.5],
      [[LTProgress alloc] initWithProgress:1],
      imageAssetProgress
    ]);
  });

  context(@"PTNCachePolicyReturnCacheDataThenLoad", ^{
    __block NSURL *fetchStaleUrl;
    __block id<PTNDescriptor> descriptorWithPolicy;
    __block PTNImageRequest *requestWithPolicy;

    beforeEach(^{
      fetchStaleUrl = [url ptn_cacheURLWithCachePolicy:$(PTNCachePolicyReturnCacheDataThenLoad)];
      descriptorWithPolicy = PTNCreateDescriptor(fetchStaleUrl, nil, 0, nil);
      requestWithPolicy = [[PTNImageRequest alloc] initWithDescriptor:descriptorWithPolicy
                                                     resizingStrategy:resizingStrategy
                                                              options:options];

      PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedImageAsset
                                                                          info:staleCacheInfo];
      OCMStub([cache cachedImageAssetForURL:OCMOCK_ANY resizingStrategy:resizingStrategy])
          .andReturn([RACSignal return:cacheResponse]);
    });

    it(@"should return cache response followed by an origin response", ^{
      LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptorWithPolicy
          resizingStrategy:resizingStrategy options:options] testRecorder];

      [underlyingAssetManager serveValidateImageWithRequest:requestWithPolicy
                                                  entityTag:staleCacheInfo.entityTag
                                               withValidity:NO];
      PTNCacheProxy *imageAssetWithInfo =
          [[PTNCacheProxy alloc] initWithUnderlyingObject:imageAsset cacheInfo:freshCacheInfo];

      [underlyingAssetManager serveImageRequest:requestWithPolicy withProgress:@[@0.25, @0.5, @1]
                                     imageAsset:(id<PTNImageAsset>)imageAssetWithInfo];

      expect(values).will.sendValues(@[
        cachedImageAssetProgress,
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5],
        [[LTProgress alloc] initWithProgress:1],
        [[LTProgress alloc] initWithResult:imageAssetWithInfo]
      ]);
      OCMVerify([cache storeImageAsset:imageAsset withCacheInfo:freshCacheInfo forURL:OCMOCK_ANY]);
    });

     it(@"should return just a cache response when it's valid", ^{
      LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptorWithPolicy
          resizingStrategy:resizingStrategy options:options] testRecorder];

      [underlyingAssetManager serveValidateImageWithRequest:requestWithPolicy
                                                  entityTag:staleCacheInfo.entityTag
                                               withValidity:YES];

      expect(values).will.sendValues(@[cachedImageAssetProgress]);
    });

    it(@"should return just a cache response when the origin response is cache equivalent", ^{
      LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptorWithPolicy
          resizingStrategy:resizingStrategy options:options] testRecorder];

      [underlyingAssetManager serveValidateImageWithRequest:requestWithPolicy
                                                  entityTag:staleCacheInfo.entityTag
                                               withValidity:NO];
      [underlyingAssetManager serveImageRequest:requestWithPolicy withProgress:@[]
                                     imageAsset:(id<PTNImageAsset>)cachedImageAsset];

      expect(values).will.sendValues(@[cachedImageAssetProgress]);
    });

    it(@"should return cache response followed by origin response when getting progress", ^{
      LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptorWithPolicy
          resizingStrategy:resizingStrategy options:options] testRecorder];

      [underlyingAssetManager serveValidateImageWithRequest:requestWithPolicy
                                                  entityTag:staleCacheInfo.entityTag
                                               withValidity:NO];
      [underlyingAssetManager serveImageRequest:requestWithPolicy withProgress:@[@0.25, @0.5, @1]
                                     imageAsset:cachedImageAsset];

      expect(values).will.sendValues(@[
        cachedImageAssetProgress,
        [[LTProgress alloc] initWithProgress:0.25],
        [[LTProgress alloc] initWithProgress:0.5],
        [[LTProgress alloc] initWithProgress:1],
        cachedImageAssetProgress
      ]);
    });

    it(@"should return cache response followed by origin response when not cache equivalent", ^{
      LLSignalTestRecorder *values = [[assetManager fetchImageWithDescriptor:descriptorWithPolicy
          resizingStrategy:resizingStrategy options:options] testRecorder];

      [underlyingAssetManager serveValidateImageWithRequest:requestWithPolicy
                                                  entityTag:staleCacheInfo.entityTag
                                               withValidity:NO];
      [underlyingAssetManager serveImageRequest:requestWithPolicy withProgress:@[]
                                     imageAsset:imageAsset];

      expect(values).will.sendValues(@[
        cachedImageAssetProgress,
        imageAssetProgress
      ]);
    });
  });

  it(@"should reuse cached image assets when they have the same canonic url", ^{
    PTNImageRequest *otherRequest = [[PTNImageRequest alloc] initWithDescriptor:descriptor
        resizingStrategy:[PTNResizingStrategy maxPixels:1337] options:options];

    NSURL *canonicalURL = [NSURL URLWithString:@"http://www.foo.bar/canonical"];
    [underlyingAssetManager setCanonicalURL:canonicalURL forImageRequest:request];
    [underlyingAssetManager setCanonicalURL:canonicalURL forImageRequest:otherRequest];
    PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:cachedImageAsset
                                                                        info:freshCacheInfo];
    OCMStub([cache cachedImageAssetForURL:canonicalURL resizingStrategy:OCMOCK_ANY])
        .andReturn([RACSignal return:cacheResponse]);

    expect([assetManager fetchImageWithDescriptor:request.descriptor
        resizingStrategy:request.resizingStrategy options:request.options])
        .will.sendValues(@[cachedImageAssetProgress]);
    expect([assetManager fetchImageWithDescriptor:otherRequest.descriptor
        resizingStrategy:otherRequest.resizingStrategy options:otherRequest.options])
        .will.sendValues(@[cachedImageAssetProgress]);
  });
});

context(@"AVAsset fetching", ^{
  __block PTNAVAssetFetchOptions *options;
  __block id<PTNDescriptor> descriptor;
  __block PTNAVAssetRequest *request;
  __block id<PTNAudiovisualAsset> videoAsset;

  beforeEach(^{
    options = OCMClassMock([PTNImageFetchOptions class]);
    descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    videoAsset = OCMProtocolMock(@protocol(PTNAudiovisualAsset));
    request = [[PTNAVAssetRequest alloc] initWithDescriptor:descriptor options:options];
  });

  it(@"should forward values from underlying asset manager", ^{
    LLSignalTestRecorder *values =
        [[assetManager fetchAVAssetWithDescriptor:descriptor options:options] testRecorder];

    [underlyingAssetManager serveAVAssetRequest:request withProgress:@[] videoAsset:videoAsset];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:videoAsset]]);
    expect(values).will.complete();
  });

  it(@"should forward errors from underlying asset manager", ^{
    LLSignalTestRecorder *values =
        [[assetManager fetchAVAssetWithDescriptor:descriptor options:options] testRecorder];

    NSError *error = [NSError lt_errorWithCode:1337];

    [underlyingAssetManager serveAVAssetRequest:request withProgress:@[@0.666] finallyError:error];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithProgress:0.666]]);
    expect(values).will.error();
    expect(values.error).will.equal(error);
  });
});

context(@"image data fetching", ^{
  __block id<PTNAssetDescriptor> descriptor;
  __block id<PTNImageDataAsset> imageDataAsset;
  __block PTNImageDataRequest *request;

  beforeEach(^{
    descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    imageDataAsset = OCMProtocolMock(@protocol(PTNImageDataAsset));
    request = [[PTNImageDataRequest alloc] initWithAssetDescriptor:descriptor];
  });

  it(@"should forward values from underlying asset manager", ^{
    LLSignalTestRecorder *values = [[assetManager fetchImageDataWithDescriptor:descriptor]
                                    testRecorder];

    [underlyingAssetManager serveImageDataRequest:request withProgress:@[]
                                   imageDataAsset:imageDataAsset];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:imageDataAsset]]);
    expect(values).will.complete();
  });

  it(@"should forward errors from underlying asset manager", ^{
    LLSignalTestRecorder *values = [[assetManager fetchImageDataWithDescriptor:descriptor]
                                    testRecorder];

    NSError *error = [NSError lt_errorWithCode:1337];
    [underlyingAssetManager serveImageDataRequest:request withProgress:@[@0.123]
                                     finallyError:error];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithProgress:0.123]]);
    expect(values).will.error();
    expect(values.error).will.equal(error);
  });
});

context(@"AV preview fetching", ^{
  __block PTNAVAssetFetchOptions *options;
  __block id<PTNDescriptor> descriptor;
  __block PTNAVPreviewRequest *request;

  beforeEach(^{
    options = OCMClassMock([PTNImageFetchOptions class]);
    descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    request = [[PTNAVPreviewRequest alloc] initWithDescriptor:descriptor options:options];
  });

  it(@"should forward values from underlying asset manager", ^{
    LLSignalTestRecorder *values =
        [[assetManager fetchAVPreviewWithDescriptor:descriptor options:options] testRecorder];
    AVPlayerItem *playerItem = OCMClassMock([AVPlayerItem class]);

    [underlyingAssetManager serveAVPreviewRequest:request withProgress:@[] playerItem:playerItem];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:playerItem]]);
    expect(values).will.complete();
  });

  it(@"should forward errors from underlying asset manager", ^{
    LLSignalTestRecorder *values =
        [[assetManager fetchAVPreviewWithDescriptor:descriptor options:options] testRecorder];

    NSError *error = [NSError lt_errorWithCode:1337];

    [underlyingAssetManager serveAVPreviewRequest:request withProgress:@[@0.666]
                                     finallyError:error];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithProgress:0.666]]);
    expect(values).will.error();
    expect(values.error).will.equal(error);
  });
});

context(@"av data fetching", ^{
  __block id<PTNAssetDescriptor> descriptor;
  __block PTNAVDataRequest *request;

  beforeEach(^{
    descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    request = [[PTNAVDataRequest alloc] initWithDescriptor:descriptor];
  });

  it(@"should forward values from underlying asset manager", ^{
    LLSignalTestRecorder *values = [[assetManager fetchAVDataWithDescriptor:descriptor]
                                    testRecorder];
    id<PTNAVDataAsset> avDataAsset = OCMProtocolMock(@protocol(PTNAVDataAsset));

    [underlyingAssetManager serveAVDataRequest:request withProgress:@[] avDataAsset:avDataAsset];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:avDataAsset]]);
    expect(values).will.complete();
  });

  it(@"should forward errors from underlying asset manager", ^{
    LLSignalTestRecorder *values = [[assetManager fetchAVDataWithDescriptor:descriptor]
                                    testRecorder];

    NSError *error = [NSError lt_errorWithCode:1337];
    [underlyingAssetManager serveAVDataRequest:request withProgress:@[@0.123] finallyError:error];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithProgress:0.123]]);
    expect(values).will.error();
    expect(values.error).will.equal(error);
  });
});

SpecEnd
