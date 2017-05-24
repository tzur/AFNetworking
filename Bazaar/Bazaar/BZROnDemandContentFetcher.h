// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRContentFetcherParameters.h"
#import "BZRProductContentFetcher.h"

NS_ASSUME_NONNULL_BEGIN

/// Fetcher that provides products content via Apple's On Demand Resources.
///
/// @note Access to products content is available only after \c fetchProductContent completes
/// without any error, or after \c contentBundleForProduct returned the content bundle.
///
/// @see Apple's On Demand Resources Guide:
/// https://developer.apple.com/library/content/documentation/FileManagement/Conceptual/On_Demand_Resources_Guide/
@interface BZROnDemandContentFetcher : NSObject <BZRProductContentFetcher>

/// Initializes with the \c bundle set to [NSBundle mainBundle].
- (instancetype)init;

/// Initializes with \c bundle, used to access On Demand Resources.
- (instancetype)initWithBundle:(NSBundle *)bundle NS_DESIGNATED_INITIALIZER;

@end

/// Additional parameters required for fetching content with \c BZROnDemandContentFetcher.
///
/// Example of a JSON serialized \c BZROnDemandContentFetcherParameters:
/// @code
/// {
///   "type": "BZROnDemandContentFetcher",
///   "tags": "[tag1, tag2]"
/// }
@interface BZROnDemandContentFetcherParameters : BZRContentFetcherParameters

/// Set of strings that specify the contents in On Demand Resources that a product needs. Every On
/// Demand Resource can be tagged by one or more tags. When a tag is requested, all the resources
/// that are tagged with it are fetched. Thus when tags of a product are requested, all resources
/// that have one of the tags are fetched.
@property (readonly, nonatomic) NSSet<NSString *> *tags;

@end

NS_ASSUME_NONNULL_END
