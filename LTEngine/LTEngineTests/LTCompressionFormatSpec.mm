// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "LTCompressionFormat.h"

SpecBegin(LTCompressionFormat)

it(@"should return file extension for every compression format", ^{
  [LTCompressionFormat enumerateEnumUsingBlock:^(LTCompressionFormat *value) {
    expect(value.fileExtension.length).to.beGreaterThan(0);
  }];
});

it(@"should return mime type for every compression format", ^{
  [LTCompressionFormat enumerateEnumUsingBlock:^(LTCompressionFormat *value) {
    expect(value.mimeType.length).to.beGreaterThan(0);
  }];
});

it(@"should return UTI for every compression extension", ^{
  [LTCompressionFormat enumerateEnumUsingBlock:^(LTCompressionFormat *value) {
    expect(value.UTI.length).to.beGreaterThan(0);
  }];
});

it(@"should report supported formats on simulator", ^{
  [LTCompressionFormat enumerateEnumUsingBlock:^(LTCompressionFormat *format) {
    if ([format isEqual:$(LTCompressionFormatHEIC)]) {
      /// LTCompressionFormatHEIC isn't supported on simulator
      expect(format.isSupported).to.beFalsy();
    } else {
      expect(format.isSupported).to.beTruthy();
    }
  }];
});

SpecEnd
