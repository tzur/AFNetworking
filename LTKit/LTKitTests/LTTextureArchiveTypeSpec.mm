// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureArchiveType.h"

LTSpecBegin(LTTextureArchiveType)

it(@"should return a the archiver that should be used for each enum value", ^{
  [LTTextureArchiveType enumerateEnumUsingBlock:^(LTTextureArchiveType *value) {
    expect(value.archiver).notTo.beNil();
  }];
});

it(@"should return the file extension assoicated with each enum value", ^{
  [LTTextureArchiveType enumerateEnumUsingBlock:^(LTTextureArchiveType *value) {
    expect(value.fileExtension).notTo.beNil();
    expect(value.fileExtension.length).to.beGreaterThan(0);
  }];
});

LTSpecEnd
