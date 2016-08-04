// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocalProductsProvider.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "BZRProduct.h"
#import "NSErrorCodes+Bazaar.h"
#import "RACSignal+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRLocalProductsProvider ()

/// Path from which to fetch the JSON list.
@property (readonly, nonatomic) LTPath *path;

/// File manager used to read the file's content specified by \c path into a JSON list.
@property (readonly, nonatomic) NSFileManager *fileManager;

@end

@implementation BZRLocalProductsProvider

- (instancetype)initWithPath:(LTPath *)path fileManager:(NSFileManager *)fileManager {
  if (self = [super init]) {
    _path = path;
    _fileManager = fileManager;
  }
  return self;
}

- (RACSignal *)fetchProductList {
  return [[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSError *error;
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
  }]
      bzr_deserializeArrayOfModels:[BZRProduct class]]
      subscribeOn:[RACScheduler scheduler]]
      setNameWithFormat:@"%@ -fetchProductList", self.description];
}

@end

NS_ASSUME_NONNULL_END
