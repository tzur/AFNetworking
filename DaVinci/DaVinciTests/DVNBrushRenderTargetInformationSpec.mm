// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushRenderTargetInformation.h"

SpecBegin(DVNBrushRenderTargetInformation)

context(@"factory methods", ^{
  it(@"should return a new instance", ^{
    lt::Quad quad = lt::Quad::canonicalSquare();
    DVNBrushRenderTargetInformation *information =
        [DVNBrushRenderTargetInformation instanceWithRenderTargetLocation:quad
                                             renderTargetHasSingleChannel:YES
                                           renderTargetIsNonPremultiplied:YES
                                             renderTargetHasBytePrecision:YES];
    expect(information.renderTargetLocation == quad).to.beTruthy();
    expect(information.renderTargetHasSingleChannel).to.beTruthy();
    expect(information.renderTargetIsNonPremultiplied).to.beTruthy();
    expect(information.renderTargetHasBytePrecision).to.beTruthy();
  });
});

SpecEnd
