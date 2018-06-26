// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "PTNOceanClient.h"

#import <AFNetworking/AFNetworking.h>
#import <Fiber/FBRHTTPClient.h>
#import <FiberTestUtils/FBRHTTPTestUtils.h>
#import <LTKit/NSBundle+Path.h>
#import <Mantle/Mantle.h>

#import "NSErrorCodes+Photons.h"
#import "PTNFileSystemTestUtils.h"
#import "PTNOceanAssetDescriptor.h"
#import "PTNOceanAssetSearchResponse.h"
#import "PTNOceanEnums.h"
#import "PTNTestResources.h"

/// Block reporting progress of URL session operations. Used by the \c AFNetworking library.
typedef void (^AFNetworkProgressBlock)(NSProgress *progress);

/// Block asking for final URL for a URL download operation. Used by the \c AFNetworking library.
typedef NSURL * _Nullable (^AFNetworkDownloadDestinationBlock)(NSURL *targetPath,
                                                               NSURLResponse *response);

/// Block providing the completion status for a URL download operation for download operation. Used
/// by the \c AFNetworking library.
typedef void (^AFNetworkDownloadCompletionBlock)(NSURLResponse *response,
                                                 NSURL * _Nullable filePath,
                                                 NSError * _Nullable error);

static FBRHTTPRequestParameters *PTNFakeBaseRequestParameters() {
  return @{
    @"idfv": [UIDevice currentDevice].identifierForVendor.UUIDString,
    @"bundle": [NSBundle mainBundle].bundleIdentifier
  };
}

static FBRHTTPResponse *PTNFakeHTTPResponse(NSData *data, NSString * _Nullable mimeType = nil) {
  auto headers = mimeType ? @{@"Content-Type": mimeType} : nil;
  return FBRFakeHTTPResponse(@"https://foo.bar", 200, headers, data);
}

SpecBegin(PTNOceanClient)

__block FBRHTTPClient *oceanClient;
__block FBRHTTPClient *dataClient;
__block AFHTTPSessionManager *sessionManager;
__block PTNOceanClient *client;

beforeEach(^{
  oceanClient = OCMClassMock([FBRHTTPClient class]);
  dataClient = OCMClassMock([FBRHTTPClient class]);
  sessionManager = OCMClassMock([AFHTTPSessionManager class]);

  client = [[PTNOceanClient alloc] initWithOceanClient:oceanClient dataClient:dataClient
                                        sessionManager:sessionManager];
});

context(@"asset search", ^{
  it(@"should use image search endpoint when searching for images", ^{
    auto parameters = [[PTNOceanSearchParameters alloc] initWithType:$(PTNOceanAssetTypePhoto)
                                                              source:$(PTNOceanAssetSourcePixabay)
                                                              phrase:@"foo" page:3];
    OCMExpect([oceanClient GET:@"image/search"
               withParameters:OCMOCK_ANY headers:nil]);

    auto __unused recorder = [[client searchWithParameters:parameters] testRecorder];

    OCMVerifyAll((id)oceanClient);
  });

  it(@"should use image search endpoint when searching for videos", ^{
    auto parameters = [[PTNOceanSearchParameters alloc] initWithType:$(PTNOceanAssetTypeVideo)
                                                              source:$(PTNOceanAssetSourcePixabay)
                                                              phrase:@"foo" page:3];
    OCMExpect([oceanClient GET:@"video/search"
               withParameters:OCMOCK_ANY headers:nil]);

    auto __unused recorder = [[client searchWithParameters:parameters] testRecorder];

    OCMVerifyAll((id)oceanClient);
  });

  it(@"should use parameters from request URL when issuing album search request", ^{
    auto parameters = [[PTNOceanSearchParameters alloc] initWithType:$(PTNOceanAssetTypeVideo)
                                                              source:$(PTNOceanAssetSourcePixabay)
                                                              phrase:@"foo" page:3];
    auto expectedParameters = [@{
      @"phrase": @"foo",
      @"page": @"3",
      @"source_id": @"pixabay"
    } mtl_dictionaryByAddingEntriesFromDictionary:PTNFakeBaseRequestParameters()];
    OCMExpect([oceanClient GET:OCMOCK_ANY withParameters:expectedParameters headers:nil]);

    auto __unused recorder = [[client searchWithParameters:parameters] testRecorder];

    OCMVerifyAll((id)oceanClient);
  });

  it(@"should return search result", ^{
    auto parameters = [[PTNOceanSearchParameters alloc] initWithType:$(PTNOceanAssetTypeVideo)
                                                              source:$(PTNOceanAssetSourcePixabay)
                                                              phrase:@"foo" page:3];
    RACSubject *subject = [RACSubject subject];
    OCMStub([oceanClient GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
        .andReturn(subject);
    LLSignalTestRecorder *recorder = [[client searchWithParameters:parameters] testRecorder];

    auto responseURL = PTNOceanSearchResponseJSONURL();
    auto data = [NSData dataWithContentsOfURL:responseURL];
    NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    PTNOceanAssetSearchResponse *expectedDescriptor =
        [MTLJSONAdapter modelOfClass:[PTNOceanAssetSearchResponse class] fromJSONDictionary:results
                               error:nil];
    LTAssert(expectedDescriptor);
    [subject sendNext:[[LTProgress alloc] initWithResult:PTNFakeHTTPResponse(data)]];
    [subject sendCompleted];

    expect(recorder).to.sendValues(@[expectedDescriptor]);
    expect(recorder).to.complete();
  });

  it(@"should err when http client errs", ^{
    auto parameters = [[PTNOceanSearchParameters alloc] initWithType:$(PTNOceanAssetTypeVideo)
                                                              source:$(PTNOceanAssetSourcePixabay)
                                                              phrase:@"foo" page:3];
    RACSubject *request = [RACSubject subject];
    OCMStub([oceanClient GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
        .andReturn(request);
    LLSignalTestRecorder *recorder = [[client searchWithParameters:parameters] testRecorder];

    auto error = [NSError lt_errorWithCode:1337];
    [request sendError:error];

    expect(recorder.error.code).to.equal(PTNErrorCodeRemoteFetchFailed);
    expect(recorder.error.lt_isLTDomain).to.beTruthy();
  });
});

context(@"asset descriptor fetch", ^{
  it(@"should use image search endpoint when searching for images", ^{
    auto parameters = [[PTNOceanAssetFetchParameters alloc]
                       initWithType:$(PTNOceanAssetTypePhoto)
                       source:$(PTNOceanAssetSourcePixabay)
                       identifier:@"bar"];
    auto expectedParameters = [@{
      @"source_id": @"pixabay"
    } mtl_dictionaryByAddingEntriesFromDictionary:PTNFakeBaseRequestParameters()];
    OCMExpect([oceanClient GET:@"image/asset/bar"
               withParameters:expectedParameters headers:nil]);

    auto __unused recorder = [[client fetchAssetDescriptorWithParameters:parameters] testRecorder];

    OCMVerifyAll((id)oceanClient);
  });

    it(@"should use video search endpoint when searching for videos", ^{
    auto parameters = [[PTNOceanAssetFetchParameters alloc]
                       initWithType:$(PTNOceanAssetTypeVideo)
                       source:$(PTNOceanAssetSourcePixabay)
                       identifier:@"bar"];
    auto expectedParameters = [@{
      @"source_id": @"pixabay"
    } mtl_dictionaryByAddingEntriesFromDictionary:PTNFakeBaseRequestParameters()];
    OCMExpect([oceanClient GET:@"video/asset/bar"
               withParameters:expectedParameters headers:nil]);

    auto __unused recorder = [[client fetchAssetDescriptorWithParameters:parameters] testRecorder];

    OCMVerifyAll((id)oceanClient);
  });

  it(@"should fetch image asset descriptor", ^{
    auto parameters = [[PTNOceanAssetFetchParameters alloc]
                       initWithType:$(PTNOceanAssetTypePhoto)
                       source:$(PTNOceanAssetSourcePixabay)
                       identifier:@"bar"];

    auto responseURL = PTNOceanPhotoAssetDescriptorJSONURL();
    auto *data = [NSData dataWithContentsOfURL:responseURL];
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0
                                                                     error:nil];
    PTNOceanAssetSearchResponse *expectedDescriptor =
        [MTLJSONAdapter modelOfClass:[PTNOceanAssetDescriptor class]
                  fromJSONDictionary:jsonDictionary error:nil];

    RACSubject *subject = [RACSubject subject];
    OCMStub([oceanClient GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
        .andReturn(subject);
    LLSignalTestRecorder *recorder = [[client fetchAssetDescriptorWithParameters:parameters]
                                      testRecorder];
    [subject sendNext:[[LTProgress alloc] initWithResult:PTNFakeHTTPResponse(data)]];
    [subject sendCompleted];

    expect(recorder).to.sendValues(@[expectedDescriptor]);
    expect(recorder).to.complete();
  });

  it(@"should fetch video asset descriptor", ^{
    auto parameters = [[PTNOceanAssetFetchParameters alloc]
                       initWithType:$(PTNOceanAssetTypeVideo)
                       source:$(PTNOceanAssetSourcePixabay)
                       identifier:@"bar"];

    auto responseURL = PTNOceanVideoAssetDescriptorJSONURL();
    auto *data = [NSData dataWithContentsOfURL:responseURL];
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0
                                                                     error:nil];
    PTNOceanAssetSearchResponse *expectedDescriptor =
        [MTLJSONAdapter modelOfClass:[PTNOceanAssetDescriptor class]
                  fromJSONDictionary:jsonDictionary error:nil];

    RACSubject *subject = [RACSubject subject];
    OCMStub([oceanClient GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
        .andReturn(subject);
    LLSignalTestRecorder *recorder = [[client fetchAssetDescriptorWithParameters:parameters]
                                      testRecorder];
    [subject sendNext:[[LTProgress alloc] initWithResult:PTNFakeHTTPResponse(data)]];
    [subject sendCompleted];

    expect(recorder).to.sendValues(@[expectedDescriptor]);
    expect(recorder).to.complete();
  });
});

context(@"data download", ^{
  __block NSString *urlString;
  __block NSURL *url;
  __block RACSubject *subject;

  beforeEach(^{
    urlString = @"http://foo/bar.jpg";
    url = [NSURL URLWithString:urlString];
    subject = [RACSubject subject];
  });

  it(@"should send progress", ^{
    OCMStub([dataClient GET:urlString withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
        .andReturn(subject);

    LLSignalTestRecorder *recorder = [[client downloadDataWithURL:url] testRecorder];

    [subject sendNext:[[LTProgress alloc] initWithProgress:0.25]];
    [subject sendNext:[[LTProgress alloc] initWithProgress:0.5]];

    expect(recorder).to.sendValues(@[
      [[PTNProgress alloc] initWithProgress:@0.25],
      [[PTNProgress alloc] initWithProgress:@0.5]
    ]);
  });

  it(@"should send the data downloaded", ^{
    OCMStub([dataClient GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
        .andReturn(subject);
    NSData *data = [NSData data];

    LLSignalTestRecorder *recorder = [[client downloadDataWithURL:url] testRecorder];

    [subject sendNext:[[LTProgress alloc] initWithResult:PTNFakeHTTPResponse(data)]];

    expect(recorder).to.sendValues(@[
      [[PTNProgress alloc] initWithResult:RACTuplePack(data, nil)]
    ]);
  });

  it(@"should send the data downloaded and convert mime type to UTI", ^{
    OCMStub([dataClient GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
        .andReturn(subject);
    NSData *data = [NSData data];

    LLSignalTestRecorder *recorder = [[client downloadDataWithURL:url] testRecorder];

    [subject sendNext:[[LTProgress alloc] initWithResult:PTNFakeHTTPResponse(data, @"image/jpeg")]];

    expect(recorder).to.sendValues(@[
      [[PTNProgress alloc] initWithResult:RACTuplePack(data, (__bridge NSString *)kUTTypeJPEG)]
    ]);
  });

  it(@"should err when underlying client errs", ^{
    OCMStub([dataClient GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
        .andReturn(subject);
    auto underlyingError = [NSError lt_errorWithCode:1337];

    LLSignalTestRecorder *recorder = [[client downloadDataWithURL:url] testRecorder];

    [subject sendError:underlyingError];

    expect(recorder).to.sendError([NSError lt_errorWithCode:PTNErrorCodeRemoteFetchFailed
                                            underlyingError:underlyingError]);
  });
});

context(@"file download", ^{
  __block NSURLSessionDownloadTask *task;
  __block NSURL *url;

  beforeEach(^{
    url = [NSURL URLWithString:@"scheme://foo.com/bar.jpg"];
    task = OCMClassMock([NSURLSessionDownloadTask class]);
  });

  it(@"should resume the task when subscribed to", ^{
    OCMStub([sessionManager
             downloadTaskWithRequest:[OCMArg checkWithBlock:^BOOL(NSURLRequest *request) {
      return [request.URL isEqual:url];
    }] progress:OCMOCK_ANY destination:OCMOCK_ANY completionHandler:OCMOCK_ANY]).andReturn(task);
    OCMExpect([task resume]);

    auto __unused recorder = [[client downloadFileWithURL:url] testRecorder];
    OCMVerifyAll((id)task);
  });

  it(@"should forward progress values when reported by the session", ^{
    auto *progress = [NSProgress progressWithTotalUnitCount:100];
    __block AFNetworkProgressBlock progressBlock;
    OCMStub([sessionManager
             downloadTaskWithRequest:OCMOCK_ANY progress:OCMOCK_ANY destination:OCMOCK_ANY
             completionHandler:OCMOCK_ANY]).andReturn(task).andDo(^(NSInvocation *invocation) {
      AFNetworkProgressBlock __unsafe_unretained _progressBlock;
      [invocation getArgument:&_progressBlock atIndex:3];
      progressBlock = [_progressBlock copy];
    });

    auto *recorder = [[client downloadFileWithURL:url] testRecorder];

    progress.completedUnitCount = 0;
    progressBlock(progress);
    progress.completedUnitCount = 50;
    progressBlock(progress);
    progress.completedUnitCount = 100;
    progressBlock(progress);

    expect(recorder).to.sendValues(@[
      [[PTNProgress alloc] initWithProgress:@0],
      [[PTNProgress alloc] initWithProgress:@0.5],
      [[PTNProgress alloc] initWithProgress:@1]
    ]);
    expect(recorder).toNot.complete();
  });

  it(@"should send a path to the temporary file that was downloaded", ^{
    __block AFNetworkDownloadDestinationBlock destinationBlock;
    __block AFNetworkDownloadCompletionBlock completionBlock;
    OCMStub([sessionManager
             downloadTaskWithRequest:OCMOCK_ANY progress:OCMOCK_ANY destination:OCMOCK_ANY
             completionHandler:OCMOCK_ANY]).andReturn(task).andDo(^(NSInvocation *invocation) {
      AFNetworkDownloadDestinationBlock __unsafe_unretained _destinationBlock;
      AFNetworkDownloadCompletionBlock __unsafe_unretained _completionBlock;
      [invocation getArgument:&_destinationBlock atIndex:4];
      [invocation getArgument:&_completionBlock atIndex:5];
      destinationBlock = [_destinationBlock copy];
      completionBlock = [_completionBlock copy];
    });

    auto recorder = [[client downloadFileWithURL:url] testRecorder];
    auto response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:nil
                                              headerFields:nil];

    auto downloadURL = destinationBlock([NSURL URLWithString:@"file://some/path.tmp"], response);
    [[NSFileManager defaultManager] copyItemAtURL:PTNOneSecondVideoURL() toURL:downloadURL
                                            error:nil];

    completionBlock(response, downloadURL, nil);

    expect(recorder).to.sendValuesWithCount(1);
    expect(recorder.values[0]).to.beKindOf([PTNProgress class]);
    expect(((PTNProgress *)recorder.values[0]).result).to.beKindOf([LTPath class]);
    LTPath *resultPath = ((PTNProgress *)recorder.values[0]).result;
    NSData *fileData = [NSData dataWithContentsOfURL:resultPath.url];
    auto assetData = [NSData dataWithContentsOfURL:PTNOneSecondVideoURL()];
    expect(fileData).equal(assetData);
    expect(recorder).to.complete();
  });

  it(@"should send a path to the temporary file that was downloaded with UTI from the MIME type", ^{
    __block AFNetworkDownloadDestinationBlock destinationBlock;
    __block AFNetworkDownloadCompletionBlock completionBlock;
    OCMStub([sessionManager
             downloadTaskWithRequest:OCMOCK_ANY progress:OCMOCK_ANY destination:OCMOCK_ANY
             completionHandler:OCMOCK_ANY]).andReturn(task).andDo(^(NSInvocation *invocation) {
      AFNetworkDownloadDestinationBlock __unsafe_unretained _destinationBlock;
      AFNetworkDownloadCompletionBlock __unsafe_unretained _completionBlock;
      [invocation getArgument:&_destinationBlock atIndex:4];
      [invocation getArgument:&_completionBlock atIndex:5];
      destinationBlock = [_destinationBlock copy];
      completionBlock = [_completionBlock copy];
    });

    auto recorder = [[client downloadFileWithURL:url] testRecorder];
    auto response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:nil
                                              headerFields:@{ @"Content-Type": @"video/mp4" }];

    auto downloadURL = destinationBlock([NSURL URLWithString:@"file://some/path.tmp"], response);
    [[NSFileManager defaultManager] copyItemAtURL:PTNOneSecondVideoURL() toURL:downloadURL
                                            error:nil];

    completionBlock(response, downloadURL, nil);

    expect(recorder).to.sendValuesWithCount(1);
    expect(recorder.values[0]).to.beKindOf([PTNProgress class]);
    expect(((PTNProgress *)recorder.values[0]).result).to.beKindOf([LTPath class]);
    LTPath *resultPath = ((PTNProgress *)recorder.values[0]).result;
    expect([resultPath.path pathExtension]).to.equal(@"mp4");
  });

  context(@"download errors", ^{
    __block NSHTTPURLResponse *validResponse;
    __block NSURL *downloadURL;

    beforeEach(^{
      validResponse = OCMClassMock([NSHTTPURLResponse class]);
      OCMStub(validResponse.statusCode).andReturn(200);
      downloadURL = [LTPath temporaryPathWithExtension:@"mp4"].url;
    });

    it(@"should err when output URL is nil", ^{
      NSError *underlyingError = [NSError lt_errorWithCode:1337];
      OCMStub([sessionManager
               downloadTaskWithRequest:OCMOCK_ANY progress:OCMOCK_ANY destination:OCMOCK_ANY
               completionHandler:([OCMArg invokeBlockWithArgs:validResponse, [NSNull null],
                                   underlyingError, nil])]).andReturn(task);

      auto *recorder = [[client downloadFileWithURL:url] testRecorder];

      expect(recorder).to.sendError([NSError lt_errorWithCode:PTNErrorCodeRemoteFetchFailed
                                              underlyingError:underlyingError]);
    });

    it(@"should err when response is nil", ^{
      NSError *underlyingError = [NSError lt_errorWithCode:1337];
      OCMStub([sessionManager
               downloadTaskWithRequest:OCMOCK_ANY progress:OCMOCK_ANY destination:OCMOCK_ANY
               completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null], downloadURL,
                                   underlyingError, nil])]).andReturn(task);

      auto *recorder = [[client downloadFileWithURL:url] testRecorder];

      expect(recorder).to.sendError([NSError lt_errorWithCode:PTNErrorCodeRemoteFetchFailed
                                              underlyingError:underlyingError]);
    });

    it(@"should err when response is invalid", ^{
      NSError *underlyingError = [NSError lt_errorWithCode:1337];
      auto invalidResponse = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:404
                                                        HTTPVersion:nil headerFields:nil];
      OCMStub([sessionManager
               downloadTaskWithRequest:OCMOCK_ANY progress:OCMOCK_ANY destination:OCMOCK_ANY
               completionHandler:([OCMArg invokeBlockWithArgs:invalidResponse, downloadURL,
                                   underlyingError, nil])]).andReturn(task);

      auto *recorder = [[client downloadFileWithURL:url] testRecorder];

      expect(recorder).to.sendError([NSError lt_errorWithCode:PTNErrorCodeRemoteFetchFailed
                                              underlyingError:underlyingError]);
    });

    it(@"should err when response is not an HTTP response", ^{
      NSError *underlyingError = [NSError lt_errorWithCode:1337];
      auto urlResponse = [[NSURLResponse alloc] initWithURL:url
                                                  MIMEType:@"video/mp4"
                                     expectedContentLength:1337
                                          textEncodingName:nil];

      OCMStub([sessionManager
               downloadTaskWithRequest:OCMOCK_ANY progress:OCMOCK_ANY destination:OCMOCK_ANY
               completionHandler:([OCMArg invokeBlockWithArgs:urlResponse, downloadURL,
                                   underlyingError, nil])]).andReturn(task);

      auto *recorder = [[client downloadFileWithURL:url] testRecorder];

      expect(recorder).to.sendError([NSError lt_errorWithCode:PTNErrorCodeRemoteFetchFailed
                                              underlyingError:underlyingError]);
    });
  });

  it(@"should cancel the task when unsubscribed", ^{
    OCMExpect([task cancel]);
    OCMStub([sessionManager
             downloadTaskWithRequest:OCMOCK_ANY progress:OCMOCK_ANY destination:OCMOCK_ANY
             completionHandler:OCMOCK_ANY]).andReturn(task);
    [[[client downloadFileWithURL:url] subscribeNext:^(id __unused x) {}] dispose];

    OCMVerifyAll((id)task);
  });
});

SpecEnd
