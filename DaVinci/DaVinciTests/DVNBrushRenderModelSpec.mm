// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushRenderModel.h"

#import "DVNBrushModel.h"
#import "DVNBrushRenderTargetInformation.h"

SpecBegin(DVNBrushRenderModel)

context(@"factory methods", ^{
  it(@"should return a new instance with render target info", ^{
    DVNBrushModel *brushModel = OCMClassMock([DVNBrushModel class]);
    DVNBrushRenderTargetInformation *renderTargetInfo =
        OCMClassMock([DVNBrushRenderTargetInformation class]);
    auto model = [DVNBrushRenderModel instanceWithBrushModel:brushModel
                                            renderTargetInfo:renderTargetInfo conversionFactor:0.7];
    expect(model.brushModel).to.equal(brushModel);
    expect(model.renderTargetInfo).to.equal(renderTargetInfo);
    expect(model.conversionFactor).to.equal(0.7);
  });

  it(@"should return a new instance with given parameters", ^{
    DVNBrushModel *brushModel = OCMClassMock([DVNBrushModel class]);
    DVNBrushRenderTargetInformation *renderTargetInfo =
    [DVNBrushRenderTargetInformation instanceWithRenderTargetLocation:lt::Quad::canonicalSquare()
                                         renderTargetHasSingleChannel:YES
                                       renderTargetIsNonPremultiplied:NO];
    auto model = [DVNBrushRenderModel instanceWithBrushModel:brushModel
                                        renderTargetLocation:lt::Quad::canonicalSquare()
                                renderTargetHasSingleChannel:YES renderTargetIsNonPremultiplied:NO
                                            conversionFactor:0.7];
    expect(model.brushModel).to.equal(brushModel);
    expect(model.renderTargetInfo).to.equal(renderTargetInfo);
    expect(model.conversionFactor).to.equal(0.7);
  });
});

SpecEnd
