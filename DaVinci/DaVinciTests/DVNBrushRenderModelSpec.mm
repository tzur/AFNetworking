// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushRenderModel.h"

#import "DVNBrushModel.h"
#import "DVNBrushRenderTargetInformation.h"

SpecBegin(DVNBrushRenderModel)

context(@"factory methods", ^{
  it(@"should return a new instance", ^{
    DVNBrushModel *brushModel = OCMClassMock([DVNBrushModel class]);
    DVNBrushRenderTargetInformation *renderTargetInfo =
        OCMClassMock([DVNBrushRenderTargetInformation class]);
    auto model = [DVNBrushRenderModel instanceWithBrushModel:brushModel
                                            renderTargetInfo:renderTargetInfo];
    expect(model.brushModel).to.equal(brushModel);
    expect(model.renderTargetInfo).to.equal(renderTargetInfo);
  });
});

SpecEnd
