// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SPXPromotion.h"

#import "NSErrorCodes+Shopix.h"
#import "SPXProductAxis.h"

/// Returns all the classes that conform to \c protocol.
NSSet<Class> *SPXClassesConformToProtocol(Protocol *protocol) {
  NSMutableSet *classSet = [NSMutableSet set];

  int numClasses = objc_getClassList(NULL, 0);
  if (numClasses > 0) {
    Class *classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    for (int i = 0; i < numClasses; ++i) {
      Class nextClass = classes[i];
      if (class_conformsToProtocol(nextClass, protocol)) {
        [classSet addObject:classes[i]];
      }
    }
    free(classes);
  }
  return classSet;
}

SpecBegin(SPXPromotion)

__block SPXCoupon *coupon1;
__block SPXCoupon *coupon2;
__block SPXPromotion *promotion;

beforeEach(^{
  coupon1 = [SPXCoupon
             couponWithBaseProductValues:@[SPXBaseProductAxis.subscriptionPeriod.monthly,
                                           SPXBaseProductAxis.subscriptionPeriod.biYearly]
             benefitValues:@[SPXBenefitProductAxis.discountLevel.off25]];
  coupon2 = [SPXCoupon
             couponWithBaseProductValues:@[SPXBaseProductAxis.subscriptionPeriod.yearly]
             benefitValues:@[SPXBenefitProductAxis.discountLevel.off75]];
  promotion = [[SPXPromotion alloc] initWithName:@"Test"
                                         coupons:@[coupon1, coupon2]
                                      expiryDate:[NSDate dateWithTimeIntervalSince1970:1337]];
});

it(@"should serialize and deserialize promotions", ^{
  auto serializedPromotion = [MTLJSONAdapter JSONDictionaryFromModel:promotion];
  NSError *error = nil;
  auto *jsonData = [NSJSONSerialization dataWithJSONObject:serializedPromotion options:0
                                                     error:&error];
  NSDictionary *deserializedDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0
                                                                     error:&error];
  SPXPromotion *newPromotion = [MTLJSONAdapter modelOfClass:SPXPromotion.class
                                         fromJSONDictionary:deserializedDict error:&error];
  expect(promotion).to.equal(newPromotion);
});

it(@"should deserialize JSON string", ^{
  NSDictionary *json = @{
    @"name": @"Test",
    @"coupons": @[
      @{
        @"baseProductValues": @[
          @{
            @"axis": @"SubscriptionPeriod",
            @"value": @"Monthly"
          },
          @{
            @"axis": @"SubscriptionPeriod",
            @"value": @"BiYearly"
          }
        ],
        @"benefitValues": @[
        @{
          @"axis": @"DiscountLevel",
          @"value": @"25Off"
        }
        ]
      },
      @{
        @"baseProductValues": @[
          @{
            @"axis": @"SubscriptionPeriod",
            @"value": @"Yearly"
          }
        ],
        @"benefitValues": @[
          @{
            @"axis": @"DiscountLevel",
            @"value": @"75Off"
          }
        ]
      }
    ],
    @"expiryDate": @"1970-01-01T00:22:17.000Z"
  };
  NSError *error;
  SPXPromotion *promotion = [MTLJSONAdapter modelOfClass:SPXPromotion.class fromJSONDictionary:json
                                                   error:&error];
  expect(promotion.name).to.equal(@"Test");
  expect(promotion.coupons).to.equal(@[coupon1, coupon2]);
  expect(promotion.expiryDate).to.equal([NSDate dateWithTimeIntervalSince1970:1337]);
});

it(@"should fail to deserialize if unknown axis is given", ^{
  NSDictionary *json = @{
    @"name": @"Test",
    @"coupons": @[
      @{
        @"baseProductValues": @[
          @{
            @"axis": @"SPXNonExistingAxis",
            @"value": @"Monthly"
          }
        ],
        @"benefitValues": @[
        @{
          @"axis": @"DiscountLevel",
          @"value": @"25Off"
        }
        ]
      }
    ],
    @"expiryDate": @"1970-01-01T00:22:17.000Z"
  };
  NSError *error;
  SPXPromotion *promotion = [MTLJSONAdapter modelOfClass:SPXPromotion.class fromJSONDictionary:json
                                                   error:&error];
  expect(promotion).to.beNil();
  expect(error.code).to.equal(SPXErrorCodeDeserializationFailed);
});

it(@"should fail to deserialize if value is non-string", ^{
  NSDictionary *json = @{
    @"name": @"Test",
    @"coupons": @[
      @{
        @"baseProductValues": @[
          @{
            @"axis": @"SubscriptionPeriod",
            @"value": @2
          },
          @{
            @"axis": @"SubscriptionPeriod",
            @"value": @"BiYearly"
          }
        ],
        @"benefitValues": @[
        @{
          @"axis": @"DiscountLevel",
          @"value": @"25Off"
        }
        ]
      }
    ],
    @"expiryDate": @"1970-01-01T00:22:17.000Z"
  };
  NSError *error;
  SPXPromotion *promotion = [MTLJSONAdapter modelOfClass:SPXPromotion.class fromJSONDictionary:json
                                                   error:&error];
  expect(promotion).to.beNil();
  expect(error.code).to.equal(SPXErrorCodeDeserializationFailed);
});

it(@"should fail to deserialize if the the axis is in the wrong list", ^{
  NSDictionary *json = @{
    @"name": @"Test",
    @"coupons": @[
      @{
        @"baseProductValues": @[
          @{
            @"axis": @"SubscriptionPeriod",
            @"value": @"BiYearly"
          },
          @{
            @"axis": @"FreeTrialDuration",
            @"value": @"1MonthTrial"
          }
        ],
        @"benefitValues": @[
        @{
          @"axis": @"DiscountLevel",
          @"value": @"25Off"
        }
        ]
      }
    ],
    @"expiryDate": @"1970-01-01T00:22:17.000Z"
  };
  NSError *error;
  SPXPromotion *promotion = [MTLJSONAdapter modelOfClass:SPXPromotion.class fromJSONDictionary:json
                                                   error:&error];
  expect(promotion).to.beNil();
  expect(error.code).to.equal(SPXErrorCodeDeserializationFailed);
});

it(@"should fail to deserialize if the value of the axis does not exist", ^{
  NSDictionary *json = @{
    @"name": @"Test",
    @"coupons": @[
      @{
        @"baseProductValues": @[
          @{
            @"axis": @"SubscriptionPeriod",
            @"value": @"foo"
          }
        ],
        @"benefitValues": @[
        @{
          @"axis": @"DiscountLevel",
          @"value": @"25Off"
        }
        ]
      }
    ],
    @"expiryDate": @"1970-01-01T00:22:17.000Z"
  };
  NSError *error;
  SPXPromotion *promotion = [MTLJSONAdapter modelOfClass:SPXPromotion.class fromJSONDictionary:json
                                                   error:&error];
  expect(promotion).to.beNil();
  expect(error.code).to.equal(SPXErrorCodeDeserializationFailed);
});

it(@"should fail to deserialize if properties are missing", ^{
  NSDictionary *json = @{
    @"name": @"Test",
    @"coupons": @[
      @{
        @"baseProductValues": @[
          @{
            @"axis": @"SPXNonExistingAxis",
            @"value": @"Monthly"
          }
        ]
      }
    ],
    @"expiryDate": @"1970-01-01T00:22:17.000Z"
  };
  NSError *error;
  SPXPromotion *promotion = [MTLJSONAdapter modelOfClass:SPXPromotion.class fromJSONDictionary:json
                                                   error:&error];
  expect(promotion).to.beNil();
  expect(error.code).to.equal(SPXErrorCodeDeserializationFailed);
});

it(@"should fail to deserialize if expiryDate is not in the correct format", ^{
  NSDictionary *json = @{
    @"name": @"Test",
    @"coupons": @[
      @{
        @"baseProductValues": @[
          @{
            @"axis": @"SPXNonExistingAxis",
            @"value": @"Monthly"
          }
        ],
        @"benefitValues": @[
        @{
          @"axis": @"DiscountLevel",
          @"value": @"25Off"
        }
        ]
      }
    ],
    @"expiryDate": @"1970-01-01T00:22:rr"
  };
  NSError *error;
  SPXPromotion *promotion = [MTLJSONAdapter modelOfClass:SPXPromotion.class fromJSONDictionary:json
                                                   error:&error];
  expect(promotion).to.beNil();
  expect(error.code).to.equal(SPXErrorCodeDeserializationFailed);
});

it(@"should make sure all classes that conform to SPXBaseProductAxis can be serialized", ^{
  for (Class productAxis in SPXClassesConformToProtocol(@protocol(SPXBaseProductAxis))) {
    id<SPXBaseProductAxis> axis = [[productAxis alloc] init];
    auto value = [[SPXBaseProductAxisValue alloc] initWithValue:@"foo" andAxis:axis];
    auto coupon = [SPXCoupon
                   couponWithBaseProductValues:@[value]
                   benefitValues:@[SPXBenefitProductAxis.discountLevel.off25]];
    auto serializedPromotion = [MTLJSONAdapter JSONDictionaryFromModel:coupon];
    NSError *error = nil;
    auto *jsonData = [NSJSONSerialization dataWithJSONObject:serializedPromotion options:0
                                                       error:&error];
    expect(jsonData).notTo.beNil();
  }
});

it(@"should make sure all classes that conform to SPXBenefitAxis can be serialized", ^{
  for (Class productAxis in SPXClassesConformToProtocol(@protocol(SPXBenefitAxis))) {
    id<SPXBenefitAxis> axis = [[productAxis alloc] init];
    auto value = [[SPXBenefitAxisValue alloc] initWithValue:@"foo" andAxis:axis];
    auto coupon = [SPXCoupon
                   couponWithBaseProductValues:@[SPXBaseProductAxis.subscriptionPeriod.monthly]
                   benefitValues:@[value]];
    auto serializedPromotion = [MTLJSONAdapter JSONDictionaryFromModel:coupon];
    NSError *error = nil;
    auto *jsonData = [NSJSONSerialization dataWithJSONObject:serializedPromotion options:0
                                                       error:&error];
    expect(jsonData).notTo.beNil();
  }
});

SpecEnd
