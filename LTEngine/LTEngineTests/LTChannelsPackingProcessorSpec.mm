// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTChannelsPackingProcessor.h"

#import "LTTexture+Factory.h"

SpecBegin(LTChannelsPackingProcessor)

context(@"initialization", ^{
  it(@"should initialize with valid arguments", ^{
    LTTexture *input1 = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
    LTTexture *input2 = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];

    LTTexture *output = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];

    expect(^{
      LTChannelsPackingProcessor __unused *channelsPackingProcessor =
          [[LTChannelsPackingProcessor alloc] initWithInputs:@[input1, input2] output:output];
    }).notTo.raiseAny();
  });

  it(@"should raise with an empty inputs array", ^{
    LTTexture *output = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    expect(^{
      LTChannelsPackingProcessor __unused *channelsPackingProcessor =
          [[LTChannelsPackingProcessor alloc] initWithInputs:@[] output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise with an inputs array of size that is larger than 4", ^{
    LTTexture *input = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
    NSArray<LTTexture *> *inputs = @[input, input, input, input, input];
    LTTexture *output = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];

    expect(^{
      LTChannelsPackingProcessor __unused *channelsPackingProcessor =
          [[LTChannelsPackingProcessor alloc] initWithInputs:inputs output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when inputs array contains a multiple channels texture", ^{
    LTTexture *input1 = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    LTTexture *input2 = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];

    LTTexture *output = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];

    expect(^{
      LTChannelsPackingProcessor __unused *channelsPackingProcessor =
          [[LTChannelsPackingProcessor alloc] initWithInputs:@[input1, input2] output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when output is not an RGBA texture", ^{
    LTTexture *input1 = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
    LTTexture *input2 = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];

    LTTexture *output = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];

    expect(^{
      LTChannelsPackingProcessor __unused *channelsPackingProcessor =
          [[LTChannelsPackingProcessor alloc] initWithInputs:@[input1, input2] output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when output size is different than the input sizes", ^{
    LTTexture *input1 = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
    LTTexture *input2 = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];

    LTTexture *output = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(2)];

    expect(^{
      LTChannelsPackingProcessor __unused *channelsPackingProcessor =
          [[LTChannelsPackingProcessor alloc] initWithInputs:@[input1, input2] output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when output bit depth is different than the input bit depths", ^{
    LTTexture *input1 = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
    LTTexture *input2 = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];

    LTTexture *output = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                       pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                    allocateMemory:YES];

    expect(^{
      LTChannelsPackingProcessor __unused *channelsPackingProcessor =
          [[LTChannelsPackingProcessor alloc] initWithInputs:@[input1, input2] output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when input texture sizes are not equal", ^{
    LTTexture *input1 = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
    LTTexture *input2 = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(2)];

    LTTexture *output = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];

    expect(^{
      LTChannelsPackingProcessor __unused *channelsPackingProcessor =
          [[LTChannelsPackingProcessor alloc] initWithInputs:@[input1, input2] output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when input texture pixel formats are not equal", ^{
    LTTexture *input1 = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
    LTTexture *input2 = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                       pixelFormat:$(LTGLPixelFormatR16Float) allocateMemory:YES];

    LTTexture *output = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];

    expect(^{
      LTChannelsPackingProcessor __unused *channelsPackingProcessor =
          [[LTChannelsPackingProcessor alloc] initWithInputs:@[input1, input2] output:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"packing", ^{
  context(@"byte textures packing", ^{
    __block LTTexture *output;

    beforeEach(^{
      output = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(2)];
      [output clearWithColor:LTVector4::ones()];
    });

    afterEach(^{
      output = nil;
    });

    context(@"one texture packing", ^{
      it(@"should process output correctly", ^{
        LTTexture *input1 = [LTTexture textureWithImage:cv::Mat1b(2, 2, 64)];
        LTChannelsPackingProcessor *channelPackingProcessor =
            [[LTChannelsPackingProcessor alloc] initWithInputs:@[input1] output:output];
        [channelPackingProcessor process];

        cv::Mat4b expected (2, 2, cv::Vec4b(64, 0, 0, 0));
        expect($([output image])).to.equalMat($(expected));
      });
    });

    context(@"two textures packing", ^{
      it(@"should process output correctly", ^{
        LTTexture *input1 = [LTTexture textureWithImage:cv::Mat1b(2, 2, 64)];
        LTTexture *input2 = [LTTexture textureWithImage:cv::Mat1b(2, 2, 128)];
        LTChannelsPackingProcessor *channelPackingProcessor =
            [[LTChannelsPackingProcessor alloc] initWithInputs:@[input1, input2] output:output];
        [channelPackingProcessor process];

        cv::Mat4b expected (2, 2, cv::Vec4b(64, 128, 0, 0));
        expect($([output image])).to.equalMat($(expected));
      });
    });

    context(@"three textures packing", ^{
      it(@"should process output correctly", ^{
        LTTexture *input1 = [LTTexture textureWithImage:cv::Mat1b(2, 2, 64)];
        LTTexture *input2 = [LTTexture textureWithImage:cv::Mat1b(2, 2, 128)];
        LTTexture *input3 = [LTTexture textureWithImage:cv::Mat1b(2, 2, 192)];
        LTChannelsPackingProcessor *channelPackingProcessor =
            [[LTChannelsPackingProcessor alloc] initWithInputs:@[input1, input2, input3]
                                                        output:output];
        [channelPackingProcessor process];
        
        cv::Mat4b expected (2, 2, cv::Vec4b(64, 128, 192, 0));
        expect($([output image])).to.equalMat($(expected));
      });
    });

    context(@"four textures packing", ^{
      it(@"should process output correctly", ^{
        LTTexture *input1 = [LTTexture textureWithImage:cv::Mat1b(2, 2, 64)];
        LTTexture *input2 = [LTTexture textureWithImage:cv::Mat1b(2, 2, 128)];
        LTTexture *input3 = [LTTexture textureWithImage:cv::Mat1b(2, 2, 192)];
        LTTexture *input4 = [LTTexture textureWithImage:cv::Mat1b(2, 2, 255)];
        LTChannelsPackingProcessor *channelPackingProcessor =
            [[LTChannelsPackingProcessor alloc] initWithInputs:@[input1, input2, input3, input4]
                                                        output:output];
        [channelPackingProcessor process];

        cv::Mat4b expected (2, 2, cv::Vec4b(64, 128, 192, 255));
        expect($([output image])).to.equalMat($(expected));
      });
    });
  });
});

SpecEnd
