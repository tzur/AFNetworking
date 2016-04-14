// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxRestClient.h"

#import <DropboxSDK/DropboxSDK.h>

#import "NSError+Photons.h"
#import "PTNDropboxPathProvider.h"
#import "PTNDropboxRestClientProvider.h"
#import "PTNDropboxThumbnail.h"
#import "PTNProgress.h"
#import "RACSignal+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNDropboxRestClient () <DBRestClientDelegate>

/// Dropbox session used to create REST clients with which to make API calls.
@property (strong, nonatomic) id<PTNDropboxRestClientProvider> restClientProvider;

/// Path provider to supply local paths for files to be saved in.
@property (strong, nonatomic) id<PTNDropboxPathProvider> pathProvider;

@end

@implementation PTNDropboxRestClient

- (instancetype)initWithRestClientProvider:(id<PTNDropboxRestClientProvider>)restClientProvider
                              pathProvider:(id<PTNDropboxPathProvider>)pathProvider {
  if (self = [super init]) {
    self.restClientProvider = restClientProvider;
    self.pathProvider = pathProvider;
  }
  return self;
}

#pragma mark -
#pragma mark Metadata fetching
#pragma mark -

- (RACSignal *)fetchMetadata:(NSString *)path revision:(nullable NSString *)revision {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    if (![self.restClientProvider isLinked]) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeNotAuthorized]];
      return nil;
    }

    DBRestClient *restClient = [self.restClientProvider ptn_restClient];
    restClient.delegate = self;

    // Using \c subscribe: internally stores disposables within the subscriber, so there's no need
    // to explicitly dispose them.
    [[self loadMetadataFailedForDropboxPath:path restClient:restClient] subscribe:subscriber];
    [[self metadataLoadedForDropboxPath:path revision:revision restClient:restClient]
        subscribe:subscriber];

    if (revision) {
      [restClient loadMetadata:path atRev:revision];
    } else {
      [restClient loadMetadata:path];
    }
    
    return nil;
  }];
}

- (RACSignal *)metadataLoadedForDropboxPath:(NSString *)path revision:(nullable NSString *)revision
                                 restClient:(DBRestClient *)restClient {
  return [[[[self rac_signalForSelector:(@selector(restClient:loadedMetadata:))
                           fromProtocol:@protocol(DBRestClientDelegate)]
      filter:^BOOL(RACTuple *tuple) {
        RACTupleUnpack(DBRestClient *client, DBMetadata *metadata) = tuple;
        return client == restClient &&
               [metadata.path isEqualToString:path] &&
               ([metadata.rev isEqualToString:revision] || !revision);
      }]
      reduceEach:^(DBRestClient __unused *client, DBMetadata *metadata) {
        return metadata;
      }]
      take:1];
}

- (RACSignal *)loadMetadataFailedForDropboxPath:(NSString *)dropboxPath
                                     restClient:(DBRestClient *)restClient{
  RACSignal *allMetadataErrors =
      [self rac_signalForSelector:@selector(restClient:loadMetadataFailedWithError:)
                     fromProtocol:@protocol(DBRestClientDelegate)];

  return [self liftSignal:allMetadataErrors toErrorWithCode:PTNErrorCodeAssetLoadingFailed
                  forPath:dropboxPath andClient:(DBRestClient *)restClient];
}

#pragma mark -
#pragma mark File fetching
#pragma mark -

- (RACSignal *)fetchFile:(NSString *)path revision:(nullable NSString *)revision {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    if (![self.restClientProvider isLinked]) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeNotAuthorized]];
      return nil;
    }

    NSString *localPath = [self.pathProvider localPathForFileInPath:path revision:revision];
    DBRestClient *restClient = [self.restClientProvider ptn_restClient];
    restClient.delegate = self;

    // Using \c subscribe: internally stores disposables within the subscriber, so there's no need
    // to explicitly dispose them.
    [[self loadedFileToLocalPath:localPath restClient:restClient] subscribe:subscriber];
    [[self loadFileError:path restClient:restClient] subscribe:subscriber];
    [[self loadFileProgress:localPath restClient:restClient] subscribe:subscriber];

    if (revision) {
      [restClient loadFile:path atRev:revision intoPath:localPath];
    } else {
      [restClient loadFile:path intoPath:localPath];
    }

    return [RACDisposable disposableWithBlock:^{
      [restClient cancelFileLoad:path];
    }];
  }];
}

- (RACSignal *)loadedFileToLocalPath:(NSString *)localPath restClient:(DBRestClient *)restClient {
  return [[[[[self rac_signalForSelector:@selector(restClient:loadedFile:)
                           fromProtocol:@protocol(DBRestClientDelegate)]
      filter:^BOOL(RACTuple *tuple) {
        RACTupleUnpack(DBRestClient *client, NSString *destPath) = tuple;
        return client == restClient && [destPath isEqualToString:localPath];
      }]
      reduceEach:^(DBRestClient __unused *client, NSString *destPath) {
        return destPath;
      }]
      map:^(NSString *localPath) {
        return [[PTNProgress alloc] initWithResult:localPath];
      }]
      take:1];
}

- (RACSignal *)loadFileError:(NSString *)dropboxPath restClient:(DBRestClient *)restClient {
  RACSignal *allFileErrors =
      [self rac_signalForSelector:@selector(restClient:loadFileFailedWithError:)
                     fromProtocol:@protocol(DBRestClientDelegate)];

  return [self liftSignal:allFileErrors toErrorWithCode:PTNErrorCodeAssetLoadingFailed
                  forPath:dropboxPath andClient:restClient];
}

- (RACSignal *)loadFileProgress:(NSString *)localPath restClient:(DBRestClient *)restClient {
  return [[[[self rac_signalForSelector:@selector(restClient:loadProgress:forFile:)
                          fromProtocol:@protocol(DBRestClientDelegate)]
      filter:^BOOL(RACTuple *tuple) {
        RACTupleUnpack(DBRestClient *client, NSNumber __unused *progress,
                       NSString *destPath) = tuple;
        return client == restClient && [destPath isEqualToString:localPath];
      }]
      reduceEach:^(DBRestClient __unused *client, NSNumber *progress,
                   NSString __unused *destPath) {
        return progress;
      }]
      map:^(NSNumber *progress) {
        return [[PTNProgress alloc] initWithProgress:progress];
      }];
}

#pragma mark -
#pragma mark Thumbnail fetching
#pragma mark -

- (RACSignal *)fetchThumbnail:(NSString *)path type:(PTNDropboxThumbnailType *)type {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    if (![self.restClientProvider isLinked]) {
      [subscriber sendError:[NSError lt_errorWithCode:PTNErrorCodeNotAuthorized]];
      return nil;
    }
    
    NSString *localPath = [self.pathProvider localPathForThumbnailInPath:path size:type.size];
    DBRestClient *restClient = [self.restClientProvider ptn_restClient];
    restClient.delegate = self;

    // Using \c subscribe: internally stores disposables within the subscriber, so there's no need
    // to explicitly dispose them.
    [[self loadThumbnailSuccesful:localPath restClient:restClient] subscribe:subscriber];
    [[self loadThumbnailError:path restClient:restClient] subscribe:subscriber];

    [restClient loadThumbnail:path ofSize:type.sizeName intoPath:localPath];

    return [RACDisposable disposableWithBlock:^{
      [restClient cancelThumbnailLoad:path size:type.sizeName];
    }];
  }];
}

- (RACSignal *)loadThumbnailSuccesful:(NSString *)localPath restClient:(DBRestClient *)restClient {
  return [[[[self rac_signalForSelector:@selector(restClient:loadedThumbnail:)
                           fromProtocol:@protocol(DBRestClientDelegate)]
      filter:^BOOL(RACTuple *tuple) {
        RACTupleUnpack(DBRestClient *client, NSString *destPath) = tuple;
        return client == restClient && [destPath isEqualToString:localPath];
      }]
      reduceEach:^(DBRestClient __unused *client, NSString *destPath) {
        return destPath;
      }]
      take:1];
}

- (RACSignal *)loadThumbnailError:(NSString *)dropboxPath restClient:(DBRestClient *)restClient {
  RACSignal *allThumbnailErrors =
      [self rac_signalForSelector:@selector(restClient:loadThumbnailFailedWithError:)
                     fromProtocol:@protocol(DBRestClientDelegate)];

  return [self liftSignal:allThumbnailErrors toErrorWithCode:PTNErrorCodeAssetLoadingFailed
                  forPath:dropboxPath andClient:restClient];
}

#pragma mark -
#pragma mark Signal operations
#pragma mark -

- (RACSignal *)liftSignal:(RACSignal *)signal toErrorWithCode:(NSInteger)errorCode
                  forPath:(NSString *)path andClient:(DBRestClient *)restClient {
  // Path key in \c error's \c userInfo is hard codded as \c @"path" in the Dropbox SDK.
  static NSString * const kErrorInfoPathKey = @"path";
  return [[[signal
      filter:^BOOL(RACTuple *tuple) {
        RACTupleUnpack(DBRestClient *client, NSError *error) = tuple;
        return client == restClient && [error.userInfo[kErrorInfoPathKey] isEqualToString:path];
      }]
      reduceEach:^(DBRestClient __unused *client, NSError *error) {
        return error;
      }]
      flattenMap:^(NSError *error) {
        NSError *dropboxError = [NSError lt_errorWithCode:errorCode
                                          underlyingError:error];
        return [RACSignal error:dropboxError];
      }];
}

@end

NS_ASSUME_NONNULL_END
