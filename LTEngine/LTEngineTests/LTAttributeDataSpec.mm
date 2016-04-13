// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTAttributeData.h"

#import "LTGPUStruct.h"

LTGPUStructMake(TestStruct,
                float, value0,
                float, value1);

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

SpecEnd
