// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocalJSONProductsProvider.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRLocalJSONProductsProvider ()

/// Path from which to fetch the JSON list.
@property (readonly, nonatomic) LTPath *path;

/// File manager used to read the file's content specified by \c path into a JSON list.
@property (readonly, nonatomic) NSFileManager *fileManager;

@end

@implementation BZRLocalJSONProductsProvider

- (instancetype)initWithPath:(LTPath *)path fileManager:(NSFileManager *)fileManager {
  if (self = [super init]) {
    _fileManager = fileManager;
    _path = path;
  }
  return self;
}

- (RACSignal *)fetchJSONProductList {
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSError *error = nil;
    NSData *data = [self.fileManager lt_dataWithContentsOfFile:self.path.path options:0
                                                         error:&error];
    if (error) {
      [subscriber sendError:error];
      return nil;
    }

    NSArray *productList = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
      NSError *wrappingError = [NSError lt_errorWithCode:BZRErrorCodeJSONDataDeserializationFailed
                                         underlyingError:error];
      [subscriber sendError:wrappingError];
      return nil;
    }

    [subscriber sendNext:productList];
    [subscriber sendCompleted];

    return nil;
  }] subscribeOn:[RACScheduler scheduler]];
}

@end

NS_ASSUME_NONNULL_END
