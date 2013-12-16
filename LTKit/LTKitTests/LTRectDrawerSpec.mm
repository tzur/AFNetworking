// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectDrawer.h"

#import "LTFbo.h"
#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTTestUtils.h"
#import "NSValue+GLKitExtensions.h"

SpecBegin(LTRectDrawer)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

static NSString * const kVertexSource =
    @"uniform highp mat4 modelview;"
    "uniform highp mat4 projection;"
    "uniform highp mat3 texture;"
    ""
    "attribute highp vec4 position;"
    "attribute highp vec3 texcoord;"
    ""
    "varying highp vec2 vTexcoord;"
    ""
    "void main() {"
    "  vec4 newpos = vec4(position.xy, 0.0, 1.0);"
    "  vTexcoord = (texture * vec3(texcoord.xy, 1.0)).xy;"
    "  gl_Position = projection * modelview * newpos;"
    "}";

static NSString * const kFragmentSource =
    @"uniform sampler2D sourceTexture;"
    ""
    "varying highp vec2 vTexcoord;"
    ""
    "void main() {"
    "  highp vec4 color = texture2D(sourceTexture, vTexcoord);"
    "  gl_FragColor = color;"
    "}";

static NSString * const kFragmentWithUniformSource =
    @"uniform sampler2D sourceTexture;"
    "uniform highp vec4 outputColor;"
    ""
    "varying highp vec2 vTexcoord;"
    ""
    "void main() {"
    "  sourceTexture;"
    "  gl_FragColor = outputColor;"
    "}";

__block LTTexture *texture;
__block cv::Mat image;

CGSize inputSize = CGSizeMake(16, 16);

beforeEach(^{
  short width = inputSize.width / 2;
  short height = inputSize.height / 2;
  image = cv::Mat(inputSize.height, inputSize.width, CV_8UC4);
  image(cv::Rect(0, 0, width, height)).setTo(cv::Vec4b(255, 0, 0, 255));
  image(cv::Rect(width, 0, width, height)).setTo(cv::Vec4b(0, 255, 0, 255));
  image(cv::Rect(0, height, width, height)).setTo(cv::Vec4b(0, 0, 255, 255));
  image(cv::Rect(width, height, width, height)).setTo(cv::Vec4b(255, 255, 0, 255));

  texture = [[LTGLTexture alloc] initWithSize:inputSize
                                    precision:LTTexturePrecisionByte
                                     channels:LTTextureChannelsRGBA allocateMemory:NO];
  [texture load:image];
  texture.magFilterInterpolation = LTTextureInterpolationNearest;
});

afterEach(^{
  texture = nil;
});

context(@"initialization", ^{
  it(@"should initialize with valid program", ^{
    LTProgram *program = [[LTProgram alloc] initWithVertexSource:kVertexSource
                                                  fragmentSource:kFragmentSource];

    expect(^{
      __unused LTRectDrawer *rectDrawer = [[LTRectDrawer alloc] initWithProgram:program
                                                                  sourceTexture:texture];
    }).toNot.raise(NSInternalInconsistencyException);
  });

  pending(@"should not initialize with invalid program");
});

context(@"drawing", ^{
  __block LTProgram *program;
  __block LTRectDrawer *rectDrawer;
  __block LTTexture *output;
  __block LTFbo *fbo;

  beforeEach(^{
    program = [[LTProgram alloc] initWithVertexSource:kVertexSource
                                       fragmentSource:kFragmentSource];
    rectDrawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:texture];

    output = [[LTGLTexture alloc] initWithSize:inputSize
                                     precision:LTTexturePrecisionByte
                                      channels:LTTextureChannelsRGBA allocateMemory:YES];

    fbo = [[LTFbo alloc] initWithTexture:output];
  });

  afterEach(^{
    fbo = nil;
    output = nil;
    rectDrawer = nil;
    program = nil;
  });

  context(@"framebuffer", ^{
    it(@"should draw to to target texture of the same size", ^{
      [rectDrawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height) inFrameBuffer:fbo
                  fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];

      expect(LTCompareMat(image, output.image)).to.beTruthy();
    });

    it(@"should draw subrect of input to entire output", ^{
      [rectDrawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height) inFrameBuffer:fbo
                  fromRect:CGRectMake(inputSize.width / 2, 0,
                                      inputSize.width / 2, inputSize.height / 2)];

      cv::Mat expected(inputSize.height, inputSize.width, CV_8UC4);
      expected.setTo(image.at<cv::Vec4b>(0, inputSize.width / 2));
      expect(LTCompareMat(output.image, expected)).to.beTruthy();
    });

    it(@"should draw all input to subrect of output", ^{
      [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
      [rectDrawer drawRect:CGRectMake(inputSize.width / 2, 0,
                                      inputSize.width / 2, inputSize.height / 2)
             inFrameBuffer:fbo
                  fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];

      // Actual image should be a resized version at (0, w/2). Prepare the resized version and put
      // it where it belongs.
      cv::Mat resized;
      cv::resize(image, resized, cv::Size(), 0.5, 0.5, cv::INTER_NEAREST);

      cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
      expected.setTo(cv::Vec4b(0, 0, 0, 255));

      cv::Rect roi(inputSize.width / 2, 0, inputSize.width / 2, inputSize.height / 2);
      resized.copyTo(expected(roi));

      expect(LTCompareMat(output.image, expected)).to.beTruthy();
    });

    it(@"should draw subrect of input to subrect of output", ^{
      [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
      [rectDrawer drawRect:CGRectMake(inputSize.width / 2, 0,
                                      inputSize.width / 2, inputSize.height / 2)
             inFrameBuffer:fbo
                  fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];
    });
  });

  context(@"anonymous target", ^{
    it(@"should draw to rect", ^{
      [fbo bindAndExecute:^{
        [rectDrawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height)
       inFrameBufferWithSize:fbo.size
                    fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];

        expect(LTCompareMat(image, output.image)).to.beTruthy();
      }];
    });
  });
});

context(@"custom uniforms", ^{
  __block LTProgram *program;
  __block LTRectDrawer *rectDrawer;
  __block LTTexture *output;
  __block LTFbo *fbo;

  beforeEach(^{
    program = [[LTProgram alloc] initWithVertexSource:kVertexSource
                                       fragmentSource:kFragmentWithUniformSource];
    rectDrawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:texture];

    output = [[LTGLTexture alloc] initWithSize:inputSize
                                     precision:LTTexturePrecisionByte
                                      channels:LTTextureChannelsRGBA allocateMemory:YES];

    fbo = [[LTFbo alloc] initWithTexture:output];
  });

  afterEach(^{
    fbo = nil;
    output = nil;
    rectDrawer = nil;
    program = nil;
  });

  fit(@"should draw given color to target", ^{
    GLKVector4 outputColor = GLKVector4Make(1, 0, 0, 1);
    rectDrawer[@"outputColor"] = [NSValue valueWithGLKVector4:outputColor];

    [rectDrawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height) inFrameBuffer:fbo
                fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];

    cv::Mat expected(inputSize.height, inputSize.width, CV_8UC4);
    expected.setTo(LTGLKVector4ToVec4b(outputColor));

    expect(LTCompareMat(expected, output.image)).to.beTruthy();
  });
});

SpecEnd
