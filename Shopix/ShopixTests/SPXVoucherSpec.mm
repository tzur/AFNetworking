// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SPXVoucher.h"

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

@interface SPXDummyBenefitAxis : LTValueObject <SPXBenefitAxis>
@end

@implementation SPXDummyBenefitAxis

- (NSArray<id<SPXProductAxisValue>> *)values {
  return @[[[SPXBenefitAxisValue alloc] initWithValue:@"foo" andAxis:self]];
}

- (SPXBenefitAxisValue *)defaultValue {
  return [[SPXBenefitAxisValue alloc] initWithValue:@"foo" andAxis:self];
}

@end

SpecBegin(SPXVoucher)

__block SPXCoupon *coupon1;
__block SPXCoupon *coupon2;
__block SPXCoupon *coupon3;
__block SPXVoucher *voucher;

beforeEach(^{
  auto dummyAxis = [[SPXDummyBenefitAxis alloc] init];
  [SPXCoupon registerAxisForSerialization:dummyAxis.class withName:@"dummyName" error:nil];

  coupon1 = [SPXCoupon
             couponWithBaseProductValues:@[SPXBaseProductAxis.subscriptionPeriod.monthly,
                                           SPXBaseProductAxis.subscriptionPeriod.biYearly]
             benefitValues:@[SPXBenefitProductAxis.discountLevel.off25]];
  coupon2 = [SPXCoupon
             couponWithBaseProductValues:@[SPXBaseProductAxis.subscriptionPeriod.yearly]
             benefitValues:@[SPXBenefitProductAxis.discountLevel.off75]];
  coupon3 = [SPXCoupon
             couponWithBaseProductValues:@[]
             benefitValues:@[dummyAxis.defaultValue]];

  voucher = [[SPXVoucher alloc] initWithName:@"Test" coupons:@[coupon1, coupon2, coupon3]
                                  expiryDate:[NSDate dateWithTimeIntervalSince1970:1337]];
});

afterEach(^{
  [SPXCoupon deregisterAxisForSerialization:SPXDummyBenefitAxis.class];
});

it(@"should serialize and deserialize vouchers", ^{
  auto serializedVoucher = [MTLJSONAdapter JSONDictionaryFromModel:voucher];
  auto *jsonData = [NSJSONSerialization dataWithJSONObject:serializedVoucher options:0 error:nil];

  NSDictionary *deserializedDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0
                                                                     error:nil];
  SPXVoucher *newVoucher = [MTLJSONAdapter modelOfClass:SPXVoucher.class
                                     fromJSONDictionary:deserializedDict error:nil];
  expect(voucher).to.equal(newVoucher);
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
      },
      @{
        @"baseProductValues": @[],
        @"benefitValues": @[
          @{
            @"axis": @"dummyName",
            @"value": @"foo"
          }
        ]
      }
    ],
    @"expiryDate": @"1970-01-01T00:22:17.000Z"
  };

  NSError *error;
  SPXVoucher *voucher = [MTLJSONAdapter modelOfClass:SPXVoucher.class fromJSONDictionary:json
                                               error:&error];
  expect(voucher.name).to.equal(@"Test");
  expect(voucher.coupons).to.equal(@[coupon1, coupon2, coupon3]);
  expect(voucher.expiryDate).to.equal([NSDate dateWithTimeIntervalSince1970:1337]);
  expect(error).to.beNil();
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
  SPXVoucher *voucher = [MTLJSONAdapter modelOfClass:SPXVoucher.class fromJSONDictionary:json
                                               error:&error];
  expect(voucher).to.beNil();
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
  SPXVoucher *voucher = [MTLJSONAdapter modelOfClass:SPXVoucher.class fromJSONDictionary:json
                                               error:&error];
  expect(voucher).to.beNil();
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
  SPXVoucher *voucher = [MTLJSONAdapter modelOfClass:SPXVoucher.class fromJSONDictionary:json
                                               error:&error];
  expect(voucher).to.beNil();
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
  SPXVoucher *voucher = [MTLJSONAdapter modelOfClass:SPXVoucher.class fromJSONDictionary:json
                                               error:&error];
  expect(voucher).to.beNil();
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
  SPXVoucher *voucher = [MTLJSONAdapter modelOfClass:SPXVoucher.class fromJSONDictionary:json
                                               error:&error];
  expect(voucher).to.beNil();
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
  SPXVoucher *voucher = [MTLJSONAdapter modelOfClass:SPXVoucher.class fromJSONDictionary:json
                                               error:&error];
  expect(voucher).to.beNil();
  expect(error.code).to.equal(SPXErrorCodeDeserializationFailed);
});

it(@"should make sure all classes that conform to SPXBaseProductAxis can be serialized", ^{
  for (Class productAxis in SPXClassesConformToProtocol(@protocol(SPXBaseProductAxis))) {
    id<SPXBaseProductAxis> axis = [[productAxis alloc] init];
    auto value = [[SPXBaseProductAxisValue alloc] initWithValue:@"foo" andAxis:axis];
    auto coupon = [SPXCoupon
                   couponWithBaseProductValues:@[value]
                   benefitValues:@[SPXBenefitProductAxis.discountLevel.off25]];
    auto serializedVoucher = [MTLJSONAdapter JSONDictionaryFromModel:coupon];
    auto *jsonData = [NSJSONSerialization dataWithJSONObject:serializedVoucher options:0 error:nil];
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
    auto serializedVoucher = [MTLJSONAdapter JSONDictionaryFromModel:coupon];
    auto *jsonData = [NSJSONSerialization dataWithJSONObject:serializedVoucher options:0 error:nil];
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
    auto serializedVoucher = [voucher serializeAndSignWithKey:key error:&error];
    expect(error).to.beNil();
    expect([[NSData alloc] initWithURLSafeBase64EncodedString:serializedVoucher]).notTo.beNil();
  });

  it(@"should convert to string and back to voucher", ^{
    auto _Nullable serializedVoucher = [voucher serializeAndSignWithKey:key error:nil];
    auto _Nullable newVoucher = [SPXVoucher voucherWithSerializedString:serializedVoucher key:key
                                                                  error:nil];
    expect(newVoucher).to.equal(voucher);
  });

  it(@"should deserialize a voucher that is generated by an external script", ^{
    auto serializedVoucher = @"BjONL8DtKDWmxGWN_XyIw7rLsaYxEIt36EeIHxRW0kSYbhFWEwIQDt_hUbnJGE61p1ha"
                             "B7gDHTSs5TJXv-pQMBXfNOwLW0HPMcIG7kpZLCSIGOtpgIeXF1pFGuwZf5co-CQdVxlM5"
                             "VhG_TC7imwv_Sssz40rEonTXtudGU145KOLR_O1tVSSx6KjDj5p5GF8YByuGzL4Pxc241"
                             "T7UqPFG-etiTzZ8uITs19zHX7UMkfpljv6xjungiN9rPcKcm6uLZr3V5N8dfW0yMkvkd_"
                             "SzkO-CO1oQCkkLMRI5mwue0jKhOUm9PHswL0wP_BeQa4OEPqHtF4cGqxcbdzUF1NPZQ";

    auto _Nullable newVoucher =
        [SPXVoucher voucherWithSerializedString:serializedVoucher key:key error:nil];

    expect(newVoucher).to.equal(voucher);
  });

  it(@"should err if signature doesn't match", ^{
    auto IV = [NSMutableData dataWithLength:16];
    auto encrypted = [[[@"foo" spx_dataUsingUTF8]
                       lt_compressWithCompressionType:LTCompressionTypeZLIB error:nil]
                       lt_encryptWithKey:[[key spx_dataUsingUTF8] lt_MD5] iv:IV error:nil];
    auto signature = [[NSData data] lt_HMACSHA256WithKey:[key spx_dataUsingUTF8]];
    auto serializedVouchers = [SPXConcateDatas(@[signature, encrypted]) lt_urlSafeBase64];

    NSError *error;
    auto _Nullable newVoucher = [SPXVoucher voucherWithSerializedString:serializedVouchers key:key
                                                                  error:&error];
    expect(newVoucher).to.beNil();
    expect(error.code).equal(SPXErrorCodeSignatureValidationFailed);
  });

  it(@"should err if data it too small", ^{
    auto serializedVouchers = [[NSMutableData dataWithLength:31] lt_urlSafeBase64];

    NSError *error;
    auto _Nullable newVoucher = [SPXVoucher voucherWithSerializedString:serializedVouchers key:key
                                                                  error:&error];
    expect(newVoucher).to.beNil();
    expect(error.code).equal(SPXErrorCodeDeserializationFailed);
  });

  it(@"should err if decryption fails", ^{
    auto encrypted = [@"foobarbaz" spx_dataUsingUTF8];
    auto signature = [encrypted lt_HMACSHA256WithKey:[key spx_dataUsingUTF8]];
    auto serializedVouchers = [SPXConcateDatas(@[signature, encrypted]) lt_urlSafeBase64];

    NSError *error;
    auto _Nullable newVoucher = [SPXVoucher voucherWithSerializedString:serializedVouchers key:key
                                                                  error:&error];
    expect(newVoucher).to.beNil();
    expect(error.code).equal(SPXErrorCodeDeserializationFailed);
  });

  it(@"should err if decompressions fails", ^{
    auto IV = [NSMutableData dataWithLength:16];
    auto encrypted = [[@"foobarbaz" spx_dataUsingUTF8]
                      lt_encryptWithKey:[[key spx_dataUsingUTF8] lt_MD5] iv:IV error:nil];
    auto signature = [encrypted lt_HMACSHA256WithKey:[key spx_dataUsingUTF8]];
    auto serializedVouchers = [SPXConcateDatas(@[signature, encrypted]) lt_urlSafeBase64];

    NSError *error;
    auto _Nullable newVoucher = [SPXVoucher voucherWithSerializedString:serializedVouchers key:key
                                                                  error:&error];
    expect(newVoucher).to.beNil();
    expect(error.code).equal(SPXErrorCodeDeserializationFailed);
  });

  it(@"should err if deserialization fails", ^{
    auto IV = [NSMutableData dataWithLength:16];
    auto encrypted = [[[@"foo" spx_dataUsingUTF8]
                       lt_compressWithCompressionType:LTCompressionTypeZLIB error:nil]
                       lt_encryptWithKey:[[key spx_dataUsingUTF8] lt_MD5] iv:IV error:nil];
    auto signature = [encrypted lt_HMACSHA256WithKey:[key spx_dataUsingUTF8]];
    auto serializedVouchers = [SPXConcateDatas(@[signature, encrypted]) lt_urlSafeBase64];

    NSError *error;
    auto _Nullable newVoucher = [SPXVoucher voucherWithSerializedString:serializedVouchers key:key
                                                                      error:&error];
    expect(newVoucher).to.beNil();
    expect(error.code).equal(SPXErrorCodeDeserializationFailed);
  });
});

context(@"registering axes for serialization", ^{
  it(@"should return error when registering an already registered axis", ^{
    [SPXCoupon registerAxisForSerialization:SPXDummyBenefitAxis.class
                                   withName:@"dummyName" error:nil];

    NSError *error;
    BOOL success =
        [SPXCoupon registerAxisForSerialization:SPXDummyBenefitAxis.class
                                       withName:@"dummyName" error:&error];

    expect(success).to.beFalsy();
    expect(error).notTo.beNil();
  });

  it(@"should return error when registering a class that does not conform to SPXProductAxis", ^{
    NSError *error;
    BOOL success =
        [SPXCoupon registerAxisForSerialization:NSObject.class withName:@"fooName" error:&error];

    expect(success).to.beFalsy();
    expect(error).notTo.beNil();
  });

  it(@"should return error when axis name is already associated with another class", ^{
    NSError *error;
    BOOL success =
        [SPXCoupon registerAxisForSerialization:SPXDummyBenefitAxis.class
                                       withName:@"DiscountLevel" error:&error];

    expect(success).to.beFalsy();
    expect(error).notTo.beNil();
  });
});

context(@"de-registering axis for serialization", ^{
  it(@"should fail serialization after de-registering axis", ^{
    [SPXCoupon registerAxisForSerialization:SPXDummyBenefitAxis.class
                                   withName:@"dummyName" error:nil];
    [SPXCoupon deregisterAxisForSerialization:SPXDummyBenefitAxis.class];

    NSDictionary *json = @{
      @"name": @"Test",
      @"coupons": @[
        @{
          @"baseProductValues": @[],
          @"benefitValues": @[
            @{
              @"axis": @"dummyName",
              @"value": @"foo"
            }
          ]
        }
      ],
      @"expiryDate": @"1970-01-01T00:22:17.000Z"
    };

    NSError *error;
    SPXVoucher *newVoucher = [MTLJSONAdapter modelOfClass:SPXVoucher.class fromJSONDictionary:json
                                                 error:&error];

    expect(newVoucher).to.beNil();
    expect(error).notTo.beNil();
  });
});

SpecEnd
