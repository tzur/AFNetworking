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
/// @note Occasionally, when content is requested, ODR methods says that it exists, even though it
/// does not. In order to overcome this inconsistency issue, we added content version validation
/// that compares a checksum string from the product's \c contentFetcherParameters to the contents
/// of a checksum file added as part of the downloaded content. Hence, in order for the checksum
/// validation to work properly, there must be a file named <tt><product.identifier>.checksum</tt>
/// with the same tags as the tagged resources, and its content must be identical to
/// \c product.contentFetcherParameters.checksum.
/// @see http://www.openradar.me/32767758 for more information about this issue.
///
/// @see Apple's On Demand Resources Guide:
/// https://developer.apple.com/library/content/documentation/FileManagement/Conceptual/On_Demand_Resources_Guide/
@interface BZROnDemandContentFetcher : NSObject <BZRProductContentFetcher>

/// Initializes with the \c bundle set to [NSBundle mainBundle] and \c fileManager set to
/// \c [NSFileManager defaultManager].
- (instancetype)init;

/// Initializes with \c bundle, used to access On Demand Resources, and \c fileManager used in
/// order to read the checksum file.
- (instancetype)initWithBundle:(NSBundle *)bundle fileManager:(NSFileManager *)fileManager
    NS_DESIGNATED_INITIALIZER;

/// Fetches the given \c product's content by its On Demand Resources tags as specified by
/// \c product.contentFetcherParameters.tags.
///
/// Returns a signal that starts the fetching process. The signal sends \c LTProgress with
/// \c progress updates throughout the fetching process. When fetching completes, the
/// content version is validated, if the validation was successful, the signal sends an
/// \c LTProgress with \c result set to an \c NSBundle that provides access to the content. The
/// signal completes after sending the \c LTProgress with the \c result. The signal errs if there
/// was an error while fetching the content, the downloaded content didn't pass the version
/// validation or if the given \c product.contentFetcherParameters is invalid.
- (RACSignal<BZRContentFetchingProgress *> *)fetchProductContent:(BZRProduct *)product;

/// Checks if the product's content bundle exists using the tags as specified by
/// \c product.contentFetcherParameters.tags.
///
/// Returns a signal that sends an \c NSBundle if the content is available and passed validation.
/// The signal sends \c nil if the content is not available on the device, didn't pass the
/// version validation or if \c product.contentFetcherParameters is invalid. The signal completes
/// after sending the value. The signal doesn't err.
- (RACSignal<NSBundle *> *)contentBundleForProduct:(BZRProduct *)product;

@end

/// Additional parameters required for fetching content with \c BZROnDemandContentFetcher.
///
/// Example of a JSON serialized \c BZROnDemandContentFetcherParameters:
/// @code
/// {
///   "type": "BZROnDemandContentFetcher",
///   "tags": [tag1, tag2],
///   "checksum": "41dbb5e299ddf150a4952cd26c9c0331"
/// }
@interface BZROnDemandContentFetcherParameters : BZRContentFetcherParameters

/// Set of strings that specify the contents in On Demand Resources that a product needs. Every On
/// Demand Resource can be tagged by one or more tags. When a tag is requested, all the resources
/// that are tagged with it are fetched. Thus when tags of a product are requested, all resources
/// that have one of the tags are fetched.
@property (readonly, nonatomic) NSSet<NSString *> *tags;

/// String that uniquely identifies the version of the content of the product.
@property (readonly, nonatomic) NSString *checksum;

@end

NS_ASSUME_NONNULL_END
