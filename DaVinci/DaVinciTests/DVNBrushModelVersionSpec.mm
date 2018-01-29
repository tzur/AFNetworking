// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModelVersion.h"

#import "DVNBrushModelV1.h"

SpecBegin(DVNBrushModelVersion)

static NSDictionary<DVNBrushModelVersion *, Class> * const kVersionToClass = @{
  $(DVNBrushModelVersionV1): [DVNBrushModelV1 class]
};

context(@"initialization", ^{
  it(@"should return the class of the corresponding brush model", ^{
    [DVNBrushModelVersion enumerateEnumUsingBlock:^(DVNBrushModelVersion *version) {
      expect([version classOfBrushModel]).to.equal(kVersionToClass[version]);
    }];
  });
});

SpecEnd
