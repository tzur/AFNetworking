// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanAssetManager.h"

#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVPlayerItem.h>
#import <LTKit/LTPath.h>
#import <LTKit/LTRandomAccessCollection.h>
#import <LTKit/NSBundle+Path.h>

#import "NSError+Photons.h"
#import "NSErrorCodes+Photons.h"
#import "NSURL+Ocean.h"
#import "PTNAVAssetFetchOptions.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNCacheInfo.h"
#import "PTNCacheProxy.h"
#import "PTNDataBackedImageAsset.h"
#import "PTNDateProvider.h"
#import "PTNFileBackedAVAsset.h"
#import "PTNImageFetchOptions.h"
#import "PTNImageMetadata.h"
#import "PTNOceanAlbumDescriptor.h"
#import "PTNOceanAssetDescriptor.h"
#import "PTNOceanAssetSearchResponse.h"
#import "PTNOceanClient.h"
#import "PTNOceanEnums.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"
#import "PTNStaticImageAsset.h"
#import "PTNTestResources.h"

static PTNCacheProxy *PTNAssetCacheProxy(NSData *data, NSString * _Nullable uti,
                                         id<PTNResizingStrategy> resizingStrategy,
                                         NSDate *responseTime) {
  auto result = [[PTNDataBackedImageAsset alloc] initWithData:data uniformTypeIdentifier:uti
                                             resizingStrategy:resizingStrategy];
  auto cacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:86400 responseTime:responseTime
                                              entityTag:nil];
  return [[PTNCacheProxy<PTNAlbum> alloc] initWithUnderlyingObject:result cacheInfo:cacheInfo];
}

static PTNCacheProxy *PTNAssetCacheProxy(NSData *data, id<PTNResizingStrategy> resizingStrategy,
                                         NSDate *responseTime) {
  return PTNAssetCacheProxy(data, nil, resizingStrategy, responseTime);
}

static NSURL *PTNFakeAlbumRequestURL(NSUInteger page = 2,
                                     PTNOceanAssetType *assetType = $(PTNOceanAssetTypePhoto),
                                     NSString *phrase = @"foo") {
  return [NSURL ptn_oceanAlbumURLWithSource:$(PTNOceanAssetSourcePixabay) assetType:assetType
                                     phrase:phrase page:page];
}

static id PTNObjectFromJSONFileURL(NSURL *jsonFileURL, Class objectClass) {
  NSData *data = nn([NSData dataWithContentsOfURL:jsonFileURL]);
  id object = nn([NSJSONSerialization JSONObjectWithData:data options:0 error:nil]);
  return nn([MTLJSONAdapter modelOfClass:objectClass fromJSONDictionary:object
                                   error:nil]);
}

PTNOceanAssetSearchResponse *PTNFakeOceanSearchResponse() {
  return PTNObjectFromJSONFileURL(PTNOceanSearchResponseJSONURL(),
                                  [PTNOceanAssetSearchResponse class]);
}

PTNOceanAssetSearchResponse *PTNFakeOceanSearchResponseLastPage() {
  return PTNObjectFromJSONFileURL(PTNOceanSearchResponseLastPageJSONURL(),
                                  [PTNOceanAssetSearchResponse class]);
}

PTNOceanAssetDescriptor *PTNFakeOceanPhotoAssetDescriptor() {
  return PTNObjectFromJSONFileURL(PTNOceanPhotoAssetDescriptorJSONURL(),
                                  [PTNOceanAssetDescriptor class]);
}

PTNOceanAssetDescriptor *PTNFakeOceanVideoAssetDescriptor() {
  return PTNObjectFromJSONFileURL(PTNOceanVideoAssetDescriptorJSONURL(),
                                  [PTNOceanAssetDescriptor class]);
}

PTNOceanAssetDescriptor *PTNFakeOceanPartialVideoAssetDescriptor() {
  return PTNObjectFromJSONFileURL(PTNOceanPartialVideoAssetDescriptorJSONURL(),
                                  [PTNOceanAssetDescriptor class]);
}

PTNOceanAssetDescriptor *PTNFakeOceanNoDownloadVideoAssetDescriptor() {
  return PTNObjectFromJSONFileURL(PTNOceanNoDownloadVideoAssetDescriptorJSONURL(),
                                  [PTNOceanAssetDescriptor class]);
}

PTNOceanAssetDescriptor *PTNFakeOceanNoStreamingVideoAssetDescriptor() {
  return PTNObjectFromJSONFileURL(PTNOceanNoStreamingVideoAssetDescriptorJSONURL(),
                                  [PTNOceanAssetDescriptor class]);
}

NSURL *PTNOceanSmallImageURL() {
  return [NSURL URLWithString:@"http://a"];
}

NSURL *PTNOceanMediumImageURL() {
  return [NSURL URLWithString:@"http://b"];
}

NSURL *PTNOceanLargeImageURL() {
  return [NSURL URLWithString:@"http://c"];
}

NSURL *PTNOceanCloseTo360pVideoStreamURL() {
  return [NSURL URLWithString:@"https://stream/350_630"];
}

NSURL *PTNOceanCloseTo720pVideoStreamURL() {
  return [NSURL URLWithString:@"https://stream/710_1270"];
}

NSURL *PTNOcean1080pVideoStreamURL() {
  return [NSURL URLWithString:@"https://stream/1080_1920"];
}

NSURL *PTNOceanCloseTo360pVideoDownloadURL() {
  return [NSURL URLWithString:@"https://download/350_630"];
}

NSURL *PTNOceanCloseTo720pVideoDownloadURL() {
  return [NSURL URLWithString:@"https://download/710_1270"];
}

NSURL *PTNOcean1080pVideoDownloadURL() {
  return [NSURL URLWithString:@"https://download/1080_1920"];
}

SpecBegin(PTNOceanAssetManager)

static NSString * const kFakeURLString = @"http://foo.bar";

__block NSURL *requestURL;
__block PTNOceanClient *client;
__block PTNOceanAssetManager *manager;
__block PTNDateProvider *dateProvider;
__block NSDate *date;

beforeEach(^{
  requestURL = PTNFakeAlbumRequestURL();
  client = OCMClassMock([PTNOceanClient class]);
  dateProvider = OCMClassMock([PTNDateProvider class]);
  date = [NSDate date];
  OCMStub([dateProvider date]).andReturn(date);
  manager = [[PTNOceanAssetManager alloc] initWithClient:client dateProvider:dateProvider
             preferredImageDataPixelCount:(30 * 50) preferredVideoDataPixelCount:(720 * 1280)];
});

context(@"fetching albums", ^{
  context(@"valid URL", ^{
    it(@"should use parameters from request URL when issuing album search request", ^{
      auto expectedParameters = [[PTNOceanSearchParameters alloc]
                                 initWithType:$(PTNOceanAssetTypePhoto)
                                 source:$(PTNOceanAssetSourcePixabay) phrase:@"foo" page:2];

      OCMExpect([client searchWithParameters:expectedParameters]).andReturn([RACSignal empty]);

      auto __unused recorder = [[manager fetchAlbumWithURL:requestURL] testRecorder];

      OCMVerifyAll((id)client);
    });

    it(@"should use asset type according to URL", ^{
      NSURL *imageAlbumRequest = PTNFakeAlbumRequestURL(2, $(PTNOceanAssetTypeVideo));
      auto expectedParameters = [[PTNOceanSearchParameters alloc]
                                 initWithType:$(PTNOceanAssetTypeVideo)
                                 source:$(PTNOceanAssetSourcePixabay) phrase:@"foo" page:2];

      OCMExpect([client searchWithParameters:expectedParameters]).andReturn([RACSignal empty]);

      auto __unused recorder = [[manager fetchAlbumWithURL:imageAlbumRequest] testRecorder];

      OCMVerifyAll((id)client);
    });

    it(@"should use page number according to URL", ^{
      NSURL *imageAlbumRequest = PTNFakeAlbumRequestURL(3);
      auto expectedParameters = [[PTNOceanSearchParameters alloc]
                                 initWithType:$(PTNOceanAssetTypePhoto)
                                 source:$(PTNOceanAssetSourcePixabay) phrase:@"foo" page:3];

      OCMExpect([client searchWithParameters:expectedParameters]).andReturn([RACSignal empty]);

      auto __unused recorder = [[manager fetchAlbumWithURL:imageAlbumRequest] testRecorder];

      OCMVerifyAll((id)client);
    });

    it(@"should use phrase according to URL", ^{
      NSURL *imageAlbumRequest = PTNFakeAlbumRequestURL(2, $(PTNOceanAssetTypePhoto), @"bar");
      auto expectedParameters = [[PTNOceanSearchParameters alloc]
                                 initWithType:$(PTNOceanAssetTypePhoto)
                                 source:$(PTNOceanAssetSourcePixabay) phrase:@"bar" page:2];

      OCMExpect([client searchWithParameters:expectedParameters]).andReturn([RACSignal empty]);

      auto __unused recorder = [[manager fetchAlbumWithURL:imageAlbumRequest] testRecorder];

      OCMVerifyAll((id)client);
    });

    it(@"should fetch album", ^{
      RACSubject *subject = [RACSubject subject];
      OCMStub([client searchWithParameters:OCMOCK_ANY]).andReturn(subject);
      LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:requestURL] testRecorder];

      [subject sendNext:PTNFakeOceanSearchResponse()];
      id<PTNAlbum> album = [[PTNAlbum alloc] initWithURL:requestURL subalbums:@[]
                                                  assets:PTNFakeOceanSearchResponse().results
                                            nextAlbumURL:PTNFakeAlbumRequestURL(3)];
      auto cacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:300 responseTime:date entityTag:nil];
      auto cacheProxy = [[PTNCacheProxy<PTNAlbum> alloc] initWithUnderlyingObject:album
                                                                        cacheInfo:cacheInfo];

      expect(recorder).to.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:cacheProxy]]);
    });

    it(@"should not have next album for the last page", ^{
      RACSubject *subject = [RACSubject subject];
      OCMStub([client searchWithParameters:OCMOCK_ANY]).andReturn(subject);
      LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:requestURL] testRecorder];

      [subject sendNext:PTNFakeOceanSearchResponseLastPage()];

      id<PTNAlbum> album = [[PTNAlbum alloc] initWithURL:requestURL subalbums:@[] assets:@[]];
      auto cacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:300 responseTime:date entityTag:nil];
      auto cacheProxy = [[PTNCacheProxy<PTNAlbum> alloc] initWithUnderlyingObject:album
                                                                        cacheInfo:cacheInfo];

      expect(recorder).to.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:cacheProxy]]);
    });
  });

  context(@"errors", ^{
    it(@"should send error when using an invalid URL", ^{
      NSURL *invalidURL = [NSURL URLWithString:kFakeURLString];
      expect([manager fetchAlbumWithURL:invalidURL])
          .to.sendError([NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:invalidURL]);
    });

    it(@"should forward parsing errors", ^{
      RACSubject *subject = [RACSubject subject];
      OCMStub([client searchWithParameters:OCMOCK_ANY]).andReturn(subject);
      LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:requestURL] testRecorder];

      auto underlyingError = [NSError lt_errorWithCode:1337];
      [subject sendError:underlyingError];

      expect(recorder).to.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAlbumNotFound &&
            [error.lt_underlyingError isEqual:underlyingError];
      });
    });
  });
});

context(@"fetching descriptors", ^{
  it(@"should fetch album descriptor", ^{
    auto descriptor = [[PTNOceanAlbumDescriptor alloc] initWithAlbumURL:requestURL];
    auto cacheInfo = [[PTNCacheInfo alloc]
                      initWithMaxAge:[NSDate distantFuture].timeIntervalSince1970
                      responseTime:date entityTag:nil];
    auto cacheProxy = [[PTNCacheProxy<PTNAlbum> alloc] initWithUnderlyingObject:descriptor
                                                                      cacheInfo:cacheInfo];
    expect([manager fetchDescriptorWithURL:requestURL]).to.sendValues(@[cacheProxy]);
  });

  context(@"fetching asset descriptor", ^{
    context(@"image asset", ^{
      __block NSURL *assetRequestURL;

      beforeEach(^{
        assetRequestURL = [NSURL ptn_oceanAssetURLWithSource:$(PTNOceanAssetSourcePixabay)
                                                   assetType:$(PTNOceanAssetTypePhoto)
                                                  identifier:@"bar"];
      });

      it(@"should use correct request arguments", ^{
        auto expectredParameters = [[PTNOceanAssetFetchParameters alloc]
                                    initWithType:$(PTNOceanAssetTypePhoto)
                                    source:$(PTNOceanAssetSourcePixabay)
                                    identifier:@"bar"];

        OCMExpect([client fetchAssetDescriptorWithParameters:expectredParameters])
            .andReturn([RACSignal empty]);

        auto __unused recorder = [[manager fetchDescriptorWithURL:assetRequestURL] testRecorder];

        OCMVerifyAll((id)client);
      });

      it(@"should fetch asset descriptor", ^{
        auto expectedDescriptor = PTNFakeOceanPhotoAssetDescriptor();
        auto cacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:86400 responseTime:date
                                                    entityTag:nil];
        auto cacheProxy = [[PTNCacheProxy<PTNAlbum> alloc]
                           initWithUnderlyingObject:expectedDescriptor
                           cacheInfo:cacheInfo];
        RACSubject *subject = [RACSubject subject];
        OCMStub([client fetchAssetDescriptorWithParameters:OCMOCK_ANY])
            .andReturn(subject);
        auto recorder = [[manager fetchDescriptorWithURL:assetRequestURL] testRecorder];

        [subject sendNext:expectedDescriptor];

        expect(recorder).to.sendValues(@[cacheProxy]);
      });

      it(@"should send err when client errs", ^{
        RACSubject *subject = [RACSubject subject];

        OCMStub([client fetchAssetDescriptorWithParameters:OCMOCK_ANY])
            .andReturn(subject);
        LLSignalTestRecorder *recorder =
            [[manager fetchDescriptorWithURL:assetRequestURL] testRecorder];

        auto underlyingError = [NSError lt_errorWithCode:1337];
        [subject sendError:underlyingError];

        expect(recorder).to.matchError(^BOOL(NSError *error) {
          return error.code == PTNErrorCodeAssetLoadingFailed &&
              [error.lt_underlyingError isEqual:underlyingError];
        });
      });
    });
  });

  it(@"should send error when using an invalid URL", ^{
    NSURL *invalidURL = [NSURL URLWithString:kFakeURLString];
    expect([manager fetchDescriptorWithURL:invalidURL])
        .to.sendError([NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:invalidURL]);
  });
});

context(@"fetching images", ^{
  it(@"should send error for an invalid descriptor class", ^{
    id<PTNDescriptor> invalidDescriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    RACSignal *fetch = [manager
                        fetchImageWithDescriptor:invalidDescriptor
                        resizingStrategy:[PTNResizingStrategy identity]
                        options:[PTNImageFetchOptions options]];

    expect(fetch).to.sendError([NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                     associatedDescriptor:invalidDescriptor]);
  });

  context(@"ocean descriptors", ^{
    context(@"invalid descriptors", ^{
      it(@"should send error if there are no available assets", ^{
        PTNOceanAssetDescriptor *invalidDescriptor = OCMClassMock([PTNOceanAssetDescriptor class]);
        OCMStub(invalidDescriptor.images).andReturn(@[]);
        OCMStub(invalidDescriptor.type).andReturn($(PTNOceanAssetTypePhoto));

        RACSignal *fetch = [manager
                            fetchImageWithDescriptor:invalidDescriptor
                            resizingStrategy:OCMProtocolMock(@protocol(PTNResizingStrategy))
                            options:OCMClassMock([PTNImageFetchOptions class])];

        expect(fetch).to.sendError([NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                         associatedDescriptor:invalidDescriptor]);
      });
    });

    context(@"valid descriptors", ^{
      __block id<PTNResizingStrategy> resizingStrategy;
      __block PTNImageFetchOptions *options;
      __block PTNOceanAssetDescriptor *descriptor;

      beforeEach(^{
        descriptor = PTNFakeOceanPhotoAssetDescriptor();

        resizingStrategy = OCMProtocolMock(@protocol(PTNResizingStrategy));
        OCMStub([resizingStrategy sizeForInputSize:CGSizeMake(100, 60)])
            .andReturn(CGSizeMake(100, 60));
        OCMStub([resizingStrategy sizeForInputSize:CGSizeMake(50, 20)])
            .andReturn(CGSizeMake(100, 60));
        OCMStub([resizingStrategy sizeForInputSize:CGSizeMake(500, 200)])
            .andReturn(CGSizeMake(100, 60));

        options = OCMClassMock([PTNImageFetchOptions class]);
      });

      it(@"should send progress", ^{
        RACSubject *subject = [RACSubject subject];

        OCMStub([client downloadDataWithURL:OCMOCK_ANY]).andReturn(subject);

        LLSignalTestRecorder *recorder = [[manager fetchImageWithDescriptor:descriptor
                                                           resizingStrategy:resizingStrategy
                                                                    options:options] testRecorder];

        [subject sendNext:[[PTNProgress alloc] initWithProgress:@0.25]];
        [subject sendNext:[[PTNProgress alloc] initWithProgress:@0.5]];

        expect(recorder).to.sendValues(@[
          [[PTNProgress alloc] initWithProgress:@0.25],
          [[PTNProgress alloc] initWithProgress:@0.5]
        ]);
      });

      it(@"should fetch image in fast delivery mode", ^{
        OCMStub([options deliveryMode]).andReturn(PTNImageDeliveryModeFast);

        RACSubject *subject = [RACSubject subject];
        OCMStub([client downloadDataWithURL:PTNOceanMediumImageURL()])
            .andReturn([RACSubject empty]);
        OCMStub([client downloadDataWithURL:PTNOceanSmallImageURL()]).andReturn(subject);
        auto data = [NSData data];
        auto progress = [PTNProgress progressWithResult:RACTuplePack(data, nil)];

        LLSignalTestRecorder *recorder = [[manager
                                           fetchImageWithDescriptor:descriptor
                                           resizingStrategy:resizingStrategy
                                           options:options] testRecorder];

        [subject sendNext:progress];

        auto result = PTNAssetCacheProxy(data, resizingStrategy, date);
        expect(recorder).to.sendValues(@[[[PTNProgress alloc] initWithResult:result]]);
      });

      it(@"should fetch image in high quality delivery mode", ^{
        OCMStub([options deliveryMode]).andReturn(PTNImageDeliveryModeHighQuality);

        OCMStub([client downloadDataWithURL:PTNOceanSmallImageURL()])
            .andReturn([RACSignal empty]);
        RACSubject *subject = [RACSubject subject];
        OCMStub([client downloadDataWithURL:PTNOceanMediumImageURL()]).andReturn(subject);
        auto data = [NSData data];
        auto progress = [PTNProgress progressWithResult:RACTuplePack(data, nil)];

        LLSignalTestRecorder *recorder = [[manager
                                           fetchImageWithDescriptor:descriptor
                                           resizingStrategy:resizingStrategy
                                           options:options] testRecorder];

        [subject sendNext:progress];

        expect(recorder).to.sendValues(@[
          [[PTNProgress alloc] initWithResult:PTNAssetCacheProxy(data, resizingStrategy, date)]
        ]);
      });

      it(@"should prefer image with biggest pixel count where applicable", ^{
        OCMStub([options deliveryMode]).andReturn(PTNImageDeliveryModeHighQuality);

        OCMStub([client downloadDataWithURL:PTNOceanSmallImageURL()])
            .andReturn([RACSignal empty]);
        RACSubject *subject = [RACSubject subject];
        OCMStub([client downloadDataWithURL:PTNOceanLargeImageURL()]).andReturn(subject);
        auto data = [NSData data];
        auto progress = [PTNProgress progressWithResult:RACTuplePack(data, nil)];
        resizingStrategy = [PTNResizingStrategy identity];

        LLSignalTestRecorder *recorder = [[manager
                                           fetchImageWithDescriptor:descriptor
                                           resizingStrategy:resizingStrategy
                                           options:options] testRecorder];

        [subject sendNext:progress];

        expect(recorder).to.sendValues(@[
          [[PTNProgress alloc] initWithResult:PTNAssetCacheProxy(data, resizingStrategy, date)]
        ]);
      });

      it(@"should fetch image in opportunistic delivery mode", ^{
        OCMStub([options deliveryMode]).andReturn(PTNImageDeliveryModeOpportunistic);

        RACSubject *lowQuality = [RACSubject subject];
        OCMStub([client downloadDataWithURL:PTNOceanSmallImageURL()]).andReturn(lowQuality);
        auto lowQualityData = [NSData data];
        auto lowQualityProgress = [PTNProgress
                                   progressWithResult:RACTuplePack(lowQualityData, nil)];

        RACSubject *highQuality = [RACSubject subject];
        OCMStub([client downloadDataWithURL:PTNOceanMediumImageURL()]).andReturn(highQuality);
        auto highQualityData = [NSData data];
        auto highQualityProgress = [PTNProgress
                                    progressWithResult:RACTuplePack(highQualityData, nil)];

        LLSignalTestRecorder *recorder = [[manager
                                           fetchImageWithDescriptor:descriptor
                                           resizingStrategy:resizingStrategy
                                           options:options] testRecorder];

        [lowQuality sendNext:lowQualityProgress];
        [lowQuality sendCompleted];

        [highQuality sendNext:highQualityProgress];
        [highQuality sendCompleted];

        expect(recorder).to.complete();
        expect(recorder).to.sendValues(@[
          [[PTNProgress alloc]
           initWithResult:PTNAssetCacheProxy(lowQualityData, resizingStrategy, date)],
          [[PTNProgress alloc]
           initWithResult:PTNAssetCacheProxy(highQualityData, resizingStrategy, date)]
        ]);
      });

      it(@"should fetch image when descriptor is wrapped by PTNCacheProxy", ^{
        auto cacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:1000 entityTag:nil];
        auto proxy = [[PTNCacheProxy alloc] initWithUnderlyingObject:descriptor
                                                           cacheInfo:cacheInfo];
        OCMStub([options deliveryMode]).andReturn(PTNImageDeliveryModeFast);

        OCMStub([client downloadDataWithURL:PTNOceanMediumImageURL()])
            .andReturn([RACSignal empty]);
        RACSubject *subject = [RACSubject subject];
        OCMStub([client downloadDataWithURL:PTNOceanSmallImageURL()]).andReturn(subject);
        NSData *data = [NSData data];
        auto progress = [PTNProgress progressWithResult:RACTuplePack(data, nil)];

        LLSignalTestRecorder *recorder =
            [[manager fetchImageWithDescriptor:(id<PTNDescriptor>)proxy
                              resizingStrategy:resizingStrategy
                                       options:options] testRecorder];

        [subject sendNext:progress];
        [subject sendCompleted];

        auto result = PTNAssetCacheProxy(data, resizingStrategy, date);
        expect(recorder).to.sendValues(@[[[PTNProgress alloc] initWithResult:result]]);
        expect(recorder).to.complete();
      });
    });
  });
});

context(@"fetching image data", ^{
  it(@"should send error for an invalid descriptor class", ^{
    id<PTNDescriptor> invalidDescriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    RACSignal *fetch = [manager fetchImageDataWithDescriptor:invalidDescriptor];

    expect(fetch).to.sendError([NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                     associatedDescriptor:invalidDescriptor]);
  });

  context(@"ocean descriptors", ^{
    context(@"invalid descriptors", ^{
      it(@"should send error if there are no available assets", ^{
        PTNOceanAssetDescriptor *invalidDescriptor = OCMClassMock([PTNOceanAssetDescriptor class]);
        OCMStub(invalidDescriptor.images).andReturn(@[]);
        OCMStub(invalidDescriptor.type).andReturn(PTNOceanAssetTypePhoto);

        RACSignal *fetch = [manager fetchImageDataWithDescriptor:invalidDescriptor];

        expect(fetch).to.sendError([NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                         associatedDescriptor:invalidDescriptor]);
      });
    });

    context(@"valid descriptors", ^{
      __block PTNOceanAssetDescriptor *descriptor;

      beforeEach(^{
        descriptor = PTNFakeOceanPhotoAssetDescriptor();
      });

      it(@"should send progress", ^{
        RACSubject *subject = [RACSubject subject];
        OCMStub([client downloadDataWithURL:OCMOCK_ANY]).andReturn(subject);

        LLSignalTestRecorder *recorder = [[manager fetchImageDataWithDescriptor:descriptor]
                                          testRecorder];

        [subject sendNext:[[PTNProgress alloc] initWithProgress:@0.25]];
        [subject sendNext:[[PTNProgress alloc] initWithProgress:@0.5]];

        expect(recorder).to.sendValues(@[
          [[PTNProgress alloc] initWithProgress:@0.25],
          [[PTNProgress alloc] initWithProgress:@0.5]
        ]);
      });

      it(@"should prefer image with pixel count closest to the preferred image pixel count", ^{
        RACSubject *subject = [RACSubject subject];
        OCMStub([client downloadDataWithURL:PTNOceanSmallImageURL()]).andReturn(subject);
        NSData *data = [NSData data];
        auto progress = [PTNProgress progressWithResult:RACTuplePack(data, nil)];

        LLSignalTestRecorder *recorder = [[manager fetchImageDataWithDescriptor:descriptor]
                                          testRecorder];
        [subject sendNext:progress];

        expect(recorder).to.sendValues(@[
          [[PTNProgress alloc] initWithResult:PTNAssetCacheProxy(data,
                                                                 [PTNResizingStrategy identity],
                                                                 date)]
        ]);
      });

      it(@"should convert MIME type to UTI", ^{
        RACSubject *subject = [RACSubject subject];
        OCMStub([client downloadDataWithURL:OCMOCK_ANY]).andReturn(subject);
        NSData *data = [NSData data];
        auto progress = [PTNProgress progressWithResult:RACTuplePack(data, @"foo")];

        LLSignalTestRecorder *recorder = [[manager fetchImageDataWithDescriptor:descriptor]
                                          testRecorder];
        [subject sendNext:progress];

        expect(recorder).to.sendValues(@[
          [[PTNProgress alloc] initWithResult:PTNAssetCacheProxy(data, @"foo",
                                                                 [PTNResizingStrategy identity],
                                                                 date)]
        ]);
      });
    });
  });
});

context(@"fetching AV preview", ^{
  it(@"should send error for an invalid descriptor class", ^{
    id<PTNDescriptor> invalidDescriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    RACSignal *fetch = [manager
                        fetchAVPreviewWithDescriptor:invalidDescriptor
                        options:OCMClassMock([PTNAVAssetFetchOptions class])];

    expect(fetch).to.sendError([NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                     associatedDescriptor:invalidDescriptor]);
  });

  context(@"ocean descriptors", ^{
    context(@"invalid descriptors", ^{
      it(@"should send error if there are no available assets", ^{
        PTNOceanAssetDescriptor *invalidDescriptor = OCMClassMock([PTNOceanAssetDescriptor class]);
        OCMStub([invalidDescriptor videos]).andReturn(@[]);
        OCMStub([invalidDescriptor type]).andReturn($(PTNOceanAssetTypeVideo));

        RACSignal *fetch = [manager
                            fetchAVPreviewWithDescriptor:invalidDescriptor
                            options:OCMClassMock([PTNAVAssetFetchOptions class])];

        expect(fetch).to.sendError([NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                         associatedDescriptor:invalidDescriptor]);
      });

      it(@"should err when there are no streaming URLs", ^{
        auto noStreamingDescriptor = PTNFakeOceanNoStreamingVideoAssetDescriptor();
        RACSignal *fetch = [manager
                            fetchAVPreviewWithDescriptor:noStreamingDescriptor
                            options:OCMClassMock([PTNAVAssetFetchOptions class])];

        expect(fetch).to.matchError(^BOOL(NSError *error) {
          return error.code == PTNErrorCodeAssetNotFound && error.lt_isLTDomain &&
              [error.ptn_associatedDescriptor isEqual:noStreamingDescriptor];
        });
      });
    });

    context(@"valid descriptors", ^{
      __block PTNOceanAssetDescriptor *descriptor;

      beforeEach(^{
        descriptor = PTNFakeOceanVideoAssetDescriptor();
      });

      it(@"should fetch the video closes to 360p in fast delivery mode", ^{
        auto options = [PTNAVAssetFetchOptions
                        optionsWithDeliveryMode:PTNAVAssetDeliveryModeFastFormat];

        RACSignal *values = [manager fetchAVPreviewWithDescriptor:descriptor options:options];
        expect(values).will.matchValue(0, ^BOOL(PTNProgress<AVPlayerItem *> *progress) {
          AVPlayerItem *playerItem = progress.result;
          if (![playerItem.asset isKindOfClass:[AVURLAsset class]]) {
            return NO;
          }
          return [((AVURLAsset *)playerItem.asset).URL isEqual:PTNOceanCloseTo360pVideoStreamURL()];
        });
      });

      it(@"should fetch the video closes to 720p in medium quality delivery mode", ^{
        auto options = [PTNAVAssetFetchOptions
                        optionsWithDeliveryMode:PTNAVAssetDeliveryModeMediumQualityFormat];

        RACSignal *values = [manager fetchAVPreviewWithDescriptor:descriptor options:options];
        expect(values).will.matchValue(0, ^BOOL(PTNProgress<AVPlayerItem *> *progress) {
          AVPlayerItem *playerItem = progress.result;
          if (![playerItem.asset isKindOfClass:[AVURLAsset class]]) {
            return NO;
          }
          return [((AVURLAsset *)playerItem.asset).URL isEqual:PTNOceanCloseTo720pVideoStreamURL()];
        });
      });

      it(@"should fetch the largest video in high quality delivery mode", ^{
        auto options = [PTNAVAssetFetchOptions
                        optionsWithDeliveryMode:PTNAVAssetDeliveryModeHighQualityFormat];

        RACSignal *values = [manager fetchAVPreviewWithDescriptor:descriptor options:options];
        expect(values).will.matchValue(0, ^BOOL(PTNProgress<AVPlayerItem *> *progress) {
          AVPlayerItem *playerItem = progress.result;
          if (![playerItem.asset isKindOfClass:[AVURLAsset class]]) {
            return NO;
          }
          return [((AVURLAsset *)playerItem.asset).URL isEqual:PTNOcean1080pVideoStreamURL()];
        });
      });

      it(@"should fetch the video closes to 720p in automatic delivery mode", ^{
        auto options = [PTNAVAssetFetchOptions
                        optionsWithDeliveryMode:PTNAVAssetDeliveryModeAutomatic];
        RACSignal *values = [manager fetchAVPreviewWithDescriptor:descriptor options:options];
        expect(values).will.matchValue(0, ^BOOL(PTNProgress<AVPlayerItem *> *progress) {
          AVPlayerItem *playerItem = progress.result;
          if (![playerItem.asset isKindOfClass:[AVURLAsset class]]) {
            return NO;
          }
          return [((AVURLAsset *)playerItem.asset).URL isEqual:PTNOceanCloseTo720pVideoStreamURL()];
        });
      });

      it(@"should only use video assets with non-nil stream URLs", ^{
        auto partialDescriptor = PTNFakeOceanPartialVideoAssetDescriptor();
        auto options = [PTNAVAssetFetchOptions
                        optionsWithDeliveryMode:PTNAVAssetDeliveryModeFastFormat];
        RACSignal *values = [manager fetchAVPreviewWithDescriptor:partialDescriptor
                                                          options:options];
        expect(values).will.matchValue(0, ^BOOL(PTNProgress<AVPlayerItem *> *progress) {
          AVPlayerItem *playerItem = progress.result;
          if (![playerItem.asset isKindOfClass:[AVURLAsset class]]) {
            return NO;
          }
          return [((AVURLAsset *)playerItem.asset).URL isEqual:PTNOceanCloseTo720pVideoStreamURL()];
        });
      });
    });
  });
});

context(@"fetching AV data", ^{
  it(@"should send error for an invalid descriptor class", ^{
    id<PTNDescriptor> invalidDescriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    RACSignal *fetch = [manager fetchAVDataWithDescriptor:invalidDescriptor];

    expect(fetch).to.sendError([NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                     associatedDescriptor:invalidDescriptor]);
  });

  context(@"ocean descriptors", ^{
    context(@"invalid descriptors", ^{
      it(@"should send error if there are no available assets", ^{
        PTNOceanAssetDescriptor *invalidDescriptor = OCMClassMock([PTNOceanAssetDescriptor class]);
        OCMStub(invalidDescriptor.videos).andReturn(@[]);
        OCMStub(invalidDescriptor.type).andReturn($(PTNOceanAssetTypeVideo));

        RACSignal *fetch = [manager fetchAVDataWithDescriptor:invalidDescriptor];

        expect(fetch).to.sendError([NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                         associatedDescriptor:invalidDescriptor]);
      });
    });

    context(@"valid descriptors", ^{
      __block PTNOceanAssetDescriptor *descriptor;

      beforeEach(^{
        descriptor = PTNFakeOceanVideoAssetDescriptor();
      });

      it(@"should send progress", ^{
        RACSubject *subject = [RACSubject subject];
        OCMStub([client downloadFileWithURL:OCMOCK_ANY]).andReturn(subject);

        LLSignalTestRecorder *recorder = [[manager fetchAVDataWithDescriptor:descriptor]
                                          testRecorder];

        [subject sendNext:[[PTNProgress alloc] initWithProgress:@0.25]];
        [subject sendNext:[[PTNProgress alloc] initWithProgress:@0.5]];

        expect(recorder).to.sendValues(@[
          [[PTNProgress alloc] initWithProgress:@0.25],
          [[PTNProgress alloc] initWithProgress:@0.5]
        ]);
      });

      it(@"should err when there are no download URLs", ^{
        auto noDownloadDescriptor = PTNFakeOceanNoDownloadVideoAssetDescriptor();
        RACSignal *fetch = [manager fetchAVDataWithDescriptor:noDownloadDescriptor];

        expect(fetch).to.matchError(^BOOL(NSError *error) {
          return error.code == PTNErrorCodeAssetNotFound && error.lt_isLTDomain &&
              [error.ptn_associatedDescriptor isEqual:noDownloadDescriptor];
        });
      });

      it(@"should prefer video with pixel count closest to the preferred video pixel count", ^{
        RACSubject *subject = [RACSubject subject];
        OCMStub([client downloadFileWithURL:PTNOceanCloseTo720pVideoDownloadURL()])
            .andReturn(subject);
        auto path = [LTPath temporaryPathWithExtension:@"tmp"];
        auto progress = [PTNProgress progressWithResult:path];
        auto expectedAsset = [[PTNFileBackedAVAsset alloc] initWithFilePath:path];

        LLSignalTestRecorder *recorder = [[manager fetchAVDataWithDescriptor:descriptor]
                                          testRecorder];
        [subject sendNext:progress];

        expect(recorder).to.sendValues(@[[[PTNProgress alloc] initWithResult:expectedAsset]]);
      });

      it(@"should only use video assets with non-nil download URL", ^{
        auto partialDescriptor = PTNFakeOceanPartialVideoAssetDescriptor();
        RACSubject *subject = [RACSubject subject];
        OCMStub([client downloadFileWithURL:PTNOceanCloseTo720pVideoDownloadURL()])
            .andReturn(subject);
        auto path = [LTPath temporaryPathWithExtension:@"tmp"];
        auto progress = [PTNProgress progressWithResult:path];
        auto expectedAsset = [[PTNFileBackedAVAsset alloc] initWithFilePath:path];

        LLSignalTestRecorder *recorder = [[manager fetchAVDataWithDescriptor:partialDescriptor]
                                          testRecorder];
        [subject sendNext:progress];

        expect(recorder).to.sendValues(@[[[PTNProgress alloc] initWithResult:expectedAsset]]);
      });
    });
  });
});

context(@"unsupported operations", ^{
  it(@"should err when fetching audiovisual asset", ^{
    auto options = [PTNAVAssetFetchOptions
                    optionsWithDeliveryMode:PTNAVAssetDeliveryModeAutomatic];
    RACSignal *fetch = [manager
                        fetchAVAssetWithDescriptor:OCMProtocolMock(@protocol(PTNDescriptor))
                        options:options];

    expect(fetch).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeUnsupportedOperation;
    });
  });
});

context(@"caching", ^{
  it(@"should invalidate album", ^{
    auto url = [NSURL URLWithString:kFakeURLString];
    expect([manager validateAlbumWithURL:url entityTag:@"foo"]).to.sendValues(@[@NO]);
  });

  it(@"should invalidate descriptor", ^{
    auto url = [NSURL URLWithString:kFakeURLString];
    expect([manager validateDescriptorWithURL:url entityTag:@"foo"]).to.sendValues(@[@NO]);
  });

  it(@"should invalidate image", ^{
    expect([manager validateImageWithDescriptor:OCMProtocolMock(@protocol(PTNDescriptor))
                               resizingStrategy:[PTNResizingStrategy identity]
                                        options:[PTNImageFetchOptions options]
                                      entityTag:@"foo"]).to.sendValues(@[@NO]);
  });

  it(@"should not have canonical URL", ^{
    expect([manager canonicalURLForDescriptor:OCMProtocolMock(@protocol(PTNDescriptor))
                             resizingStrategy:[PTNResizingStrategy identity]
                                      options:[PTNImageFetchOptions options]]).to.beNil();
  });
});

context(@"deallocation", ^{
  it(@"should dealloc the manager after fetch signal is disposed", ^{
    __weak PTNOceanAssetManager *weakManager;

    @autoreleasepool {
      auto manager = [[PTNOceanAssetManager alloc]
                      initWithClient:OCMClassMock([PTNOceanClient class])
                      dateProvider:dateProvider
                      preferredImageDataPixelCount:NSUIntegerMax
                      preferredVideoDataPixelCount:NSUIntegerMax];
      weakManager = manager;
      auto url = PTNFakeAlbumRequestURL();
      auto disposable = [[manager fetchDescriptorWithURL:url] subscribeNext:^(id) {}];
      [disposable dispose];
    }
    expect(weakManager).will.beNil();
  });

  it(@"should fetch values after manager is deallocated", ^{
    __weak PTNOceanAssetManager *weakManager;
    RACSignal *fetchSignal;

    @autoreleasepool {
      auto manager = [[PTNOceanAssetManager alloc]
                      initWithClient:OCMClassMock([PTNOceanClient class])
                      dateProvider:dateProvider
                      preferredImageDataPixelCount:NSUIntegerMax
                      preferredVideoDataPixelCount:NSUIntegerMax];
      weakManager = manager;
      auto url = PTNFakeAlbumRequestURL();
      fetchSignal = [manager fetchDescriptorWithURL:url];
    }
    expect(weakManager).to.beNil();
    expect(fetchSignal).will.sendValuesWithCount(1);
  });
});

SpecEnd
