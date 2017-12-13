// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SPXPromotion.h"

#import <LTKit/NSData+Base64.h>
#import <LTKit/NSData+Compression.h>
#import <LTKit/NSData+Encryption.h>
#import <LTKit/NSData+Hashing.h>

#import "NSErrorCodes+Shopix.h"
#import "SPXProductAxis.h"

/// Adds method to easily convert to \c NSData.
@interface NSString (encoding)

/// Returns the receiver encoded using UTF8.
- (NSData *)spx_dataUsingUTF8;

@end

@implementation NSString (encoding)

- (NSData *)spx_dataUsingUTF8 {
  return [self dataUsingEncoding:NSUTF8StringEncoding];
}

@end

/// Concatenates given \c datas into a single, consecutive data buffer.
static NSData *SPXConcateDatas(NSArray<NSData *> *datas) {
  NSMutableData *concatenatedDatas = [NSMutableData data];
  for (NSData *data in datas) {
    [concatenatedDatas appendData:data];
  }
  return concatenatedDatas;
}

/// Returns all the classes that conform to \c protocol.
static NSSet<Class> *SPXClassesConformToProtocol(Protocol *protocol) {
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

context(@"secure serialization", ^{
  __block NSString *key;

  beforeEach(^{
    key = @"bar";
  });

  it(@"should convert to string", ^{
    NSError *error;
    auto serializedPromotion = [promotion serializeAndSignWithKey:key error:&error];
    expect(error).to.beNil();
    expect([[NSData alloc] initWithURLSafeBase64EncodedString:serializedPromotion]).notTo.beNil();
  });

  it(@"should convert to string and back to promotion", ^{
    auto _Nullable serializedPromotion = [promotion serializeAndSignWithKey:key error:nil];
    auto _Nullable newPromotion = [SPXPromotion promotionWithSerializedString:serializedPromotion
                                                                          key:key error:nil];
    expect(newPromotion).to.equal(promotion);
  });

  it(@"should deserialize a promotion that is generated by an external script", ^{
    auto serializedPromotion = @"b1zjGXhVG3RuI5HxwgpUIMSnwxNrBdiP6YlW68fFhuTfowS6O_FKcPZI3d1cSlFeVz"
        "-VIOUHygt8NASXlyuIouEOvkFkiqgoagnFMmkW00zMCGASNj6uTvYzkgsPXdhlJEAezouukMd7w3GzsG7HP2EkfU8p"
        "O7NfnLpTuQBslbuIjgywA9F2_wpWTN6MjRxxhtybErJU4_d-r5AKVo9ljwb9jsMvMs1Zsz9MTEceV11tKK97yCFktI"
        "YU7gLt9OjM7hpha2CGsSZtfE7FKPDVanu1CMNlHafhfax4LC9hePg";

    auto _Nullable newPromotion =
        [SPXPromotion promotionWithSerializedString:serializedPromotion key:key error:nil];

    expect(newPromotion).to.equal(promotion);
  });

  it(@"should err if signature doesn't match", ^{
    auto IV = [NSMutableData dataWithLength:16];
    auto encrypted = [[[@"foo" spx_dataUsingUTF8]
                       lt_compressWithCompressionType:LTCompressionTypeZLIB error:nil]
                       lt_encryptWithKey:[[key spx_dataUsingUTF8] lt_MD5] iv:IV error:nil];
    auto signature = [[NSData data] lt_HMACSHA256WithKey:[key spx_dataUsingUTF8]];
    auto serializedPromotions = [SPXConcateDatas(@[signature, encrypted]) lt_urlSafeBase64];

    NSError *error;
    auto _Nullable newPromotion = [SPXPromotion promotionWithSerializedString:serializedPromotions
                                                                          key:key error:&error];
    expect(newPromotion).to.beNil();
    expect(error.code).equal(SPXErrorCodeSignatureValidationFailed);
  });

  it(@"should err if data it too small", ^{
    auto serializedPromotions = [[NSMutableData dataWithLength:31] lt_urlSafeBase64];

    NSError *error;
    auto _Nullable newPromotion = [SPXPromotion promotionWithSerializedString:serializedPromotions
                                                                          key:key error:&error];
    expect(newPromotion).to.beNil();
    expect(error.code).equal(SPXErrorCodeDeserializationFailed);
  });

  it(@"should err if decryption fails", ^{
    auto encrypted = [@"foobarbaz" spx_dataUsingUTF8];
    auto signature = [encrypted lt_HMACSHA256WithKey:[key spx_dataUsingUTF8]];
    auto serializedPromotions = [SPXConcateDatas(@[signature, encrypted]) lt_urlSafeBase64];

    NSError *error;
    auto _Nullable newPromotion = [SPXPromotion promotionWithSerializedString:serializedPromotions
                                                                          key:key error:&error];
    expect(newPromotion).to.beNil();
    expect(error.code).equal(SPXErrorCodeDeserializationFailed);
  });

  it(@"should err if decompressions fails", ^{
    auto IV = [NSMutableData dataWithLength:16];
    auto encrypted = [[@"foobarbaz" spx_dataUsingUTF8]
                      lt_encryptWithKey:[[key spx_dataUsingUTF8] lt_MD5] iv:IV error:nil];
    auto signature = [encrypted lt_HMACSHA256WithKey:[key spx_dataUsingUTF8]];
    auto serializedPromotions = [SPXConcateDatas(@[signature, encrypted]) lt_urlSafeBase64];

    NSError *error;
    auto _Nullable newPromotion = [SPXPromotion promotionWithSerializedString:serializedPromotions
                                                                          key:key error:&error];
    expect(newPromotion).to.beNil();
    expect(error.code).equal(SPXErrorCodeDeserializationFailed);
  });

  it(@"should err if deserialization fails", ^{
    auto IV = [NSMutableData dataWithLength:16];
    auto encrypted = [[[@"foo" spx_dataUsingUTF8]
                       lt_compressWithCompressionType:LTCompressionTypeZLIB error:nil]
                       lt_encryptWithKey:[[key spx_dataUsingUTF8] lt_MD5] iv:IV error:nil];
    auto signature = [encrypted lt_HMACSHA256WithKey:[key spx_dataUsingUTF8]];
    auto serializedPromotions = [SPXConcateDatas(@[signature, encrypted]) lt_urlSafeBase64];

    NSError *error;
    auto _Nullable newPromotion = [SPXPromotion promotionWithSerializedString:serializedPromotions
                                                                          key:key error:&error];
    expect(newPromotion).to.beNil();
    expect(error.code).equal(SPXErrorCodeDeserializationFailed);
  });
});

SpecEnd
