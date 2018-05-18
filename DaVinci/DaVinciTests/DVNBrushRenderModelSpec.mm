// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushRenderModel.h"

#import "DVNBrushModel.h"
#import "DVNBrushRenderTargetInformation.h"

SpecBegin(DVNBrushRenderModel)

__block DVNBrushModel *brushModel;
__block DVNBrushRenderTargetInformation *renderTargetInfo;

beforeEach(^{
  brushModel = OCMClassMock([DVNBrushModel class]);
  renderTargetInfo = OCMClassMock([DVNBrushRenderTargetInformation class]);
});

context(@"factory methods", ^{
  it(@"should return a new instance with render target info", ^{
    auto model = [DVNBrushRenderModel instanceWithBrushModel:brushModel
                                            renderTargetInfo:renderTargetInfo conversionFactor:0.7];
    expect(model.brushModel).to.equal(brushModel);
    expect(model.renderTargetInfo).to.equal(renderTargetInfo);
    expect(model.conversionFactor).to.equal(0.7);
  });

  it(@"should return a new instance with given parameters", ^{
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

context(@"copy methods", ^{
  it(@"should return a copy with a given brush model", ^{
    DVNBrushModel *anotherBrushModel = OCMClassMock([DVNBrushModel class]);
    auto model = [DVNBrushRenderModel instanceWithBrushModel:brushModel
                                            renderTargetInfo:renderTargetInfo conversionFactor:0.7];
    auto modelCopy = [model copyWithBrushModel:anotherBrushModel];
    expect(modelCopy).toNot.equal(model);
    expect(modelCopy.brushModel).to.equal(anotherBrushModel);
    expect(model.renderTargetInfo).to.equal(renderTargetInfo);
    expect(model.conversionFactor).to.equal(0.7);
  });
});

SpecEnd
