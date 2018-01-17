// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanAssetManager.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPResponse.h>
#import <Fiber/NSErrorCodes+Fiber.h>
#import <Fiber/RACSignal+Fiber.h>
#import <LTKit/LTPath.h>
#import <LTKit/LTProgress.h>
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
#import "PTNImageFetchOptions.h"
#import "PTNImageMetadata.h"
#import "PTNOceanAlbumDescriptor.h"
#import "PTNOceanAssetDescriptor.h"
#import "PTNOceanAssetSearchResponse.h"
#import "PTNOceanEnums.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"
#import "PTNStaticImageAsset.h"
#import "RACSignal+Mantle.h"

static FBRHTTPRequestParameters *PTNFakeRequestParameters() {
  return @{
    @"source_id": @"pixabay",
    @"idfv": [UIDevice currentDevice].identifierForVendor.UUIDString
  };
}

static PTNCacheProxy *PTNAssetCacheProxy(NSData *data, id<PTNResizingStrategy> resizingStrategy,
                                         NSDate *responseTime) {
  auto result = [[PTNDataBackedImageAsset alloc] initWithData:data
                                             resizingStrategy:resizingStrategy];
  auto cacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:86400 responseTime:responseTime
                                              entityTag:nil];
 return [[PTNCacheProxy<PTNAlbum> alloc] initWithUnderlyingObject:result cacheInfo:cacheInfo];
}

static NSURL *PTNFakeAlbumRequestURL(NSUInteger page = 2) {
  return [NSURL ptn_oceanAlbumURLWithSource:$(PTNOceanAssetSourcePixabay) phrase:@"foo" page:page];
}

static LTProgress *PTNFakeLTProgress(NSData *data) {
  FBRHTTPResponse *response = OCMClassMock([FBRHTTPResponse class]);
  OCMStub([response content]).andReturn(data);
  return [[LTProgress alloc] initWithResult:response];
}

SpecBegin(PTNOceanAssetManager)

static NSString * const kFakeURLString = @"http://foo.bar";

__block NSURL *requestURL;
__block id client;
__block PTNOceanAssetManager *manager;
__block PTNDateProvider *dateProvider;
__block NSDate *date;

beforeEach(^{
  requestURL = PTNFakeAlbumRequestURL();
  client = OCMClassMock([FBRHTTPClient class]);
  dateProvider = OCMClassMock([PTNDateProvider class]);
  date = [NSDate date];
  OCMStub([dateProvider date]).andReturn(date);
  manager = [[PTNOceanAssetManager alloc] initWithClient:client dateProvider:dateProvider];
});

context(@"fetching albums", ^{
  context(@"valid URL", ^{
    it(@"should use correct request arguments", ^{
      NSMutableDictionary *expectedParameters = [PTNFakeRequestParameters() mutableCopy];
      expectedParameters[@"phrase"] = @"foo";
      expectedParameters[@"page"] = @"2";
      NSString *expectedURLString = @"https://ocean.lightricks.com/search";
      OCMExpect([client GET:expectedURLString withParameters:expectedParameters headers:nil]);

      auto __unused recorder = [[manager fetchAlbumWithURL:requestURL] testRecorder];

      OCMVerifyAll(client);
    });

    it(@"should fetch album", ^{
      RACSubject *request = [RACSubject subject];
      OCMStub([client GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
          .andReturn(request);
      LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:requestURL] testRecorder];

      NSString *path = [NSBundle lt_pathForResource:@"OceanFakeSearchResponse.json"
                                          nearClass:[self class]];
      NSData *data = [NSData dataWithContentsOfFile:path];
      NSArray *results = [NSJSONSerialization JSONObjectWithData:data options:0
                                                           error:nil][@"results"];
      PTNOceanAssetDescriptor *expectedDescriptor = [MTLJSONAdapter
                                                     modelOfClass:[PTNOceanAssetDescriptor class]
                                                     fromJSONDictionary:results.firstObject
                                                     error:nil];

      [request sendNext:PTNFakeLTProgress(data)];

      id<PTNAlbum> album = [[PTNAlbum alloc] initWithURL:requestURL subalbums:@[]
                                                  assets:@[expectedDescriptor]
                                            nextAlbumURL:PTNFakeAlbumRequestURL(3)];
      auto cacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:300 responseTime:date entityTag:nil];
      auto cacheProxy = [[PTNCacheProxy<PTNAlbum> alloc] initWithUnderlyingObject:album
                                                                        cacheInfo:cacheInfo];

      expect(expectedDescriptor).toNot.beNil();
      expect(recorder).to.sendValues(@[[PTNAlbumChangeset changesetWithAfterAlbum:cacheProxy]]);
    });

    it(@"should not have next album for the last page", ^{
      RACSubject *request = [RACSubject subject];
      OCMStub([client GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
          .andReturn(request);
      LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:requestURL] testRecorder];

      NSString *path = [NSBundle lt_pathForResource:@"OceanFakeSearchResponseLastPage.json"
                                          nearClass:[self class]];

      [request sendNext:PTNFakeLTProgress([NSData dataWithContentsOfFile:path])];

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
      RACSubject *request = [RACSubject subject];
      OCMStub([client GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
          .andReturn(request);
      LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:requestURL] testRecorder];

      [request sendNext:PTNFakeLTProgress(nil)];

      expect(recorder).to.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAlbumNotFound &&
            error.lt_underlyingError.code == PTNErrorCodeDeserializationFailed;
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
    __block NSURL *assetRequestURL;

    beforeEach(^{
      assetRequestURL = [NSURL ptn_oceanAssetURLWithSource:$(PTNOceanAssetSourcePixabay)
                                                identifier:@"bar"];
    });

    it(@"should use correct request arguments", ^{
      FBRHTTPRequestParameters *expectedParameters = PTNFakeRequestParameters();
      NSString *expectedURLString = @"https://ocean.lightricks.com/asset/bar";
      OCMExpect([client GET:expectedURLString withParameters:expectedParameters headers:nil]);

      auto __unused recorder = [[manager fetchDescriptorWithURL:assetRequestURL] testRecorder];

      OCMVerifyAll(client);
    });

    it(@"should fetch asset descriptor", ^{
      NSString *path = [NSBundle lt_pathForResource:@"OceanFakeAssetResponse.json"
                                          nearClass:[self class]];
      NSData *data = [NSData dataWithContentsOfFile:path];
      NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0
                                                           error:nil];
      PTNOceanAssetDescriptor *expectedDescriptor = [MTLJSONAdapter
                                                     modelOfClass:[PTNOceanAssetDescriptor class]
                                                     fromJSONDictionary:jsonDictionary
                                                     error:nil];
      auto cacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:86400 responseTime:date entityTag:nil];
      auto cacheProxy = [[PTNCacheProxy<PTNAlbum> alloc] initWithUnderlyingObject:expectedDescriptor
                                                                        cacheInfo:cacheInfo];

      RACSubject *subject = [RACSubject subject];
      OCMStub([client GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
          .andReturn(subject);
      LLSignalTestRecorder *recorder =
          [[manager fetchDescriptorWithURL:assetRequestURL] testRecorder];

      [subject sendNext:PTNFakeLTProgress(data)];

      expect(expectedDescriptor).toNot.beNil();
      expect(recorder).to.sendValues(@[cacheProxy]);
    });

    it(@"should forward deserialization errors", ^{
      NSError *error = [NSError lt_errorWithCode:71070];
      RACSubject *subject = [RACSubject subject];
      RACSignal *request = OCMClassMock([RACSignal class]);
      OCMStub([request fbr_deserializeJSON]).andReturn(request);
      OCMStub([request ptn_parseDictionaryWithClass:[PTNOceanAssetDescriptor class]])
          .andReturn(subject);
      OCMStub([client GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
          .andReturn(request);
      LLSignalTestRecorder *recorder =
          [[manager fetchDescriptorWithURL:assetRequestURL] testRecorder];

      [subject sendError:error];

      expect(recorder).to.sendError([NSError lt_errorWithCode:PTNErrorCodeAssetLoadingFailed
                                                          url:assetRequestURL
                                              underlyingError:error]);
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
                        resizingStrategy:OCMProtocolMock(@protocol(PTNResizingStrategy))
                        options:OCMClassMock([PTNImageFetchOptions class])];

    expect(fetch).to.sendError([NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                     associatedDescriptor:invalidDescriptor]);
  });

  context(@"ocean descriptors", ^{
    context(@"invalid descriptors", ^{
      it(@"should send error if there are no available assets", ^{
        PTNOceanAssetDescriptor *invalidDescriptor = [MTLJSONAdapter
                                                      modelOfClass:[PTNOceanAssetDescriptor class]
                                                      fromJSONDictionary:@{
          @"all_sizes": @[],
          @"asset_type": @"photo",
          @"source_id": @"pixabay",
          @"id": @"foo"
        } error:nil];
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
        NSString *path = [NSBundle lt_pathForResource:@"OceanFakeAssetResponse.json"
                                          nearClass:[self class]];
        NSData *data = [NSData dataWithContentsOfFile:path];
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0
                                                                         error:nil];
        descriptor = [MTLJSONAdapter modelOfClass:[PTNOceanAssetDescriptor class]
                               fromJSONDictionary:jsonDictionary error:nil];

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
        OCMStub([client GET:@"http://b" withParameters:nil headers:nil]).andReturn(subject);

        LLSignalTestRecorder *recorder = [[manager fetchImageWithDescriptor:descriptor
                                                           resizingStrategy:resizingStrategy
                                                                    options:options] testRecorder];

        [subject sendNext:[[LTProgress alloc] initWithProgress:0.25]];
        [subject sendNext:[[LTProgress alloc] initWithProgress:0.5]];

        expect(recorder).to.sendValues(@[
          [[PTNProgress alloc] initWithProgress:@0.25],
          [[PTNProgress alloc] initWithProgress:@0.5]
        ]);
      });

      it(@"should fetch image in fast delivery mode", ^{
        OCMStub([options deliveryMode]).andReturn(PTNImageDeliveryModeFast);

        RACSubject *subject = [RACSubject subject];
        OCMStub([client GET:@"http://a" withParameters:nil headers:nil]).andReturn(subject);
        NSData *data = OCMClassMock([NSData class]);
        LTProgress *progress = PTNFakeLTProgress(data);

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

        RACSubject *subject = [RACSubject subject];
        OCMStub([client GET:@"http://b" withParameters:nil headers:nil]).andReturn(subject);
        NSData *data = OCMClassMock([NSData class]);
        LTProgress *progress = PTNFakeLTProgress(data);

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

        RACSubject *subject = [RACSubject subject];
        OCMStub([client GET:@"http://c" withParameters:nil headers:nil]).andReturn(subject);
        NSData *data = OCMClassMock([NSData class]);
        LTProgress *progress = PTNFakeLTProgress(data);
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
        OCMStub([client GET:@"http://a" withParameters:nil headers:nil]).andReturn(lowQuality);
        NSData *lowQualityData = OCMClassMock([NSData class]);
        LTProgress *lowQualityProgress = PTNFakeLTProgress(lowQualityData);

        RACSubject *highQuality = [RACSubject subject];
        OCMStub([client GET:@"http://b" withParameters:nil headers:nil]).andReturn(highQuality);
        NSData *highQualityData = OCMClassMock([NSData class]);
        LTProgress *highQualityProgress = PTNFakeLTProgress(highQualityData);

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

        RACSubject *subject = [RACSubject subject];
        OCMStub([client GET:@"http://a" withParameters:nil headers:nil]).andReturn(subject);
        NSData *data = OCMClassMock([NSData class]);
        LTProgress *progress = PTNFakeLTProgress(data);

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

context(@"unsupported operations", ^{
  it(@"should send error when attempting to fetch audiovisual asset", ^{
    RACSignal *fetch = [manager
                        fetchAVAssetWithDescriptor:OCMProtocolMock(@protocol(PTNDescriptor))
                        options:OCMClassMock([PTNAVAssetFetchOptions class])];

    expect(fetch).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeUnsupportedOperation;
    });
  });

  it(@"should send error when attempting to fetch image data", ^{
    RACSignal *fetch =
        [manager fetchImageDataWithDescriptor:OCMProtocolMock(@protocol(PTNDescriptor))];

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
                               resizingStrategy:OCMProtocolMock(@protocol(PTNResizingStrategy))
                                        options:OCMClassMock([PTNImageFetchOptions class])
                                      entityTag:@"foo"]).to.sendValues(@[@NO]);
  });

  it(@"should not have canonical URL", ^{
    expect([manager
            canonicalURLForDescriptor:OCMProtocolMock(@protocol(PTNDescriptor))
            resizingStrategy:OCMProtocolMock(@protocol(PTNResizingStrategy))
            options:OCMClassMock([PTNImageFetchOptions class])]).to.beNil();
  });
});

context(@"deallocation", ^{
  it(@"should dealloc the manager after fetch signal is disposed", ^{
    __weak PTNOceanAssetManager *weakManager;

    @autoreleasepool {
      auto manager = [[PTNOceanAssetManager alloc]
                      initWithClient:OCMClassMock([FBRHTTPClient class])
                      dateProvider:OCMClassMock([PTNDateProvider class])];
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
                      initWithClient:OCMClassMock([FBRHTTPClient class])
                      dateProvider:OCMClassMock([PTNDateProvider class])];
      weakManager = manager;
      auto url = PTNFakeAlbumRequestURL();
      fetchSignal = [manager fetchDescriptorWithURL:url];
    }
    expect(weakManager).to.beNil();
    expect(fetchSignal).will.sendValuesWithCount(1);
  });
});

SpecEnd
