// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTAttributeData.h"

#import "LTGPUStruct.h"

LTGPUStructMake(TestStruct,
                float, value0,
                float, value1);

LTGPUStructMake(AnotherTestStruct,
                float, value0);

SpecBegin(LTAttributeData)

__block NSData *data;
__block LTGPUStruct *gpuStruct;

beforeEach(^{
  std::vector<float> values{1, 2, 3, 4};
  data = [NSData dataWithBytes:&values[0] length:values.size() * sizeof(values[0])];
  gpuStruct = [[LTGPUStructRegistry sharedInstance] structForName:@"TestStruct"];
});

afterEach(^{
  data = nil;
  gpuStruct = nil;
});

context(@"initialization", ^{
  it(@"should raise when providing data whose length is not a multiple of the format length", ^{
    std::vector<float> values{1};
    data = [NSData dataWithBytes:&values[0] length:values.size() * sizeof(values[0])];
    expect(^{
      LTAttributeData __unused *attributeData =
          [[LTAttributeData alloc] initWithData:data inFormatOfGPUStruct:gpuStruct];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize with the given data of the given format", ^{
    LTAttributeData *attributeData =
        [[LTAttributeData alloc] initWithData:data inFormatOfGPUStruct:gpuStruct];
    expect(attributeData.data).to.equal(data);
    expect(attributeData.gpuStruct).to.equal(gpuStruct);
  });
});

context(@"NSObject protocol", ^{
  __block LTAttributeData *attributeData;

  beforeEach(^{
    attributeData = [[LTAttributeData alloc] initWithData:data inFormatOfGPUStruct:gpuStruct];
  });

  context(@"equality", ^{
    it(@"should return YES when comparing to itself", ^{
      expect([attributeData isEqual:attributeData]).to.beTruthy();
    });

    it(@"should return YES when comparing to equal attribute data", ^{
      LTAttributeData *anotherAttributeData =
          [[LTAttributeData alloc] initWithData:data inFormatOfGPUStruct:gpuStruct];
      expect([attributeData isEqual:anotherAttributeData]).to.beTruthy();
    });

    it(@"should return NO when comparing to nil", ^{
      expect([attributeData isEqual:nil]).to.beFalsy();
    });

    it(@"should return NO when comparing to an object of a different class", ^{
      expect([attributeData isEqual:[[NSObject alloc] init]]).to.beFalsy();
    });

    it(@"should return NO when comparing to point with different binary data", ^{
      std::vector<float> values{1, 2, 3, 5};
      data = [NSData dataWithBytes:&values[0] length:values.size() * sizeof(values[0])];
      LTAttributeData *anotherAttributeData =
          [[LTAttributeData alloc] initWithData:data inFormatOfGPUStruct:gpuStruct];
      expect([attributeData isEqual:anotherAttributeData]).to.beFalsy();
    });

    it(@"should return NO when comparing to point with different gpu struct", ^{
      LTGPUStruct *anotherGPUStruct =
          [[LTGPUStructRegistry sharedInstance] structForName:@"AnotherTestStruct"];
      LTAttributeData *anotherAttributeData =
          [[LTAttributeData alloc] initWithData:data inFormatOfGPUStruct:anotherGPUStruct];
      expect([attributeData isEqual:anotherAttributeData]).to.beFalsy();
    });
  });

  context(@"hash", ^{
    it(@"should return the same hash value for equal objects", ^{
      LTAttributeData *anotherAttributeData =
          [[LTAttributeData alloc] initWithData:data inFormatOfGPUStruct:gpuStruct];
      expect([attributeData hash]).to.equal([anotherAttributeData hash]);
    });
  });
});

SpecEnd
