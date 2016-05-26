// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTReshapeProcessor.h"

#import "LTDisplacementMapDrawer.h"
#import "LTMeshProcessor.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTTexture+Factory.h"

@interface LTReshapeProcessor ()

- (instancetype)initWithDisplacementMapDrawer:(LTDisplacementMapDrawer *)displacementMapDrawer
                                meshProcessor:(LTMeshProcessor *)meshProcessor;

@end

SpecBegin(LTReshapeProcessor)

context(@"initialization", ^{
  __block LTTexture *inputTexture;
  __block LTTexture *outputTexture;
  __block cv::Mat expectedDisplacementMap;
  __block LTTexture *mask;

  beforeEach(^{
    using half_float::half;

    inputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(8)];
    outputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(8)];
    expectedDisplacementMap = cv::Mat4hf(2, 2, cv::Vec4hf(half(0), half(0), half(0), half(0)));
    mask = OCMClassMock([LTTexture class]);
  });

  afterEach(^{
    inputTexture = nil;
    outputTexture = nil;
    mask = nil;
  });

  it(@"should initialize with input and output correctly", ^{
    LTReshapeProcessor *processor = [[LTReshapeProcessor alloc] initWithInput:inputTexture
                                                                       output:outputTexture];

    expect(processor.inputTexture).to.beIdenticalTo(inputTexture);
    expect(processor.outputTexture).to.beIdenticalTo(outputTexture);
    expect(processor.inputSize).to.equal(inputTexture.size);
    expect(processor.outputSize).to.equal(outputTexture.size);
    expect($(processor.meshDisplacementTexture.image)).to.equalMat($(expectedDisplacementMap));
  });

  it(@"should initialize with input, mask and output correctly", ^{
    LTReshapeProcessor *processor = [[LTReshapeProcessor alloc] initWithInput:inputTexture
                                                                         mask:mask
                                                                       output:outputTexture];

    expect(processor.inputTexture).to.beIdenticalTo(inputTexture);
    expect(processor.outputTexture).to.beIdenticalTo(outputTexture);
    expect(processor.inputSize).to.equal(inputTexture.size);
    expect(processor.outputSize).to.equal(outputTexture.size);
    expect($(processor.meshDisplacementTexture.image)).to.equalMat($(expectedDisplacementMap));
  });

  it(@"should initialize with input, nil mask and output correctly", ^{
    __block LTReshapeProcessor *processor =
        [[LTReshapeProcessor alloc] initWithInput:inputTexture mask:nil output:outputTexture];

    expect(processor.inputTexture).to.beIdenticalTo(inputTexture);
    expect(processor.outputTexture).to.beIdenticalTo(outputTexture);
    expect(processor.inputSize).to.equal(inputTexture.size);
    expect(processor.outputSize).to.equal(outputTexture.size);
    expect($(processor.meshDisplacementTexture.image)).to.equalMat($(expectedDisplacementMap));
  });

  it(@"should initialize with fragment soruce, input, mask and output correctly", ^{
    LTReshapeProcessor *processor =
        [[LTReshapeProcessor alloc] initWithFragmentSource:[PassthroughFsh source]
                                                     input:inputTexture mask:mask
                                                    output:outputTexture];

    expect(processor.inputTexture).to.beIdenticalTo(inputTexture);
    expect(processor.outputTexture).to.beIdenticalTo(outputTexture);
    expect(processor.inputSize).to.equal(inputTexture.size);
    expect(processor.outputSize).to.equal(outputTexture.size);
    expect($(processor.meshDisplacementTexture.image)).to.equalMat($(expectedDisplacementMap));
  });

  it(@"should initialize with fragment soruce, input, nil mask and output correctly", ^{
    LTReshapeProcessor *processor =
        [[LTReshapeProcessor alloc] initWithFragmentSource:[PassthroughFsh source]
                                                     input:inputTexture mask:mask
                                                    output:outputTexture];

    expect(processor.inputTexture).to.beIdenticalTo(inputTexture);
    expect(processor.outputTexture).to.beIdenticalTo(outputTexture);
    expect(processor.inputSize).to.equal(inputTexture.size);
    expect(processor.outputSize).to.equal(outputTexture.size);
    expect($(processor.meshDisplacementTexture.image)).to.equalMat($(expectedDisplacementMap));
  });

});

context(@"processing", ^{
  __block LTTexture *displacementMap;
  __block LTDisplacementMapDrawer *displacemetnMapDrawer;
  __block LTMeshProcessor *meshProcessor;
  __block LTReshapeProcessor *processor;

  beforeEach(^{
    displacementMap = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                     pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                  allocateMemory:NO];

    displacemetnMapDrawer = OCMClassMock([LTDisplacementMapDrawer class]);
    OCMStub([displacemetnMapDrawer displacementMap]).andReturn(displacementMap);

    meshProcessor = OCMClassMock([LTMeshProcessor class]);
    OCMStub([meshProcessor meshDisplacementTexture]).andReturn(displacementMap);

    processor = [[LTReshapeProcessor alloc] initWithDisplacementMapDrawer:displacemetnMapDrawer
                                                            meshProcessor:meshProcessor];
  });

  afterEach(^{
    displacementMap = nil;
    displacemetnMapDrawer = nil;
    meshProcessor = nil;
    processor = nil;
  });

  context(@"displacement map drawer", ^{
    __block CGPoint center;
    __block LTReshapeBrushParams params;

    beforeEach(^{
      center = CGPointMake(0.5, 0.5);
      params = {.diameter = 1.0, .density = 2.0, .pressure = 3.0};
    });

    it(@"should reshape", ^{
      CGPoint direction = CGPointMake(1, 1);

      [processor reshapeWithCenter:center direction:direction brushParams:params];
      OCMVerify([displacemetnMapDrawer reshapeWithCenter:center direction:direction
                                             brushParams:params]);
    });

    it(@"should resize", ^{
      CGFloat scale = 1.5;

      [processor resizeWithCenter:center scale:scale brushParams:params];
      OCMVerify([displacemetnMapDrawer resizeWithCenter:center scale:scale brushParams:params]);
    });

    it(@"should reshape", ^{
      [processor unwarpWithCenter:center brushParams:params];
      OCMVerify([displacemetnMapDrawer unwarpWithCenter:center brushParams:params]);
    });
  });

  context(@"mesh processor", ^{
    it(@"should reset mesh using mesh processor", ^{
      [processor resetMesh];
      OCMVerify([displacemetnMapDrawer resetDisplacementMap]);
    });

    it(@"should process using mesh processor", ^{
      [processor process];
      OCMVerify([meshProcessor process]);
    });

    it(@"should process using mesh processor", ^{
      [processor process];
      OCMVerify([meshProcessor process]);
    });

    it(@"should processToFramebufferWithSize using mesh processor", ^{
      CGRect rect = CGRectFromSize(CGSizeMakeUniform(1));

      [processor processInRect:rect];
      OCMVerify([meshProcessor processInRect:rect]);
    });

    it(@"should processToFramebufferWithSize using mesh processor", ^{
      CGSize size = CGSizeMakeUniform(1);
      CGRect rect = CGRectFromSize(size);

      [processor processToFramebufferWithSize:size outputRect:rect];
      OCMVerify([meshProcessor processToFramebufferWithSize:size outputRect:rect]);
    });
  });
});

SpecEnd
