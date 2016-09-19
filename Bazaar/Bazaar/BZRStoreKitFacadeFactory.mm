// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreKitFacadeFactory.h"

#import "BZRStoreKitFacade.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRStoreKitFacadeFactory ()

/// Identifier used to create instances of \c BZRStoreKitFacade.
@property (readonly, nonatomic, nullable) NSString *applicationUserID;

@end

@implementation BZRStoreKitFacadeFactory

- (instancetype)initWithApplicationUserID:(nullable NSString *)applicationUserID {
  if (self = [super init]) {
    _applicationUserID = [applicationUserID copy];
  }
  return self;
}

- (BZRStoreKitFacade *)storeKitFacadeWithUnfinishedTransactionsSubject:(RACSubject *)
    unfinishedTransactionsSubject {
  return [[BZRStoreKitFacade alloc]
          initWithUnfinishedTransactionsSubject:unfinishedTransactionsSubject
                              applicationUserID:self.applicationUserID];
}

@end

NS_ASSUME_NONNULL_END
