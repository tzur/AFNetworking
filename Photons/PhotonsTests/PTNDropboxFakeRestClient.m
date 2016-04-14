// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxFakeRestClient.h"

#import "PTNDropboxRestClient.h"
#import "PTNProgress.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNDropboxFakeRestClient ()

/// Underlying mocked client to use when forwarding method calls.
@property (readonly, nonatomic) PTNDropboxRestClient *restClient;

@end

@implementation PTNDropboxFakeRestClient

- (instancetype)init {
  if (self = [super init]) {
    _restClient = OCMClassMock([PTNDropboxRestClient class]);
    self.isLinked = YES;
  }
  return self;
}

#pragma mark -
#pragma mark PTNDropboxRestClient
#pragma mark -

- (RACSignal *)fetchMetadata:(NSString *)path revision:(nullable NSString *)revision {
  return [self.restClient fetchMetadata:path revision:revision];
}

- (RACSignal *)fetchFile:(NSString *)path revision:(nullable NSString *)revision {
  return [self.restClient fetchFile:path revision:revision];
}

- (RACSignal *)fetchThumbnail:(NSString *)path type:(PTNDropboxThumbnailType *)type {
  return [self.restClient fetchThumbnail:path type:type];
}

#pragma mark -
#pragma mark Metadata delivery
#pragma mark -

- (void)serveMetadataAtPath:(NSString *)path revision:(nullable NSString *)revision
               withMetadata:(DBMetadata *)metadata {
  OCMStub([self.restClient fetchMetadata:path revision:revision])
      .andReturn([self signalWithProgress:nil andValue:metadata]);
}

- (void)serveMetadataAtPath:(NSString *)path revision:(nullable NSString *)revision
                  withError:(NSError *)error {
  OCMStub([self.restClient fetchMetadata:path revision:revision])
      .andReturn([self signalWithProgress:nil andError:error]);
}

#pragma mark -
#pragma mark File delivery
#pragma mark -

- (void)serveFileAtPath:(NSString *)path revision:(nullable NSString *)revision
           withProgress:(nullable NSArray<NSNumber *> *)progress localPath:(NSString *)localPath {
  PTNProgress *result = [[PTNProgress alloc] initWithResult:localPath];
  OCMStub([self.restClient fetchFile:path revision:revision])
      .andReturn([self signalWithProgress:progress andValue:result]);
}

- (void)serveFileAtPath:(NSString *)path revision:(nullable NSString *)revision
           withProgress:(nullable NSArray<NSNumber *> *)progress finallyError:(NSError *)error {
  OCMStub([self.restClient fetchFile:path revision:revision])
      .andReturn([self signalWithProgress:progress andError:error]);
}

#pragma mark -
#pragma mark Thumbnail delivery
#pragma mark -

- (void)serveThumbnailAtPath:(NSString *)path type:(nullable PTNDropboxThumbnailType *)type
               withLocalPath:(NSString *)localPath {
  OCMStub([self.restClient fetchThumbnail:path type:type])
      .andReturn([self signalWithProgress:nil andValue:localPath]);
}

- (void)serveThumbnailAtPath:(NSString *)path type:(nullable PTNDropboxThumbnailType *)type
                   withError:(NSError *)error {
  OCMStub([self.restClient fetchThumbnail:path type:type])
      .andReturn([self signalWithProgress:nil andError:error]);
}

#pragma mark -
#pragma mark Utilities
#pragma mark -

- (RACSignal *)signalWithProgress:(nullable NSArray<NSNumber *> *)progress andValue:(id)value {
  if (!progress) {
    return [RACSignal return:value];
  }

  RACSubject *subject = [self progressSubject:progress];
  [subject sendNext:value];

  return subject;
}

- (RACSignal *)signalWithProgress:(nullable NSArray<NSNumber *> *)progress
                         andError:(NSError *)error {
  if (!progress) {
    return [RACSignal error:error];
  }

  RACSubject *subject = [self progressSubject:progress];
  [subject sendError:error];

  return subject;
}

- (RACReplaySubject *)progressSubject:(NSArray<NSNumber *> *)progress {
  RACReplaySubject *subject =
      [RACReplaySubject replaySubjectWithCapacity:RACReplaySubjectUnlimitedCapacity];
  for (NSNumber *beat in progress) {
    [subject sendNext:[[PTNProgress alloc] initWithProgress:beat]];
  }
  return subject;
}

@end

NS_ASSUME_NONNULL_END
