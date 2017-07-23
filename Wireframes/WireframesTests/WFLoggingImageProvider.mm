// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "WFLoggingImageProvider.h"

#import <LTEngineTests/LTSpectaObjectionHook.h>
#import <LTEngineTests/LTTestModule.h>
#import <Wireframes/WFImageLoader.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFLoggingImageProvider ()

/// Mutable array of currently ongoing requests.
@property (readonly, nonatomic) NSMutableArray<NSURL *> *mutableOngoingURLs;

/// Mutable array of successful requests.
@property (readonly, nonatomic) NSMutableArray<NSURL *> *mutableCompletedURLs;

/// Mutable array of non-successful requests.
@property (readonly, nonatomic) NSMutableArray<NSURL *> *mutableErrdURLs;

/// Mutable array of retrieved images.
@property (readonly, nonatomic) NSMutableArray<UIImage *> *mutableImages;

/// Mutable array of retrieved errors.
@property (readonly, nonatomic) NSMutableArray<NSError *> *mutableErrors;

/// \c YES if requests can be received, otherwise an exception will be raised.
@property (nonatomic) BOOL canReceiveRequests;

/// Image provider used for fetching the images.
@property (readonly, nonatomic) id<WFImageProvider> imageProvider;

@end

@implementation WFLoggingImageProvider

- (instancetype)init {
  return [self initWithImageProvider:[[WFImageLoader alloc] init]];
}

- (instancetype)initWithImageProvider:(id<WFImageProvider>)imageProvider {
  if (self = [super init]) {
    _imageProvider = imageProvider;
    _mutableOngoingURLs = [NSMutableArray array];
    _mutableCompletedURLs = [NSMutableArray array];
    _mutableErrdURLs = [NSMutableArray array];
    _mutableImages = [NSMutableArray array];
    _mutableErrors = [NSMutableArray array];

    self.canReceiveRequests = YES;
  }
  return self;
}

- (RACSignal *)imageWithURL:(NSURL *)url {
  @synchronized (self) {
    if (!self.canReceiveRequests) {
      NSString *reason = [NSString stringWithFormat:@"Received request after completion: %@", url];
      [[NSException exceptionWithName:@"com.lightricks.WFLoggingImageProviderException"
                               reason:reason userInfo:nil] raise];
    }

    [self.mutableOngoingURLs addObject:url];
  }

  return [[[[[[_imageProvider imageWithURL:url]
      takeUntil:self.rac_willDeallocSignal]
      doNext:^(UIImage *image) {
        @synchronized (self) {
          [self.mutableImages addObject:image];
        }
      }]
      doError:^(NSError *error) {
        @synchronized (self) {
          [self.mutableErrors addObject:error];
          [self.mutableOngoingURLs removeObject:url];
          [self.mutableErrdURLs addObject:url];
        }
      }]
      doCompleted:^{
        @synchronized (self) {
          [self.mutableOngoingURLs removeObject:url];
          [self.mutableCompletedURLs addObject:url];
        }
      }]
      replayLazily];
}

- (void)waitUntilCompletion {
  static const NSTimeInterval kWaitInterval = 0.1;

  @synchronized (self) {
    self.canReceiveRequests = NO;
  }

  const NSTimeInterval timeout = CACurrentMediaTime() + [Expecta asynchronousTestTimeout];

  while (self.ongoingURLs.count) {
    if (timeout < CACurrentMediaTime()) {
      [[NSException exceptionWithName:@"com.lightricks.WFLoggingImageProviderException"
                               reason:@"Timeout while waiting for completion" userInfo:nil] raise];
    }

    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:kWaitInterval]];
  }
}

- (NSArray<NSURL *> *)ongoingURLs {
  @synchronized (self) {
    return [self.mutableOngoingURLs copy];
  }
}

- (NSArray<NSURL *> *)completedURLs {
  @synchronized (self) {
    return [self.mutableCompletedURLs copy];
  }
}

- (NSArray<NSURL *> *)errdURLs {
  @synchronized (self) {
    return [self.mutableErrdURLs copy];
  }
}

- (NSArray<UIImage *> *)images {
  @synchronized (self) {
    return [self.mutableImages copy];
  }
}

- (NSArray<NSError *> *)errors {
  @synchronized (self) {
    return [self.mutableErrors copy];
  }
}

@end

extern "C" WFLoggingImageProvider *WFUseLoggingImageProvider() {
  return LTBindObjectToProtocol([[WFLoggingImageProvider alloc] init], @protocol(WFImageProvider));
}

NS_ASSUME_NONNULL_END
