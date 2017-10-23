// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSError+Shopix.h"

#import "SPXPromotion.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kSPXErrorAssociatedPromotionKey = @"AssociatedPromotion";
NSString * const kSPXErrorAssociatedCouponKey = @"AssociatedCoupon";

@implementation NSError (Shopix)

+ (instancetype)spx_errorWithCode:(NSInteger)code
              associatedPromotion:(SPXPromotion *)associatedPromotion {
  return [NSError lt_errorWithCode:code userInfo:@{
    kSPXErrorAssociatedPromotionKey: associatedPromotion
  }];
}

+ (instancetype)spx_errorWithCode:(NSInteger)code
              associatedPromotion:(SPXPromotion *)associatedPromotion
                 associatedCoupon:(SPXCoupon *)associatedCoupon {
  return [NSError lt_errorWithCode:code userInfo:@{
    kSPXErrorAssociatedPromotionKey: associatedPromotion,
    kSPXErrorAssociatedCouponKey: associatedCoupon
  }];
}

- (nullable SPXPromotion *)spx_associatedPromotion {
  return self.userInfo[kSPXErrorAssociatedPromotionKey];
}

- (nullable SPXCoupon *)spx_associatedCoupon {
  return self.userInfo[kSPXErrorAssociatedCouponKey];
}

@end

NS_ASSUME_NONNULL_END
