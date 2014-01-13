// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMMTexture.h"

#import "LTFbo.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+ColorizeFsh.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTTestUtils.h"
#import "LTTextureExamples.h"

@interface LTTexture ()
@property (nonatomic) BOOL needsSynchronizationBeforeHostAccess;
@end

SpecBegin(LTMMTexture)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

itShouldBehaveLike(kLTTextureExamples, @{kLTTextureExamplesTextureClass: [LTMMTexture class]});

__block LTMMTexture *target;

beforeEach(^{
  target = [[LTMMTexture alloc] initWithSize:CGSizeMake(2, 2)
                                   precision:LTTexturePrecisionByte
                                    channels:LTTextureChannelsRGBA
                              allocateMemory:YES];
});

afterEach(^{
  target = nil;
});

context(@"host memory mapped texture", ^{
  __block LTFbo *fbo;
  __block LTRectDrawer *drawer;

  beforeEach(^{
    fbo = [[LTFbo alloc] initWithTexture:target];

    LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTShaderStorage passthroughVsh]
                                                  fragmentSource:[LTShaderStorage colorizeFsh]];
    drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:target];
    drawer[@"color"] = [NSValue valueWithGLKVector4:GLKVector4Make(1.0, 0.0, 0.0, 1.0)];
  });

  afterEach(^{
    fbo = nil;
    drawer = nil;
  });

  it(@"should require synchronization after draw", ^{
    CGRect rect = CGRectMake(0, 0, target.size.width, target.size.height);
    [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

    expect(target.needsSynchronizationBeforeHostAccess).to.beTruthy();
  });

  it(@"should map image without creating a copy", ^{
    [target mappedImage:^(cv::Mat, BOOL isCopy) {
      expect(isCopy).to.beFalsy();
    }];
  });

  it(@"should not require synchronization after mapping", ^{
    [target mappedImage:^(cv::Mat, BOOL) {
      expect(target.needsSynchronizationBeforeHostAccess).to.beFalsy();
    }];
  });

  dit(@"should read correct data after gpu draw", ^{
    CGRect rect = CGRectMake(0, 0, target.size.width, target.size.height);
    [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];

    [target mappedImage:^(cv::Mat mapped, BOOL) {
      expect(LTCompareMatWithValue(cv::Scalar(255, 0, 0, 255), mapped)).to.beTruthy();
    }];
  });
});

context(@"synchronization", ^{
  it(@"should not allow reading while writing", ^{
    __block BOOL inRead = NO;

    [target writeToTexture:^{
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [target readFromTexture:^{
          inRead = YES;
        }];
      });
      expect(inRead).to.beFalsy();
    }];
    expect(inRead).will.beTruthy();
  });

  it(@"should not allow writing while reading", ^{
    __block BOOL inWrite = NO;

    [target readFromTexture:^{
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [target writeToTexture:^{
          inWrite = YES;
        }];
      });
      expect(inWrite).to.beFalsy();
    }];
    expect(inWrite).will.beTruthy();
  });
});

SpecEnd
