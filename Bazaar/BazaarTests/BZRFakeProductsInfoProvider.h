// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRProductsInfoProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake \c BZRProductsInfoProvider, can be filled with arbitrary data.
@interface BZRFakeProductsInfoProvider : NSObject <BZRProductsInfoProvider>

/// Fills with arbitrary preset data.
- (void)fillWithArbitraryData;

/// Events sent on this subject are sent on the signal returned from \c contentBundleForProduct:.
@property (readonly, nonatomic) RACSubject<NSBundle *> *contentBundleForProductSubject;

///The value that will be returned when calling \c isMultiAppSubscription:. Defaults to \c NO.
@property (readwrite, nonatomic) BOOL valueToReturnFromIsMultiAppSubscription;

/// Redeclare \c BZRProductsInfoProvider properties as readwrite.
@property (readwrite, nonatomic) NSSet<NSString *> *purchasedProducts;
@property (readwrite, nonatomic) NSSet<NSString *> *acquiredViaSubscriptionProducts;
@property (readwrite, nonatomic) NSSet<NSString *> *acquiredProducts;
@property (readwrite, nonatomic) NSSet<NSString *> *allowedProducts;
@property (readwrite, nonatomic) NSSet<NSString *> *downloadedContentProducts;
@property (readwrite, nonatomic, nullable) BZRReceiptSubscriptionInfo *subscriptionInfo;
@property (readwrite, nonatomic, nullable) BZRReceiptValidationStatus *receiptValidationStatus;
@property (readwrite, nonatomic, nullable) NSLocale *appStoreLocale;
@property (readwrite, nonatomic, nullable) NSDictionary<NSString *, BZRProduct *> *
    productsJSONDictionary;

@end

NS_ASSUME_NONNULL_END
