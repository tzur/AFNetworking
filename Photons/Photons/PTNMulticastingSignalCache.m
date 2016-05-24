// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNMulticastingSignalCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNMulticastingSignalCache ()

/// Replay capacity used when multicasting stored signals.
@property (readonly, nonatomic) NSUInteger replayCapacity;

/// Underlying signal cache.
@property (readonly, nonatomic) id<PTNSignalCache> signalCache;

/// Disposables of multicasted signals.
@property (readonly, nonatomic) NSMutableDictionary<NSURL *, RACDisposable *> *disposableStore;

/// Queue for accessing the signals cache in a readers/writers fashion.
@property (strong, nonatomic) dispatch_queue_t queue;

@end

@implementation PTNMulticastingSignalCache

- (instancetype)initWithReplayCapacity:(NSUInteger)replayCapacity {
  if (self = [super init]) {
    _replayCapacity = replayCapacity;
    _signalCache = [[PTNSignalCache alloc] init];
    _disposableStore = [NSMutableDictionary dictionary];
    self.queue = dispatch_queue_create("com.lightricks.Photons.MulticastingSignalCache",
                                       DISPATCH_QUEUE_CONCURRENT);
  }
  return self;
}

#pragma mark -
#pragma mark Caching
#pragma mark -

- (void)storeSignal:(nullable RACSignal *)signal forURL:(NSURL *)url {
  dispatch_barrier_sync(self.queue, ^{
    RACMulticastConnection *connection = [signal multicast:[self multicastingSubject]];

    self.signalCache[url] = connection.signal;
    [self.disposableStore[url] dispose];
    self.disposableStore[url] = [connection connect];
  });
}

- (nullable RACSignal *)signalForURL:(NSURL *)url {
  __block RACSignal *signal;

  dispatch_sync(self.queue, ^{
    signal = self.signalCache[url];
  });

  return signal;
}

- (void)removeSignalForURL:(NSURL *)url {
  dispatch_barrier_sync(self.queue, ^{
    [self.signalCache removeSignalForURL:url];
    [self.disposableStore[url] dispose];
  });
}

- (void)setObject:(nullable RACSignal *)obj forKeyedSubscript:(NSURL *)key {
  [self storeSignal:obj forURL:key];
}

#pragma mark -
#pragma mark Subscript access
#pragma mark -

- (nullable RACSignal *)objectForKeyedSubscript:(NSURL *)key {
  return [self signalForURL:key];
}

- (RACSubject *)multicastingSubject {
  return self.replayCapacity == 0 ?
      [RACSubject subject] : [RACReplaySubject replaySubjectWithCapacity:self.replayCapacity];
}

@end

NS_ASSUME_NONNULL_END
