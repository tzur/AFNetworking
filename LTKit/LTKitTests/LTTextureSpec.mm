// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLTexture.h"

#import "LTGLException.h"
#import "LTGPUResourceExamples.h"
#import "LTTestUtils.h"

// LTTexture spec is tested by the concrete class LTGLTexture.

// TODO: (yaron) refactor LTTexture to test the abstract functionality in a different spec. This
// is probably possible only by refactoring the LTTexture abstract class to the strategy pattern:
// http://stackoverflow.com/questions/243274/best-practice-with-unit-testing-abstract-classes

SpecBegin(LTTexture)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

sharedExamplesFor(@"having default property values", ^(NSDictionary *data) {
  it(@"should have default property values", ^{
    LTTexture *texture = data[@"texture"];
    
    expect(texture.usingAlphaChannel).to.equal(NO);
    expect(texture.usingHighPrecisionByte).to.equal(NO);
    expect(texture.wrap).to.equal(LTTextureWrapClamp);
    expect(texture.minFilterInterpolation).to.equal(LTTextureInterpolationLinear);
    expect(texture.magFilterInterpolation).to.equal(LTTextureInterpolationLinear);
  });
});

context(@"init without an image", ^{
  it(@"should create an unallocated texture with size", ^{
    CGSize size = CGSizeMake(42, 42);
    LTTexturePrecision precision = LTTexturePrecisionByte;
    LTTextureChannels channels = LTTextureChannelsRGBA;

    LTTexture *texture = [[LTGLTexture alloc] initWithSize:size precision:precision
                                                  channels:channels allocateMemory:NO];

    expect(texture.size).to.equal(size);
    expect(texture.precision).to.equal(precision);
    expect(texture.channels).to.equal(channels);
  });

  itShouldBehaveLike(@"having default property values", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                                 precision:LTTexturePrecisionByte
                                                  channels:LTTextureChannelsRGBA
                                            allocateMemory:NO];
    return @{@"texture": texture};
  });
});

context(@"init with an image", ^{
  it(@"should load RGBA image", ^{
    CGSize size = CGSizeMake(42, 67);
    cv::Mat image(size.height, size.width, CV_8UC4);

    LTTexture *texture = [[LTGLTexture alloc] initWithImage:image];

    expect(texture.size).to.equal(size);
    expect(texture.precision).to.equal(LTTexturePrecisionByte);
    expect(texture.channels).to.equal(LTTextureChannelsRGBA);
  });

  it(@"should load half-float RGBA image", ^{
    CGSize size = CGSizeMake(42, 67);
    cv::Mat image(size.height, size.width, CV_16UC4);

    LTTexture *texture = [[LTGLTexture alloc] initWithImage:image];

    expect(texture.size).to.equal(size);
    expect(texture.precision).to.equal(LTTexturePrecisionHalfFloat);
    expect(texture.channels).to.equal(LTTextureChannelsRGBA);
  });

  it(@"should not load invalid image depth", ^{
    CGSize size = CGSizeMake(42, 67);
    cv::Mat image(size.height, size.width, CV_64FC4);

    expect(^{
      __unused LTTexture *texture = [[LTGLTexture alloc] initWithImage:image];
    }).to.raise(kLTTextureUnsupportedFormatException);
  });

  it(@"should not load invalid image channel count", ^{
    CGSize size = CGSizeMake(42, 67);
    cv::Mat image(size.height, size.width, CV_32FC3);

    expect(^{
      __unused LTTexture *texture = [[LTGLTexture alloc] initWithImage:image];
    }).to.raise(kLTTextureUnsupportedFormatException);
  });
});

context(@"properties", ^{
  it(@"will not set wrap to repeat on NPOT texture", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 3)
                                                 precision:LTTexturePrecisionByte
                                                  channels:LTTextureChannelsRGBA allocateMemory:NO];
    texture.wrap = LTTextureWrapRepeat;

    expect(texture.wrap).toNot.equal(LTTextureWrapRepeat);
  });

  it(@"will set the warp to repeat on POT texture", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(2, 2)
                                                 precision:LTTexturePrecisionByte
                                                  channels:LTTextureChannelsRGBA allocateMemory:NO];
    texture.wrap = LTTextureWrapRepeat;

    expect(texture.wrap).to.equal(LTTextureWrapRepeat);
  });

  it(@"will set min and mag filters", ^{
    LTTexture *texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(2, 2)
                                                 precision:LTTexturePrecisionByte
                                                  channels:LTTextureChannelsRGBA allocateMemory:NO];

    texture.minFilterInterpolation = LTTextureInterpolationNearest;
    texture.magFilterInterpolation = LTTextureInterpolationNearest;

    expect(texture.minFilterInterpolation).to.equal(LTTextureInterpolationNearest);
    expect(texture.magFilterInterpolation).to.equal(LTTextureInterpolationNearest);
  });
});

context(@"binding and execution", ^{
  __block LTTexture *texture;

  beforeEach(^{
    texture = [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1) precision:LTTexturePrecisionByte
                                       channels:LTTextureChannelsRGBA allocateMemory:NO];
  });

  afterEach(^{
    texture = nil;
  });

  context(@"binding", ^{
    itShouldBehaveLike(kLTResourceExamples, ^{
      return @{kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:texture],
               kLTResourceExamplesOpenGLParameterName: @GL_TEXTURE_BINDING_2D};
    });
    
    it(@"should bind and unbind from the same texture unit", ^{
      glActiveTexture(GL_TEXTURE0);
      [texture bind];
      glActiveTexture(GL_TEXTURE1);
      [texture unbind];
      
      glActiveTexture(GL_TEXTURE0);
      GLint currentTexture;
      glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
      expect(currentTexture).to.equal(0);
    });
    
    it(@"should bind and execute block", ^{
      __block GLint currentTexture;
      __block BOOL didExecute = NO;
      glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
      expect(currentTexture).to.equal(0);
      [texture bindAndExecute:^{
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTexture);
        expect(currentTexture).toNot.equal(0);
        didExecute = YES;
      }];
      expect(didExecute).to.beTruthy();
    });
  });
  
  context(@"execution", ^{
    it(@"should execute a block", ^{
      __block BOOL didExecute = NO;
      [texture executeAndPreserveParameters:^{
        didExecute = YES;
      }];
      expect(didExecute).to.beTruthy();
    });
    
    itShouldBehaveLike(@"having default property values", ^{
      [texture executeAndPreserveParameters:^{
        texture.minFilterInterpolation = LTTextureInterpolationNearest;
        texture.magFilterInterpolation = LTTextureInterpolationNearest;
        texture.wrap = LTTextureWrapRepeat;
      }];
      return @{@"texture": texture};
    });
    
    it(@"should execute a nil block", ^{
      expect(^{
        [texture bindAndExecute:nil];
      }).toNot.raiseAny();
    });
    
    // TODO: (amit)uncomment when pushed.
    it(@"should execute a nil block when already bound", ^{
      expect(^{
        [texture bind];
        [texture bindAndExecute:nil];
        [texture unbind];
      }).toNot.raiseAny();
    });
  });
});

context(@"texture with data", ^{
  __block LTTexture *texture;
  __block cv::Mat image;

  beforeEach(^{
    image.create(48, 67, CV_8UC4);
    for (int y = 0; y < image.rows; ++y) {
      for (int x = 0; x < image.cols; ++x) {
        image.at<cv::Vec4b>(y, x) = cv::Vec4b(x, y, 0, 255);
      }
    }

    texture = [[LTGLTexture alloc] initWithImage:image];
  });

  afterEach(^{
    texture = nil;
  });

  context(@"loading data from texture", ^{
    it(@"should read entire texture to image", ^{
      cv::Mat read = [texture image];

      expect(LTCompareMat(image, read)).to.beTruthy();
    });

    it(@"should read part of texture to image", ^{
      CGRect rect = CGRectMake(2, 2, 10, 15);

      cv::Mat read = [texture imageWithRect:rect];

      expect(read.cols).to.equal(rect.size.width);
      expect(read.rows).to.equal(rect.size.height);
      expect(LTCompareMat(image(LTCVRectWithCGRect(rect)), read)).to.beTruthy();
    });

    it(@"should return a correct pixel value", ^{
      CGPoint point = CGPointMake(1, 7);

      GLKVector4 actual = [texture pixelValue:point];
      GLKVector4 expected = LTCVVec4bToGLKVector4(image.at<cv::Vec4b>(point.y, point.x));

      expect(expected).to.equal(actual);
    });

    it(@"should return correct pixel values", ^{
      CGPoints points{CGPointMake(1, 2), CGPointMake(2, 5), CGPointMake(7, 3)};

      GLKVector4s actual = [texture pixelValues:points];
      GLKVector4s expected;
      for (const CGPoint &point : points) {
        expected.push_back(LTCVVec4bToGLKVector4(image.at<cv::Vec4b>(point.y, point.x)));
      }

      expect(expected == actual).to.equal(YES);
    });
  });

  context(@"cloning", ^{
    it(@"should clone itself to a new texture", ^{
      LTTexture *cloned = [texture clone];

      expect(cloned.name).toNot.equal(texture.name);

      cv::Mat read = [cloned image];
      expect(LTCompareMat(image, read)).to.beTruthy();
    });

    it(@"should clone itself to an existing texture", ^{
      LTTexture *cloned = [[LTGLTexture alloc] initWithSize:texture.size
                                                  precision:texture.precision
                                                   channels:texture.channels
                                             allocateMemory:YES];

      [texture cloneTo:cloned];

      cv::Mat read = [cloned image];
      expect(LTCompareMat(image, read)).to.beTruthy();
    });
  });
});

SpecEnd
