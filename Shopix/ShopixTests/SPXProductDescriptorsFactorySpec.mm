// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SPXProductDescriptorsFactory.h"

#import "NSErrorCodes+Shopix.h"
#import "SPXProductAxis.h"
#import "SPXProductDescriptor.h"
#import "SPXVoucher.h"

static NSString * const kVersion = @"V4";
static NSString * const kPrefix = @"com.lightricks.test";

SpecBegin(SPXProductDescriptorsFactory)

__block id<SPXBaseProductAxis> baseAxis1;
__block id<SPXBaseProductAxis> baseAxis2;
__block id<SPXBenefitAxis> benefitAxis1;
__block id<SPXBenefitAxis> benefitAxis2;

beforeEach(^{
  baseAxis1 = OCMProtocolMock(@protocol(SPXBaseProductAxis));
  OCMStub([baseAxis1 values]).andReturn((@[
    [SPXBaseProductAxisValue axisValueWithValue:@"Base1V1" andAxis:baseAxis1],
    [SPXBaseProductAxisValue axisValueWithValue:@"Base1V2" andAxis:baseAxis1]
  ]));
  baseAxis2 = OCMProtocolMock(@protocol(SPXBaseProductAxis));
  OCMStub([baseAxis2 values]).andReturn((@[
      [SPXBaseProductAxisValue axisValueWithValue:@"Base2V1" andAxis:baseAxis2],
      [SPXBaseProductAxisValue axisValueWithValue:@"Base2V2" andAxis:baseAxis2]
  ]));
  benefitAxis1 = OCMProtocolMock(@protocol(SPXBenefitAxis));
  OCMStub([benefitAxis1 values]).andReturn((@[
    [SPXBenefitAxisValue axisValueWithValue:@"Benefit1V1" andAxis:benefitAxis1],
    [SPXBenefitAxisValue axisValueWithValue:@"Benefit1V2" andAxis:benefitAxis1]
  ]));
  OCMStub([benefitAxis1 defaultValue]).andReturn(benefitAxis1.values[0]);
  benefitAxis2 = OCMProtocolMock(@protocol(SPXBenefitAxis));
  OCMStub([benefitAxis2 values]).andReturn((@[
    [SPXBenefitAxisValue axisValueWithValue:@"Benefit2V1" andAxis:benefitAxis2],
    [SPXBenefitAxisValue axisValueWithValue:@"Benefit2V2" andAxis:benefitAxis2]
  ]));
  OCMStub([benefitAxis2 defaultValue]).andReturn(benefitAxis2.values[1]);
});

context(@"initialization", ^{
  it(@"should fail to initialize when no base product axis are given", ^{
    auto productAxis = @[benefitAxis1, benefitAxis2];
    auto baseStoreProducts = @[];

    expect(^{
      auto factory __unused = [[SPXProductDescriptorsFactory alloc] initWithProductAxes:productAxis
                               version:kVersion prefix:kPrefix baseProducts:baseStoreProducts];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail to initialize when there are duplicate product axes", ^{
    auto productAxis = @[benefitAxis1, benefitAxis1, baseAxis1];
    auto baseStoreProducts = @[@[baseAxis1.values[0]], @[baseAxis1.values[1]]];

    expect(^{
      auto factory __unused = [[SPXProductDescriptorsFactory alloc] initWithProductAxes:productAxis
                               version:kVersion prefix:kPrefix baseProducts:baseStoreProducts];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail to initialize when a product provide value with axis not in base axes list", ^{
    auto productAxis = @[benefitAxis1, baseAxis1];
    auto baseStoreProducts = @[
      @[baseAxis1.values[0]],
      @[baseAxis2.values[1]]
    ];

    expect(^{
      auto factory __unused = [[SPXProductDescriptorsFactory alloc] initWithProductAxes:productAxis
                               version:kVersion prefix:kPrefix baseProducts:baseStoreProducts];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail to initialize when a product does not provide values for all base axes ", ^{
    auto productAxis = @[benefitAxis1, baseAxis1, baseAxis2];
    auto baseStoreProducts = @[
      @[baseAxis1.values[0], baseAxis2.values[0]],
      @[baseAxis1.values[1]]
    ];

    expect(^{
      auto factory __unused = [[SPXProductDescriptorsFactory alloc] initWithProductAxes:productAxis
                               version:kVersion prefix:kPrefix baseProducts:baseStoreProducts];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"product descriptors generation", ^{
  __block SPXProductDescriptorsFactory *factory;

  beforeEach(^{
    auto productAxis = @[benefitAxis1, benefitAxis2, baseAxis1, baseAxis2];
    auto baseStoreProducts = @[
      @[baseAxis1.values[0], baseAxis2.values[1]],
      @[baseAxis1.values[1], baseAxis2.values[0]],
    ];
    factory = [[SPXProductDescriptorsFactory alloc] initWithProductAxes:productAxis
               version:kVersion prefix:kPrefix baseProducts:baseStoreProducts];
  });

  context(@"from voucher", ^{
    it(@"should create descriptors with default benefit values when no voucher provided", ^{
      NSError *error;
      auto _Nullable descriptors = [factory productDescriptorsWithVoucher:nil withError:&error];

      expect(descriptors).haveCount(2);
      expect(descriptors[0].identifier)
          .to.equal(@"com.lightricks.test.V4.Benefit1V1.Benefit2V2.Base1V1.Base2V2");
      expect(descriptors[0].baseProductValues)
          .to.equal([@[baseAxis1.values[0], baseAxis2.values[1]] lt_set]);
      expect(descriptors[0].benefitValues)
          .to.equal([@[benefitAxis1.values[0], benefitAxis2.values[1]] lt_set]);
      expect(descriptors[1].identifier)
          .to.equal(@"com.lightricks.test.V4.Benefit1V1.Benefit2V2.Base1V2.Base2V1");
      expect(descriptors[1].baseProductValues)
          .to.equal([@[baseAxis1.values[1], baseAxis2.values[0]] lt_set]);
      expect(descriptors[1].benefitValues)
          .to.equal([@[benefitAxis1.values[0], benefitAxis2.values[1]] lt_set]);
    });

    it(@"should create product descriptors according to the provided voucher", ^{
      auto *coupon1 = [SPXCoupon
                       couponWithBaseProductValues:@[baseAxis1.values[0], baseAxis2.values[1]]
                       benefitValues:@[benefitAxis1.values[1]]];
      auto *coupon2 = [SPXCoupon
                       couponWithBaseProductValues:@[baseAxis1.values[1]]
                       benefitValues:@[benefitAxis1.values[1], benefitAxis2.values[0]]];
      auto voucher = [[SPXVoucher alloc] initWithName:@"Test" coupons:@[coupon1, coupon2]
                                           expiryDate:[NSDate distantFuture]];
      NSError *error;
      auto _Nullable descriptors = [factory productDescriptorsWithVoucher:voucher withError:&error];

      expect(descriptors).haveCount(2);
      expect(descriptors[0].identifier)
          .to.equal(@"com.lightricks.test.V4.Benefit1V2.Benefit2V2.Base1V1.Base2V2");
      expect(descriptors[0].baseProductValues)
          .to.equal([@[baseAxis1.values[0], baseAxis2.values[1]] lt_set]);
      expect(descriptors[0].benefitValues)
          .to.equal([@[benefitAxis1.values[1], benefitAxis2.values[1]] lt_set]);
      expect(descriptors[1].identifier)
          .to.equal(@"com.lightricks.test.V4.Benefit1V2.Benefit2V1.Base1V2.Base2V1");
      expect(descriptors[1].baseProductValues)
          .to.equal([@[baseAxis1.values[1], baseAxis2.values[0]] lt_set]);
      expect(descriptors[1].benefitValues)
          .to.equal([@[benefitAxis1.values[1], benefitAxis2.values[0]] lt_set]);
    });

    it(@"should apply a single coupon to multiple products", ^{
      auto *coupon = [SPXCoupon
                       couponWithBaseProductValues:@[]
                       benefitValues:@[benefitAxis1.values[1], benefitAxis2.values[0]]];
      auto voucher = [[SPXVoucher alloc] initWithName:@"Test" coupons:@[coupon]
                                           expiryDate:[NSDate distantFuture]];
      NSError *error;
      auto _Nullable descriptors = [factory productDescriptorsWithVoucher:voucher withError:&error];

      expect(descriptors).haveCount(2);
      expect(descriptors[0].identifier)
          .to.equal(@"com.lightricks.test.V4.Benefit1V2.Benefit2V1.Base1V1.Base2V2");
      expect(descriptors[0].baseProductValues)
          .to.equal([@[baseAxis1.values[0], baseAxis2.values[1]] lt_set]);
      expect(descriptors[0].benefitValues)
          .to.equal([@[benefitAxis1.values[1], benefitAxis2.values[0]] lt_set]);
      expect(descriptors[1].identifier)
          .to.equal(@"com.lightricks.test.V4.Benefit1V2.Benefit2V1.Base1V2.Base2V1");
      expect(descriptors[1].baseProductValues)
          .to.equal([@[baseAxis1.values[1], baseAxis2.values[0]] lt_set]);
      expect(descriptors[1].benefitValues)
          .to.equal([@[benefitAxis1.values[1], benefitAxis2.values[0]] lt_set]);
    });

    it(@"should return error when an expired coupon is applied", ^{
      auto *coupon = [SPXCoupon
                      couponWithBaseProductValues:@[baseAxis1.values[0]]
                      benefitValues:@[benefitAxis1.values[1]]];
      auto voucher = [[SPXVoucher alloc]
                      initWithName:@"Test" coupons:@[coupon]
                      expiryDate:[[NSDate date] dateByAddingTimeInterval:-1]];
      NSError *error;
      auto _Nullable descriptors = [factory productDescriptorsWithVoucher:voucher withError:&error];

      expect(descriptors).to.beNil();
      expect(error.code).to.equal(SPXErrorCodeVoucherExpired);
      expect(error.lt_isLTDomain).to.beTruthy();
    });

    it(@"should err when a coupon has duplicate benefit axis", ^{
      auto *coupon = [SPXCoupon
                      couponWithBaseProductValues:@[baseAxis1.values[0]]
                      benefitValues:@[benefitAxis1.values[0], benefitAxis1.values[1]]];
      auto voucher = [[SPXVoucher alloc] initWithName:@"Test" coupons:@[coupon]
                                           expiryDate:[NSDate distantFuture]];
      NSError *error;
      auto _Nullable descriptors = [factory productDescriptorsWithVoucher:voucher withError:&error];

      expect(descriptors).to.beNil();
      expect(error.code).to.equal(SPXErrorCodeInvalidCoupon);
      expect(error.lt_isLTDomain).to.beTruthy();
    });

    it(@"should err when a voucher has conflicting coupons", ^{
      auto *coupon1 = [SPXCoupon
                       couponWithBaseProductValues:@[baseAxis1.values[0], baseAxis2.values[1]]
                       benefitValues:@[benefitAxis1.values[1]]];
      auto *coupon2 = [SPXCoupon
                       couponWithBaseProductValues:@[baseAxis1.values[0]]
                       benefitValues:@[benefitAxis1.values[1], benefitAxis2.values[0]]];
      auto *voucher = [[SPXVoucher alloc] initWithName:@"Test" coupons:@[coupon1, coupon2]
                                            expiryDate:[NSDate distantFuture]];
      NSError *error;
      auto _Nullable descriptors = [factory productDescriptorsWithVoucher:voucher withError:&error];

      expect(descriptors).to.beNil();
      expect(error.code).to.equal(SPXErrorCodeConflictingCoupons);
      expect(error.lt_isLTDomain).to.beTruthy();
    });
  });

  context(@"from coupons", ^{
    it(@"should create descriptors with default benefit values when no coupons provided", ^{
      NSError *error;
      auto _Nullable descriptors = [factory productDescriptorsWithCoupons:nil withError:&error];

      expect(descriptors).haveCount(2);
      expect(descriptors[0].identifier)
          .to.equal(@"com.lightricks.test.V4.Benefit1V1.Benefit2V2.Base1V1.Base2V2");
      expect(descriptors[0].baseProductValues)
          .to.equal([@[baseAxis1.values[0], baseAxis2.values[1]] lt_set]);
      expect(descriptors[0].benefitValues)
          .to.equal([@[benefitAxis1.values[0], benefitAxis2.values[1]] lt_set]);
      expect(descriptors[1].identifier)
          .to.equal(@"com.lightricks.test.V4.Benefit1V1.Benefit2V2.Base1V2.Base2V1");
      expect(descriptors[1].baseProductValues)
          .to.equal([@[baseAxis1.values[1], baseAxis2.values[0]] lt_set]);
      expect(descriptors[1].benefitValues)
          .to.equal([@[benefitAxis1.values[0], benefitAxis2.values[1]] lt_set]);
    });

    it(@"should create product descriptors according to the provided coupons", ^{
      auto *coupon1 = [SPXCoupon
                       couponWithBaseProductValues:@[baseAxis1.values[0], baseAxis2.values[1]]
                       benefitValues:@[benefitAxis1.values[1]]];
      auto *coupon2 = [SPXCoupon
                       couponWithBaseProductValues:@[baseAxis1.values[1]]
                       benefitValues:@[benefitAxis1.values[1], benefitAxis2.values[0]]];
      NSError *error;
      auto _Nullable descriptors = [factory productDescriptorsWithCoupons:@[coupon1, coupon2]
                                                                withError:&error];

      expect(descriptors).haveCount(2);
      expect(descriptors[0].identifier)
          .to.equal(@"com.lightricks.test.V4.Benefit1V2.Benefit2V2.Base1V1.Base2V2");
      expect(descriptors[0].baseProductValues)
          .to.equal([@[baseAxis1.values[0], baseAxis2.values[1]] lt_set]);
      expect(descriptors[0].benefitValues)
          .to.equal([@[benefitAxis1.values[1], benefitAxis2.values[1]] lt_set]);
      expect(descriptors[1].identifier)
          .to.equal(@"com.lightricks.test.V4.Benefit1V2.Benefit2V1.Base1V2.Base2V1");
      expect(descriptors[1].baseProductValues)
          .to.equal([@[baseAxis1.values[1], baseAxis2.values[0]] lt_set]);
      expect(descriptors[1].benefitValues)
          .to.equal([@[benefitAxis1.values[1], benefitAxis2.values[0]] lt_set]);
    });

    it(@"should apply a single coupon to multiple products", ^{
      auto *coupon = [SPXCoupon
                       couponWithBaseProductValues:@[]
                       benefitValues:@[benefitAxis1.values[1], benefitAxis2.values[0]]];
      NSError *error;
      auto _Nullable descriptors = [factory productDescriptorsWithCoupons:@[coupon]
                                                                withError:&error];

      expect(descriptors).haveCount(2);
      expect(descriptors[0].identifier)
          .to.equal(@"com.lightricks.test.V4.Benefit1V2.Benefit2V1.Base1V1.Base2V2");
      expect(descriptors[0].baseProductValues)
          .to.equal([@[baseAxis1.values[0], baseAxis2.values[1]] lt_set]);
      expect(descriptors[0].benefitValues)
          .to.equal([@[benefitAxis1.values[1], benefitAxis2.values[0]] lt_set]);
      expect(descriptors[1].identifier)
          .to.equal(@"com.lightricks.test.V4.Benefit1V2.Benefit2V1.Base1V2.Base2V1");
      expect(descriptors[1].baseProductValues)
          .to.equal([@[baseAxis1.values[1], baseAxis2.values[0]] lt_set]);
      expect(descriptors[1].benefitValues)
          .to.equal([@[benefitAxis1.values[1], benefitAxis2.values[0]] lt_set]);
    });

    it(@"should err when a coupon has duplicate benefit axis", ^{
      auto *coupon = [SPXCoupon
                      couponWithBaseProductValues:@[baseAxis1.values[0]]
                      benefitValues:@[benefitAxis1.values[0], benefitAxis1.values[1]]];
      NSError *error;
      auto _Nullable descriptors = [factory productDescriptorsWithCoupons:@[coupon]
                                                                withError:&error];

      expect(descriptors).to.beNil();
      expect(error.code).to.equal(SPXErrorCodeInvalidCoupon);
      expect(error.lt_isLTDomain).to.beTruthy();
    });

    it(@"should err when coupons are conflicting", ^{
      auto *coupon1 = [SPXCoupon
                       couponWithBaseProductValues:@[baseAxis1.values[0], baseAxis2.values[1]]
                       benefitValues:@[benefitAxis1.values[1]]];
      auto *coupon2 = [SPXCoupon
                       couponWithBaseProductValues:@[baseAxis1.values[0]]
                       benefitValues:@[benefitAxis1.values[1], benefitAxis2.values[0]]];
      NSError *error;
      auto _Nullable descriptors = [factory productDescriptorsWithCoupons:@[coupon1, coupon2]
                                                                withError:&error];

      expect(descriptors).to.beNil();
      expect(error.code).to.equal(SPXErrorCodeConflictingCoupons);
      expect(error.lt_isLTDomain).to.beTruthy();
    });
  });
});

SpecEnd
