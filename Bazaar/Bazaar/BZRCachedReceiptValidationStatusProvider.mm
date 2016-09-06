// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"

#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRReceiptValidationStatus.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRCachedReceiptValidationStatusProvider ()

/// Storage used to cache the latest fetched \c receiptValidationStatus.
@property (readonly, nonatomic) BZRKeychainStorage *keychainStorage;

/// Provider used to fetch the receipt validation status.
@property (readonly, nonatomic) id<BZRReceiptValidationStatusProvider> underlyingProvider;

/// Latest \c BZRReceiptValidationStatus fetched with \c underlyingProvider.
@property (strong, readwrite, nonatomic, nullable) BZRReceiptValidationStatus *
    receiptValidationStatus;

/// Sends storage errors as values. The subject completes when the receiver is deallocated. The
/// subject doesn't err.
@property (readonly, nonatomic) RACSubject *storageErrorsSubject;

@end

@implementation BZRCachedReceiptValidationStatusProvider

@synthesize nonCriticalErrorsSignal = _nonCriticalErrorsSignal;
@synthesize receiptValidationStatus = _receiptValidationStatus;

/// Key to the \c receiptValidationStatus stored in the secure storage.
NSString * const kValidationStatusStorageKey = @"validationStatus";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage
                     underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider {
  if (self = [super init]) {
    _keychainStorage = keychainStorage;
    _underlyingProvider = underlyingProvider;
    _storageErrorsSubject = [RACSubject subject];
    _nonCriticalErrorsSignal = [[RACSignal merge:@[
      self.storageErrorsSubject,
      self.underlyingProvider.nonCriticalErrorsSignal
    ]]
    takeUntil:[self rac_willDeallocSignal]];
  }
  return self;
}

#pragma mark -
#pragma mark Loading/storing receipt validation status
#pragma mark -

- (nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  if (!_receiptValidationStatus) {
    _receiptValidationStatus = [self loadValidationStatusFromStorage];
  }
  return _receiptValidationStatus;
}

- (nullable BZRReceiptValidationStatus *)loadValidationStatusFromStorage {
  NSError *error;
  BZRReceiptValidationStatus *receiptValidationStatus =
      [self.keychainStorage valueOfClass:[BZRReceiptValidationStatus class]
                                  forKey:kValidationStatusStorageKey error:&error];
  if (error) {
    [self.storageErrorsSubject sendNext:error];
    return nil;
  }
  return receiptValidationStatus;
}

- (void)setReceiptValidationStatus:(nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  _receiptValidationStatus = receiptValidationStatus;
  NSError *error;
  BOOL success =
      [self.keychainStorage setValue:receiptValidationStatus forKey:kValidationStatusStorageKey
                               error:&error];
  if (!success) {
    [self.storageErrorsSubject sendNext:
        [NSError lt_errorWithCode:BZRErrorCodeStoringDataToStorageFailed underlyingError:error]];
  }
}

#pragma mark -
#pragma mark Fetching receipt validation status
#pragma mark -

- (RACSignal *)fetchReceiptValidationStatus {
  @weakify(self);
  return [[[self.underlyingProvider fetchReceiptValidationStatus]
      doNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
        @strongify(self);
        self.receiptValidationStatus = receiptValidationStatus;
      }]
      setNameWithFormat:@"%@ -fetchReceiptValidationStatus", self.description];
}

@end

NS_ASSUME_NONNULL_END
