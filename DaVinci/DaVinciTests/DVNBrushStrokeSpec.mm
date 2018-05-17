// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushStroke.h"

#import <LTEngine/LTControlPointModel.h>
#import <LTEngine/LTTexture.h>

#import "DVNBrushModel.h"
#import "DVNBrushRenderModel.h"
#import "DVNBrushRenderTargetInformation.h"

SpecBegin(DVNBrushStrokeSpecification)

context(@"factory methods", ^{
  __block LTControlPointModel *controlPointModel;
  __block DVNBrushRenderModel *brushRenderModel;

  beforeEach(^{
    controlPointModel = OCMClassMock([LTControlPointModel class]);
    brushRenderModel = OCMClassMock([DVNBrushRenderModel class]);
  });

  it(@"should return a new instance", ^{
    lt::Interval<CGFloat> interval({7, 8});
    DVNBrushStrokeSpecification *stroke =
        [DVNBrushStrokeSpecification specificationWithControlPointModel:controlPointModel
                                                       brushRenderModel:brushRenderModel
                                                            endInterval:interval];
    expect(stroke.controlPointModel).to.equal(controlPointModel);
    expect(stroke.brushRenderModel).to.equal(brushRenderModel);
    expect(stroke.endInterval == interval).to.beTruthy();
  });

  context(@"invalid creation attempts", ^{
    it(@"should raise when attempting to create instance with interval with negative infimum", ^{
      expect(^{
          DVNBrushStrokeSpecification __unused *stroke =
            [DVNBrushStrokeSpecification
             specificationWithControlPointModel:controlPointModel brushRenderModel:brushRenderModel
             endInterval:lt::Interval<CGFloat>({-7, 8})];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

SpecEnd

SpecBegin(DVNBrushStrokeData)

context(@"factory methods", ^{
  __block DVNBrushStrokeSpecification *brushStrokeSpecification;
  __block NSDictionary<NSString *, LTTexture *> *textureMapping;

  beforeEach(^{
    DVNBrushModel *brushModel = OCMClassMock([DVNBrushModel class]);
    OCMStub([brushModel isValidTextureMapping:@{}]).andReturn(YES);
    DVNBrushRenderModel *model =
        [DVNBrushRenderModel
         instanceWithBrushModel:brushModel
         renderTargetInfo:OCMClassMock([DVNBrushRenderTargetInformation class]) conversionFactor:1];
    brushStrokeSpecification =
        [DVNBrushStrokeSpecification
         specificationWithControlPointModel:OCMClassMock([LTControlPointModel class])
         brushRenderModel:model
         endInterval:lt::Interval<CGFloat>(7)];
    textureMapping = @{};
  });

  it(@"should return a new instance", ^{
    lt::Interval<CGFloat> interval({7, 8});
    DVNBrushStrokeData *data = [DVNBrushStrokeData dataWithSpecification:brushStrokeSpecification
                                                          textureMapping:textureMapping];
    expect(data.specification).to.equal(brushStrokeSpecification);
    expect(data.textureMapping).to.equal(textureMapping);
  });

  context(@"invalid creation attempts", ^{
    it(@"should raise when attempting to create instance with interval with invalid mapping", ^{
      expect(^{
        DVNBrushStrokeData __unused *data =
            [DVNBrushStrokeData dataWithSpecification:brushStrokeSpecification
                                       textureMapping:@{@"foo": OCMClassMock([LTTexture class])}];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

SpecEnd
