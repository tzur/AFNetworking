// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "MTBFunctionConstant.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcomma"
#import <half.hpp>
#pragma clang diagnostic pop

SpecBegin(MTBFunctionConstant)

it(@"should create bool constant correctly", ^{
  BOOL value = YES;
  auto constant = [MTBFunctionConstant boolConstantWithValue:value name:@"foo"];
  expect(constant.name).to.equal(@"foo");
  expect(constant.type).to.equal(MTLDataTypeBool);

  auto data = [NSData dataWithBytes:&value length:sizeof(BOOL)];
  expect(constant.value).to.equal(data);
});

it(@"should create short constant correctly", ^{
  short value = 1;
  auto constant = [MTBFunctionConstant shortConstantWithValue:value name:@"foo"];
  expect(constant.name).to.equal(@"foo");
  expect(constant.type).to.equal(MTLDataTypeShort);

  auto data = [NSData dataWithBytes:&value length:sizeof(short)];
  expect(constant.value).to.equal(data);
});

it(@"should create short2 constant correctly", ^{
  simd_short2 value = {1, 2};
  auto constant = [MTBFunctionConstant short2ConstantWithValue:value name:@"foo"];
  expect(constant.name).to.equal(@"foo");
  expect(constant.type).to.equal(MTLDataTypeShort2);

  auto data = [NSData dataWithBytes:&value length:sizeof(simd_short2)];
  expect(constant.value).to.equal(data);
});

it(@"should create short4 constant correctly", ^{
  simd_short4 value = {1, 2, 3, 4};
  auto constant = [MTBFunctionConstant short4ConstantWithValue:value name:@"foo"];
  expect(constant.name).to.equal(@"foo");
  expect(constant.type).to.equal(MTLDataTypeShort4);

  auto data = [NSData dataWithBytes:&value length:sizeof(simd_short4)];
  expect(constant.value).to.equal(data);
});

it(@"should create ushort constant correctly", ^{
  ushort value = 1;
  auto constant = [MTBFunctionConstant ushortConstantWithValue:value name:@"foo"];
  expect(constant.name).to.equal(@"foo");
  expect(constant.type).to.equal(MTLDataTypeUShort);

  auto data = [NSData dataWithBytes:&value length:sizeof(ushort)];
  expect(constant.value).to.equal(data);
});

it(@"should create ushort2 constant correctly", ^{
  simd_ushort2 value = {1, 2};
  auto constant = [MTBFunctionConstant ushort2ConstantWithValue:value name:@"foo"];
  expect(constant.name).to.equal(@"foo");
  expect(constant.type).to.equal(MTLDataTypeUShort2);

  auto data = [NSData dataWithBytes:&value length:sizeof(simd_ushort2)];
  expect(constant.value).to.equal(data);
});

it(@"should create ushort4 constant correctly", ^{
  simd_ushort4 value = {1, 2, 3, 4};
  auto constant = [MTBFunctionConstant ushort4ConstantWithValue:value name:@"foo"];
  expect(constant.name).to.equal(@"foo");
  expect(constant.type).to.equal(MTLDataTypeUShort4);

  auto data = [NSData dataWithBytes:&value length:sizeof(simd_ushort4)];
  expect(constant.value).to.equal(data);
});

it(@"should create uint constant correctly", ^{
  uint value = 1;
  auto constant = [MTBFunctionConstant uintConstantWithValue:value name:@"foo"];
  expect(constant.name).to.equal(@"foo");
  expect(constant.type).to.equal(MTLDataTypeUInt);

  auto data = [NSData dataWithBytes:&value length:sizeof(uint)];
  expect(constant.value).to.equal(data);
});

it(@"should create uint2 constant correctly", ^{
  simd_uint2 value = {1, 2};
  auto constant = [MTBFunctionConstant uint2ConstantWithValue:value name:@"foo"];
  expect(constant.name).to.equal(@"foo");
  expect(constant.type).to.equal(MTLDataTypeUInt2);

  auto data = [NSData dataWithBytes:&value length:sizeof(simd_uint2)];
  expect(constant.value).to.equal(data);
});

it(@"should create uint4 constant correctly", ^{
  simd_uint4 value = {1, 2, 3, 4};
  auto constant = [MTBFunctionConstant uint4ConstantWithValue:value name:@"foo"];
  expect(constant.name).to.equal(@"foo");
  expect(constant.type).to.equal(MTLDataTypeUInt4);

  auto data = [NSData dataWithBytes:&value length:sizeof(simd_uint4)];
  expect(constant.value).to.equal(data);
});

it(@"should create float constant correctly", ^{
  float value = 0.1;
  auto constant = [MTBFunctionConstant floatConstantWithValue:value name:@"foo"];
  expect(constant.name).to.equal(@"foo");
  expect(constant.type).to.equal(MTLDataTypeFloat);

  auto data = [NSData dataWithBytes:&value length:sizeof(float)];
  expect(constant.value).to.equal(data);
});

it(@"should create half float constant correctly", ^{
  half_float::half value(0.1);
  auto constant = [MTBFunctionConstant halfConstantWithValue:value name:@"foo"];
  expect(constant.name).to.equal(@"foo");
  expect(constant.type).to.equal(MTLDataTypeHalf);

  auto data = [NSData dataWithBytes:&value length:sizeof(half_float::half)];
  expect(constant.value).to.equal(data);
});

SpecEnd
