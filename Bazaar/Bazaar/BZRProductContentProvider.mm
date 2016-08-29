// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentProvider.h"

#import "BZRProduct.h"
#import "BZRProductContentFetcher.h"
#import "BZRProductContentManager.h"
#import "BZRProductEligibilityVerifier.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRProductContentProvider ()

/// Verifier used to verify that the user is eligible to use a product.
@property (readonly, nonatomic) BZRProductEligibilityVerifier *eligibilityVerifier;

/// Fetcher used to fetch content.
@property (readonly, nonatomic) id<BZRProductContentFetcher> contentFetcher;

/// Manager used to extract content from an archive file.
@property (readonly, nonatomic) BZRProductContentManager *contentManager;

@end

@implementation BZRProductContentProvider

- (instancetype)initWithEligibilityVerifier:(BZRProductEligibilityVerifier *)eligibilityVerifier
                             contentFetcher:(id<BZRProductContentFetcher>)contentFetcher
                             contentManager:(BZRProductContentManager *)contentManager {
  if (self = [super init]) {
    _eligibilityVerifier = eligibilityVerifier;
    _contentFetcher = contentFetcher;
    _contentManager = contentManager;
  }
  return self;
}

- (RACSignal *)fetchProductContent:(BZRProduct *)product {
  @weakify(self);
  return [[self validateEligibility:product] then:^{
    @strongify(self);
    if (!product.contentFetcherParameters) {
      return [RACSignal empty];
    }
    LTPath *pathToContent =
        [self.contentManager pathToContentDirectoryOfProduct:product.identifier];
    if (pathToContent) {
      return [RACSignal return:pathToContent];
    }
    return [[self.contentFetcher fetchContentForProduct:product]
        flattenMap:^RACSignal *(LTPath *contentArchivePath) {
          @strongify(self);
          return [self.contentManager extractContentOfProduct:product.identifier
                                                  fromArchive:contentArchivePath];
        }];
  }];
}

- (RACSignal *)validateEligibility:(BZRProduct *)product {
  return [[self.eligibilityVerifier verifyEligibilityForProduct:product.identifier]
     tryMap:^NSNumber *(NSNumber *isUserEligibleToUseProduct, NSError **error) {
       if (![isUserEligibleToUseProduct boolValue]) {
         *error = [NSError lt_errorWithCode:BZRErrorCodeUserNotAllowedToUseProduct];
         return nil;
       }
       return @YES;
     }];
}

@end

NS_ASSUME_NONNULL_END
