// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRStoreKitFacade;

/// Factory used to create \c BZRStoreKitFacade objects.
@interface BZRStoreKitFacadeFactory : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c applicationUserID, used to create instances of \c BZRStoreKitFacade.
- (instancetype)initWithApplicationUserID:(nullable NSString *)applicationUserID;

/// Creates a new instance of \c BZRStoreKitFacade with the given \c unfinishedTransactionsSubject
/// and \c applicationUserID given in the initializer.
- (BZRStoreKitFacade *)storeKitFacadeWithUnfinishedTransactionsSubject:(RACSubject *)
    unfinishedTransactionsSubject;

@end

NS_ASSUME_NONNULL_END
