// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductDictionary.h"
#import "BZRProductsVariantSelectorFactory.h"

NS_ASSUME_NONNULL_BEGIN

/// Factory used to create \c BZRLocaleBasedVariantSelector objects.
@interface BZRLocaleBasedVariantSelectorFactory : NSObject <BZRProductsVariantSelectorFactory>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c fileManager, used to load country code to tier dictionary, and with
/// \c countryToTierPath, specifies the path to the file of the dictionary.
- (instancetype)initWithFileManager:(NSFileManager *)fileManager
                  countryToTierPath:(LTPath *)countryToTierPath NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
