// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocaleBasedVariantSelectorFactory.h"

#import <LTKit/NSFileManager+LTKit.h>

#import "BZRLocaleBasedVariantSelector.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRLocaleBasedVariantSelectorFactory ()

/// Manager used to load country code to tier dictionary.
@property (readonly, nonatomic) NSFileManager *fileManager;

/// Path from which to fetch country code to tier dictionary.
@property (readonly, nonatomic) LTPath *countryToTierPath;

@end

@implementation BZRLocaleBasedVariantSelectorFactory

- (instancetype)initWithFileManager:(NSFileManager *)fileManager
                  countryToTierPath:(LTPath *)countryToTierPath {
  if (self = [super init]) {
    _fileManager = fileManager;
    _countryToTierPath = countryToTierPath;
  }
  return self;
}

- (nullable id<BZRProductsVariantSelector>)productsVariantSelectorWithProductDictionary:
    (NSDictionary<NSString *,BZRProduct *> *)productDictionary
    error:(NSError * __autoreleasing *)error {
  NSError *underlyingError;
  NSData *data = [self.fileManager lt_dataWithContentsOfFile:self.countryToTierPath.path options:0
                                                       error:&underlyingError];
  if (!data) {
    if (error) {
      *error = [NSError lt_errorWithCode:BZRErrorCodeLoadingFileFailed
                         underlyingError:underlyingError];
    }
    return nil;
  }

  NSDictionary<NSString *, NSString *> *countryToTier =
      [NSJSONSerialization JSONObjectWithData:data options:0 error:&underlyingError];
  if (!countryToTier) {
    if (error) {
      *error = [NSError lt_errorWithCode:BZRErrorCodeJSONDataDeserializationFailed
                         underlyingError:underlyingError];
    }
    return nil;
  }
  return [[BZRLocaleBasedVariantSelector alloc] initWithProductDictionary:productDictionary
                                                            countryToTier:countryToTier];
}

@end

NS_ASSUME_NONNULL_END
