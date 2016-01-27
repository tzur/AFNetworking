// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNSignalCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNSignalCache ()

/// Dictionary from \c NSURL album urls to their \c RACSignal objects.
@property (strong, nonatomic) NSMutableDictionary *signals;

/// Queue for accessing the album signals cache in a readers/writers fashion.
@property (strong, nonatomic) dispatch_queue_t queue;

@end

@implementation PTNSignalCache

- (instancetype)init {
  if (self = [super init]) {
    self.signals = [NSMutableDictionary dictionary];
    self.queue = dispatch_queue_create("com.lightricks.Photons.SignalCache",
                                       DISPATCH_QUEUE_CONCURRENT);
  }
  return self;
}

#pragma mark -
#pragma mark Caching
#pragma mark -

- (void)storeSignal:(nullable RACSignal *)signal forURL:(NSURL *)url {
  dispatch_barrier_sync(self.queue, ^{
    self.signals[url] = signal;
  });
}

- (nullable RACSignal *)signalForURL:(NSURL *)url {
  __block RACSignal *signal;

  dispatch_sync(self.queue, ^{
    signal = self.signals[url];
  });

  return signal;
}

- (void)removeSignalForURL:(NSURL *)url {
  dispatch_barrier_sync(self.queue, ^{
    [self.signals removeObjectForKey:url];
  });
}

#pragma mark -
#pragma mark Subscript access
#pragma mark -

- (void)setObject:(nullable RACSignal *)obj forKeyedSubscript:(NSURL *)key {
  [self storeSignal:obj forURL:key];
}

- (nullable RACSignal *)objectForKeyedSubscript:(NSURL *)key {
  return [self signalForURL:key];
}

@end

NS_ASSUME_NONNULL_END
