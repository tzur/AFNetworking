// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Factory used to create StoreKit's \c SKProductsRequest and \c SKReceiptRefreshRequest.
@protocol BZRStoreKitRequestsFactory <NSObject>

/// Creates a new instance of \c SKProductsRequest with \c productIdentifiers.
- (SKProductsRequest *)productsRequestWithIdentifiers:(NSSet<NSString *> *)productIdentifiers;

/// Creates a new instance of \c SKReceiptRefreshRequest.
- (SKReceiptRefreshRequest *)receiptRefreshRequest;

@end

/// Default implementation of \c BZRStoreKitRequestsFactory.
@interface BZRStoreKitRequestsFactory : NSObject <BZRStoreKitRequestsFactory>

/// Returns the default implementation of \c BZRStoreKitRequestsFactory.
+ (BZRStoreKitRequestsFactory *)defaultFactory;

@end

NS_ASSUME_NONNULL_END
