// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Category to extract information about subscription products from \c EUISMModel.
@interface EUISMModel (ProductInfo)

/// Returns information about the subscription product the user is subscribed to. The returned
/// product information is of the last product the user subscribed to, even if the subscription to
/// it is pending and not yet started. Returns \c nil if the current subscription info is not
/// available or if the product info for the current product is not available.
- (nullable EUISMProductInfo *)currentProductInfo;

/// Returns information about the subscription product to promote. The product to promote is a
/// product from the subscription group of the current product that has a yearly billing period. If
/// no such product available or the current product's billing period is not monthly returns \c nil.
- (nullable EUISMProductInfo *)promotedProductInfo;

@end

NS_ASSUME_NONNULL_END
