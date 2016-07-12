// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "LTCompressionType.h"

SpecBegin(LTCompressionType)

it(@"should return file extention for every compression type", ^{
  [LTCompressionType enumerateEnumUsingBlock:^(LTCompressionType *value) {
    expect(value.fileExtention.length).to.beGreaterThan(0);
  }];
});

it(@"should return mime type for every compression type", ^{
  [LTCompressionType enumerateEnumUsingBlock:^(LTCompressionType *value) {
    expect(value.mimeType.length).to.beGreaterThan(0);
  }];
});

it(@"should return UTI for every compression type", ^{
  [LTCompressionType enumerateEnumUsingBlock:^(LTCompressionType *value) {
    expect(value.UTI.length).to.beGreaterThan(0);
  }];
});

SpecEnd
