// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTIZFastMath.h"

SpecBegin(LTIZFastMath)

it(@"should generate correct bit mask", ^{
  expect(LTBitMask(0)).to.equal(0);
  expect(LTBitMask(1)).to.equal(1);
  expect(LTBitMask(2)).to.equal(3);
  expect(LTBitMask(8)).to.equal(0xFF);
  expect(LTBitMask(31)).to.equal(0x7FFFFFFF);
});

it(@"should convert from signed to unsigned and from unsigned to signed", ^{
  expect(LTUnsignedToSigned(LTSignedToUnsigned(0))).to.equal(0);
  expect(LTUnsignedToSigned(LTSignedToUnsigned(1))).to.equal(1);
  expect(LTUnsignedToSigned(LTSignedToUnsigned(-1))).to.equal(-1);
  expect(LTUnsignedToSigned(LTSignedToUnsigned(INT32_MAX))).to.equal(INT32_MAX);
  expect(LTUnsignedToSigned(LTSignedToUnsigned(INT32_MIN))).to.equal(INT32_MIN);
});

it(@"should convert from unsigned to signed and from signed to unsigned", ^{
  expect(LTSignedToUnsigned(LTUnsignedToSigned(0))).to.equal(0);
  expect(LTSignedToUnsigned(LTUnsignedToSigned(1))).to.equal(1);
  expect(LTSignedToUnsigned(LTUnsignedToSigned(UINT32_MAX))).to.equal(UINT32_MAX);
});

it(@"should cancel value correctly", ^{
  expect(LTCancelValue(7, -1)).to.equal(0);
  expect(LTCancelValue(7, 0)).to.equal(0);
  expect(LTCancelValue(7, 1)).to.equal(7);
  expect(LTCancelValue(7, INT32_MAX)).to.equal(7);

  expect(LTCancelValue(-5, -1)).to.equal(0);
  expect(LTCancelValue(-5, 0)).to.equal(0);
  expect(LTCancelValue(-5, 1)).to.equal(-5);
  expect(LTCancelValue(-5, INT32_MAX)).to.equal(-5);
});

it(@"should bit scan reverse correctly", ^{
  expect(LTBitScanReversed(1)).to.equal(0);
  expect(LTBitScanReversed(2)).to.equal(1);
  expect(LTBitScanReversed(3)).to.equal(1);
  expect(LTBitScanReversed(UINT32_MAX)).to.equal(31);
});

it(@"should count number of bits correctly", ^{
  expect(LTNumberOfBits(0)).to.equal(0);
  expect(LTNumberOfBits(1)).to.equal(1);
  expect(LTNumberOfBits(2)).to.equal(2);
  expect(LTNumberOfBits(3)).to.equal(2);
  expect(LTNumberOfBits(0xFFFF)).to.equal(16);
  expect(LTNumberOfBits(INT32_MAX)).to.equal(31);
});

SpecEnd
