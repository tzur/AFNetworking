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

static NSString * const kMissingVertexSource =
    @"uniform highp mat4 modelview;"
    "uniform highp mat4 projection;"
    ""
    "attribute highp vec4 position;"
    "attribute highp vec3 texcoord;"
    ""
    "varying highp vec2 vTexcoord;"
    ""
    "void main() {"
    "  vec4 newpos = vec4(position.xy, 0.0, 1.0);"
    "  vTexcoord = texcoord.xy;"
    "  gl_Position = projection * modelview * newpos;"
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

  it(@"should not initialize with program with missing uniforms", ^{
    LTProgram *program = [[LTProgram alloc] initWithVertexSource:kMissingVertexSource
                                                  fragmentSource:kFragmentSource];

    expect(^{
      __unused LTRectDrawer *rectDrawer = [[LTRectDrawer alloc] initWithProgram:program
                                                                  sourceTexture:texture];
    }).to.raise(NSInternalInconsistencyException);
  });
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
      [rectDrawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height) inFramebuffer:fbo
                  fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];

      expect(LTCompareMat(output.image, image)).to.beTruthy();
    });

    it(@"should draw subrect of input to entire output", ^{
      [rectDrawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height) inFramebuffer:fbo
                  fromRect:CGRectMake(inputSize.width / 2, 0,
                                      inputSize.width / 2, inputSize.height / 2)];

      cv::Mat expected(inputSize.height, inputSize.width, CV_8UC4);
      expected.setTo(image.at<cv::Vec4b>(0, inputSize.width / 2));
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });

    it(@"should draw all input to subrect of output", ^{
      [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
      [rectDrawer drawRect:CGRectMake(inputSize.width / 2, 0,
                                      inputSize.width / 2, inputSize.height / 2)
             inFramebuffer:fbo
                  fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];

      // Actual image should be a resized version at (0, w/2). Prepare the resized version and put
      // it where it belongs.
      cv::Mat resized;
      cv::resize(image, resized, cv::Size(), 0.5, 0.5, cv::INTER_NEAREST);

      cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
      expected.setTo(cv::Vec4b(0, 0, 0, 255));

      cv::Rect roi(inputSize.width / 2, 0, inputSize.width / 2, inputSize.height / 2);
      resized.copyTo(expected(roi));

      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });

    it(@"should draw subrect of input to subrect of output", ^{
      [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
      [rectDrawer drawRect:CGRectMake(inputSize.width / 2, 0,
                                      inputSize.width / 2, inputSize.height / 2)
             inFramebuffer:fbo
                  fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];
      // nice test!
    });
  });

  context(@"screen framebuffer", ^{
    it(@"should draw to to target texture of the same size", ^{
      [fbo bindAndExecute:^{
        [rectDrawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height)
 inScreenFramebufferWithSize:fbo.size
                    fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];
      }];
      
      cv::Mat expected(image.rows, image.cols, CV_8UC4);
      cv::flip(image, expected, 0);
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
    
    it(@"should draw subrect of input to entire output", ^{
      const CGRect subrect = CGRectMake(2 * inputSize.width / 16, 3 * inputSize.height / 16,
                                        inputSize.width / 2, inputSize.height / 2);
      [fbo bindAndExecute:^{
        [rectDrawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height)
 inScreenFramebufferWithSize:fbo.size
                    fromRect:subrect];
      }];

      // Actual image should be a resized version of the subimage at the given range, flipped across
      // the x-axis.
      cv::Mat expected(inputSize.height, inputSize.width, CV_8UC4);
      cv::Mat subimage = image(cv::Range(subrect.origin.y, subrect.origin.y + subrect.size.height),
                               cv::Range(subrect.origin.x, subrect.origin.x + subrect.size.width));
      cv::resize(subimage, expected,
                 cv::Size(expected.cols, expected.rows), 0, 0, cv::INTER_NEAREST);
      cv::flip(expected, expected, 0);
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
    
    it(@"should draw all input to subrect of output", ^{
      const CGRect subrect = CGRectMake(2 * inputSize.width / 16, 3 * inputSize.height / 16,
                                        inputSize.width / 2, inputSize.height / 2);
      [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
      [fbo bindAndExecute:^{
        [rectDrawer drawRect:subrect
 inScreenFramebufferWithSize:fbo.size
                    fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];
      }];
      
      // Actual image should be a resized version positioned at the given subrect.
      cv::Mat resized;
      cv::resize(image, resized, cv::Size(), 0.5, 0.5, cv::INTER_NEAREST);
      cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
      expected.setTo(cv::Vec4b(0, 0, 0, 255));
      resized.copyTo(expected(cv::Range(subrect.origin.y, subrect.origin.y + subrect.size.height),
                              cv::Range(subrect.origin.x, subrect.origin.x + subrect.size.width)));
      cv::flip(expected, expected, 0);
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
    
    it(@"should draw subrect of input to subrect of output", ^{
      const CGRect inRect = CGRectMake(6 * inputSize.width / 16, 7 * inputSize.height / 16,
                                        inputSize.width / 4, inputSize.height / 4);
      const CGRect outRect = CGRectMake(2 * inputSize.width / 16, 3 * inputSize.height / 16,
                                        inputSize.width / 2, inputSize.height / 2);
      [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
      [fbo bindAndExecute:^{
        [rectDrawer drawRect:outRect inScreenFramebufferWithSize:fbo.size fromRect:inRect];
      }];
      
      // Actual image should be a resized version of the subimage at inputSubrect positioned at the
      // given outputSubrect.
      cv::Mat resized;
      cv::Mat subimage = image(cv::Range(inRect.origin.y, inRect.origin.y + inRect.size.height),
                               cv::Range(inRect.origin.x, inRect.origin.x + inRect.size.width));
      cv::resize(subimage, resized,
                 cv::Size(outRect.size.width, outRect.size.height), 0, 0, cv::INTER_NEAREST);
      
      cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
      expected.setTo(cv::Vec4b(0, 0, 0, 255));
      resized.copyTo(expected(cv::Range(outRect.origin.y, outRect.origin.y + outRect.size.height),
                              cv::Range(outRect.origin.x, outRect.origin.x + outRect.size.width)));
      cv::flip(expected, expected, 0);
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
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

  it(@"should draw given color to target", ^{
    GLKVector4 outputColor = GLKVector4Make(1, 0, 0, 1);
    rectDrawer[@"outputColor"] = [NSValue valueWithGLKVector4:outputColor];

    [rectDrawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height) inFramebuffer:fbo
                fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];

    cv::Mat expected(inputSize.height, inputSize.width, CV_8UC4);
    expected.setTo(LTGLKVector4ToVec4b(outputColor));

    expect(LTCompareMat(expected, output.image)).to.beTruthy();
  });
});

SpecEnd
