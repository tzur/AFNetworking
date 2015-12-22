// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTReshapeProcessor.h"

#import <LTKit/LTRandom.h>

#import "LTOpenCVExtensions.h"
#import "LTShaderStorage+passthroughFsh.h"
#import "LTTexture+Factory.h"

SpecBegin(LTReshapeProcessor)

static NSString * const kFragmentRedFilter =
    @"uniform sampler2D sourceTexture;"
    ""
    "varying highp vec2 vTexcoord;"
    ""
    "void main() {"
    "  gl_FragColor = vec4(0.0, texture2D(sourceTexture, vTexcoord).gb, 1.0);"
    "}";

__block LTTexture *input;
__block LTTexture *mask;
__block LTTexture *output;
__block LTReshapeProcessor *processor;

static const CGSize kInputSize = CGSizeMake(64, 128);
static const CGSize kOutputSize = CGSizeMake(64, 128);

beforeEach(^{
  input = [LTTexture byteRGBATextureWithSize:kInputSize];
  output = [LTTexture byteRGBATextureWithSize:kOutputSize];
  mask = [LTTexture textureWithSize:kInputSize pixelFormat:$(LTGLPixelFormatR16Float)
                     allocateMemory:YES];
  [mask clearWithColor:LTVector4::ones()];
});

afterEach(^{
  processor = nil;
  output = nil;
  input = nil;
  mask = nil;
});

context(@"initialization", ^{
  it(@"should initialize with input and output", ^{
    expect(^{
      processor = [[LTReshapeProcessor alloc] initWithInput:input output:output];
    }).notTo.raiseAny();
    expect(processor.inputSize).to.equal(input.size);
    expect(processor.outputSize).to.equal(output.size);
    expect(processor.inputTexture).to.beIdenticalTo(input);
    expect(processor.outputTexture).to.beIdenticalTo(output);
  });
  
  it(@"should initialize with input, mask and output", ^{
    expect(^{
      processor = [[LTReshapeProcessor alloc] initWithInput:input mask:mask output:output];
    }).notTo.raiseAny();
  });
  
  it(@"should initialize with fragment shader, input, mask and output", ^{
    expect(^{
      processor = [[LTReshapeProcessor alloc] initWithFragmentSource:[PassthroughFsh source]
                                                               input:input mask:mask output:output];
    }).notTo.raiseAny();
  });
  
  it(@"should initialize with fragment shader, input, output and no mask", ^{
    expect(^{
      processor = [[LTReshapeProcessor alloc] initWithFragmentSource:[PassthroughFsh source]
                                                               input:input mask:nil output:output];
    }).notTo.raiseAny();
  });
  
  it(@"should raise when initializing without fragment source", ^{
    expect(^{
      processor = [[LTReshapeProcessor alloc] initWithFragmentSource:nil
                                                               input:input mask:mask output:output];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should raise when initializing without input texture", ^{
    expect(^{
      processor = [[LTReshapeProcessor alloc] initWithFragmentSource:[PassthroughFsh source]
                                                               input:nil mask:mask output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when initializing without output texture", ^{
    expect(^{
      processor = [[LTReshapeProcessor alloc] initWithFragmentSource:[PassthroughFsh source]
                                                               input:input mask:mask output:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  using half_float::half;
  
  __block CGSize meshSize;
  __block CGSize cellSize;
  __block CGSize cellRadius;
  __block cv::Mat4b expected;

  beforeEach(^{
    processor = [[LTReshapeProcessor alloc] initWithInput:input mask:mask output:output];
    
    meshSize = processor.meshDisplacementTexture.size - CGSizeMakeUniform(1);
    cellSize = processor.inputSize / meshSize;
    cellRadius = cellSize / 2;

    input.magFilterInterpolation = LTTextureInterpolationNearest;
    input.minFilterInterpolation = LTTextureInterpolationNearest;
    [input mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      LTRandom *random = [[LTRandom alloc] initWithSeed:0];
      cv::Mat4b mat = *mapped;
      for (int i = 0; i < meshSize.height; ++i) {
        for (int j = 0; j < meshSize.width; ++j) {
          cv::Rect rect(j * cellSize.width, i * cellSize.height, cellSize.width, cellSize.height);
          cv::Vec4b color([random randomUnsignedIntegerBelow:256],
                          [random randomUnsignedIntegerBelow:256],
                          [random randomUnsignedIntegerBelow:256], 255);
          mat(rect).setTo(color);
        }
      }
    }];
    
    expected.create(kOutputSize.height, kOutputSize.width);
    expected.setTo(cv::Vec4b(0, 0, 0, 255));
  });
  
  context(@"passthrough fragment shader", ^{
    it(@"should process with default displacement", ^{
      [processor process];
      expect($(output.image)).to.equalMat($(input.image));
    });
    
    it(@"should process with custom displacement", ^{
      [processor.meshDisplacementTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec4hf(half(0)));
        mapped->col(1).setTo(cv::Vec4hf(half(-0.5 / meshSize.width), half(0), half(0), half(0)));
        mapped->col(mapped->cols - 2).setTo(cv::Vec4hf(half(0.5 / meshSize.width), half(0),
                                                       half(0), half(0)));
      }];
      [processor process];
      
      expected = input.image;
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
      .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
      .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      expect($(output.image)).to.equalMat($(expected));
    });
  });
  
  context(@"custom fragment shader", ^{
    beforeEach(^{
      processor = [[LTReshapeProcessor alloc] initWithFragmentSource:kFragmentRedFilter
                                                               input:input mask:mask output:output];
    });
    
    it(@"should process with default displacement", ^{
      [processor process];
      expected = input.image;
      std::transform(expected.begin(), expected.end(), expected.begin(),
                     [](const cv::Vec4b &value) {
        return cv::Vec4b(0, value[1], value[2], value[3]);
      });
      expect($(output.image)).to.equalMat($(expected));
    });
    
    it(@"should process with custom displacement", ^{
      [processor.meshDisplacementTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->setTo(cv::Vec4hf(half(0)));
        mapped->col(1).setTo(cv::Vec4hf(half(-0.5 / meshSize.width), half(0), half(0), half(0)));
        mapped->col(mapped->cols - 2).setTo(cv::Vec4hf(half(0.5 / meshSize.width), half(0),
                                                       half(0), half(0)));
      }];
      [processor process];
      
      expected = input.image;
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      expected.colRange(cellSize.width, cellSize.width + cellRadius.width)
          .copyTo(expected.colRange(cellRadius.width, cellSize.width));
      cv::flip(expected, expected, 1);
      std::transform(expected.begin(), expected.end(), expected.begin(),
                     [](const cv::Vec4b &value) {
        return cv::Vec4b(0, value[1], value[2], value[3]);
      });
      expect($(output.image)).to.equalMat($(expected));
    });
  });
  
  context(@"transformations", ^{
    __block LTReshapeBrushParams params;
    
    beforeEach(^{
      processor = [[LTReshapeProcessor alloc] initWithInput:input mask:mask output:output];
      [processor process];
      params = {.diameter = 1.0, .density = 1.0, .pressure = 1.0};
    });
    
    context(@"without mask", ^{
      beforeEach(^{
        processor = [[LTReshapeProcessor alloc] initWithInput:input output:output];
        [processor process];
      });
      
      it(@"should reset", ^{
        cv::Mat4hf expected = processor.meshDisplacementTexture.image;
        
        [processor.meshDisplacementTexture clearWithColor:LTVector4::ones()];
        expected.setTo(cv::Vec4hf(half(1), half(1), half(1), half(1)));
        expect($(processor.meshDisplacementTexture.image)).to.equalMat($(expected));
        
        [processor resetMesh];
        expected.setTo(cv::Vec4hf(half(0), half(0), half(0), half(0)));
        expect($(processor.meshDisplacementTexture.image)).to.equalMat($(expected));
      });
      
      it(@"should reshape", ^{
        [processor reshapeWithCenter:CGPointMake(0.5, 0.5) direction:CGPointMake(0.25, 0.25)
                         brushParams:params];
        [processor process];
        
        expected = LTLoadMat([self class], @"ReshapeProcessorReshapeWithoutMask.png");
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should resize", ^{
        [processor resizeWithCenter:CGPointMake(0.5, 0.5) scale:1.5 brushParams:params];
        [processor process];
        
        expected = LTLoadMat([self class], @"ReshapeProcessorResizeWithoutMask.png");
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should unwarp", ^{
        [processor resizeWithCenter:CGPointMake(0.5, 0.5) scale:1.5 brushParams:params];
        [processor unwarpWithCenter:CGPointMake(0.25, 0.25) brushParams:params];
        [processor process];
        
        expected = LTLoadMat([self class], @"ReshapeProcessorUnwarpWithoutMask.png");
        expect($(output.image)).to.beCloseToMat($(expected));
      });
    });
    
    context(@"with mask", ^{
      beforeEach(^{
        [mask mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
          cv::Mat1hf mat = mapped->rowRange(mapped->rows / 2, mapped->rows - 1);
          std::transform(mat.begin(), mat.end(), mat.begin(), [](const half &) {
            return half(0);
          });
        }];
      });
      
      it(@"should reset ignoring mask", ^{
        cv::Mat4hf expected = processor.meshDisplacementTexture.image;
        
        [processor.meshDisplacementTexture clearWithColor:LTVector4::ones()];
        expected.setTo(cv::Vec4hf(half(1), half(1), half(1), half(1)));
        expect($(processor.meshDisplacementTexture.image)).to.equalMat($(expected));
        
        [processor resetMesh];
        expected.setTo(cv::Vec4hf(half(0), half(0), half(0), half(0)));
        expect($(processor.meshDisplacementTexture.image)).to.equalMat($(expected));
      });
      
      it(@"should reshape with respect to mask", ^{
        [processor reshapeWithCenter:CGPointMake(0.5, 0.5) direction:CGPointMake(0.25, 0.25)
                         brushParams:params];
        [processor process];
        
        expected = LTLoadMat([self class], @"ReshapeProcessorReshapeWithMask.png");
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should resize with respect to mask", ^{
        [processor resizeWithCenter:CGPointMake(0.5, 0.5) scale:1.5 brushParams:params];
        [processor process];
        
        expected = LTLoadMat([self class], @"ReshapeProcessorResizeWithMask.png");
        expect($(output.image)).to.beCloseToMat($(expected));
      });
      
      it(@"should unwarp ignoring mask", ^{
        cv::Mat1hf previousMask = mask.image;
        [mask clearWithColor:LTVector4::ones()];
        [processor resizeWithCenter:CGPointMake(0.5, 0.5) scale:1.5 brushParams:params];
        [mask load:previousMask];
        [processor unwarpWithCenter:CGPointMake(0.75, 0.75) brushParams:params];
        [processor process];
        
        expected = LTLoadMat([self class], @"ReshapeProcessorUnwarpWithMask.png");
        expect($(output.image)).to.beCloseToMat($(expected));
      });
    });
  });
});

SpecEnd
