// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocalProductsProvider.h"

#import <LTKit/NSData+Compression.h>
#import <LTKit/NSData+Encryption.h>
#import <LTKit/NSData+HexString.h>
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

/// Key used to decrypt the products JSON file.
@property (readonly, nonatomic, nullable) NSData *decryptionKey;

@end

@implementation BZRLocalProductsProvider

- (instancetype)initWithPath:(LTPath *)path {
  return [self initWithPath:path  decryptionKey:nil fileManager:[NSFileManager defaultManager]];
}

- (instancetype)initWithPath:(LTPath *)path decryptionKey:(nullable NSString *)decryptionKey
                 fileManager:(NSFileManager *)fileManager
                {
  if (self = [super init]) {
    _path = path;
    _fileManager = fileManager;

    if (decryptionKey) {
      LTParameterAssert(decryptionKey.length == 32, @"Decryption key size must be 32");
      NSError *error;
      _decryptionKey = [NSData lt_dataWithHexString:decryptionKey error:&error];
      LTParameterAssert(self.decryptionKey, @"Failed to decode the decryption key '%@' : %@",
                        decryptionKey, error.lt_description);
    }
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

    auto JSONData = self.decryptionKey ? [self decodeData:data error:&error] : data;
    if (error) {
      [subscriber sendError:error];
      return nil;
    }

    NSArray *productList = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
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

- (RACSignal *)eventsSignal {
  return [[RACSignal never] takeUntil:[self rac_willDeallocSignal]];
}

- (nullable NSData *)decodeData:(NSData *)data
                          error:(NSError * __autoreleasing *)error {
  return [[data
          lt_decryptWithKey:self.decryptionKey error:error]
          lt_decompressWithCompressionType:LTCompressionTypeLZFSE error:error];
}

@end

NS_ASSUME_NONNULL_END
