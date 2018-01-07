// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSError+Shopix.h"

#import "SPXVoucher.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kSPXErrorAssociatedVoucherKey = @"AssociatedVoucher";
NSString * const kSPXErrorAssociatedCouponKey = @"AssociatedCoupon";

@implementation NSError (Shopix)

+ (instancetype)spx_errorWithCode:(NSInteger)code
                associatedVoucher:(SPXVoucher *)associatedVoucher {
  return [NSError lt_errorWithCode:code userInfo:@{
    kSPXErrorAssociatedVoucherKey: associatedVoucher
  }];
}

+ (instancetype)spx_errorWithCode:(NSInteger)code
                associatedVoucher:(SPXVoucher *)associatedVoucher
                  underlyingError:(NSError *)underlyingError {
  return [NSError lt_errorWithCode:code userInfo:@{
      kSPXErrorAssociatedVoucherKey: associatedVoucher,
      NSUnderlyingErrorKey: underlyingError ?: [NSError spx_nullValueGivenError]
  }];
}

+ (instancetype)spx_errorWithCode:(NSInteger)code
                associatedVoucher:(SPXVoucher *)associatedVoucher
                 associatedCoupon:(SPXCoupon *)associatedCoupon {
  return [NSError lt_errorWithCode:code userInfo:@{
    kSPXErrorAssociatedVoucherKey: associatedVoucher,
    kSPXErrorAssociatedCouponKey: associatedCoupon
  }];
}

+ (instancetype)spx_nullValueGivenError {
  return [NSError lt_errorWithCode:LTErrorCodeNullValueGiven];
}

- (nullable SPXVoucher *)spx_associatedVoucher {
  return self.userInfo[kSPXErrorAssociatedVoucherKey];
}

- (nullable SPXCoupon *)spx_associatedCoupon {
  return self.userInfo[kSPXErrorAssociatedCouponKey];
}

@end

NS_ASSUME_NONNULL_END
