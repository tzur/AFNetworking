// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRenderbuffer.h"

#import "LTGLContext.h"
#import "LTGLPixelFormat.h"
#import "LTGPUResourceExamples.h"
#import "LTRenderbuffer+Writing.h"

SpecBegin(LTRenderbuffer)

/// Shared examples types.
static NSString * const kLTRenderbufferExamples = @"LTRenderbufferExamples";
static NSString * const kLTRenderbufferInitExamples = @"LTRenderbufferInitExamples";

/// Shared examples dictionary supported keys.
static NSString * const kVersionKey = @"versionKey";
static NSString * const kRenderbufferKey = @"renderbufferKey";
static NSString * const kExpectedPixelFromatKey = @"expectedPixelFormatKey";

/// Renderbuffer size.
static const CGSize kSize = CGSizeMake(7, 5);

sharedExamplesFor(kLTRenderbufferExamples, ^(NSDictionary *info) {
  __block LTRenderbuffer *renderbuffer;
  __block LTGLPixelFormat *expectedPixelFormat;

  beforeEach(^{
    expectedPixelFormat = (LTGLPixelFormat *)info[kExpectedPixelFromatKey];
    renderbuffer = (LTRenderbuffer *)info[kRenderbufferKey];
  });

  afterEach(^{
    renderbuffer = nil;
    expectedPixelFormat = nil;
  });

  context(@"writable framebuffer attachable", ^{
    it(@"should have a valid name", ^{
      expect(renderbuffer.name).to.beGreaterThan(0);
    });

    it(@"should have a valid size", ^{
      expect(renderbuffer.size).to.equal(kSize);
    });

    it(@"should return correct pixel format", ^{
      expect(renderbuffer.pixelFormat).to.equal(expectedPixelFormat);
    });

    it(@"should have a valid generation ID after initialization", ^{
      expect(renderbuffer.generationID).toNot.beNil();
    });

    it(@"should initially have a null fill color", ^{
      expect(renderbuffer.fillColor.isNull()).to.beTruthy();
    });

    it(@"should return correct attachable type", ^{
      expect(renderbuffer.attachableType).to.equal(LTFboAttachableTypeRenderbuffer);
    });

    it(@"should update generation ID upon writing", ^{
      NSString *generationID = renderbuffer.generationID;
      [renderbuffer writeToAttachableWithBlock:^{}];

      expect(renderbuffer.generationID).toNot.equal(generationID);
    });

    it(@"should set clear color and update generation ID upon clearing", ^{
      NSString *generationID = renderbuffer.generationID;
      [renderbuffer clearAttachableWithColor:LTVector4::ones() block:^{}];

      expect(renderbuffer.fillColor).to.equal(LTVector4::ones());
      expect(renderbuffer.generationID).toNot.equal(generationID);
    });
  });

  context(@"binding", ^{
    itShouldBehaveLike(kLTResourceExamples, ^{
      return @{kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:renderbuffer],
               kLTResourceExamplesOpenGLParameterName: @GL_RENDERBUFFER_BINDING};
    });
  });
});

sharedExamplesFor(kLTRenderbufferInitExamples, ^(NSDictionary *info) {
  context(@"initialization", ^{
    __block LTGLContext *context;

    beforeEach(^{
      auto version = (LTGLVersion)[info[kVersionKey] unsignedIntegerValue];
      context = [[LTGLContext alloc] initWithSharegroup:nil version:version];
      [LTGLContext setCurrentContext:context];
    });

    afterEach(^{
      [LTGLContext setCurrentContext:nil];
      context = nil;
    });

    itShouldBehaveLike(kLTRenderbufferExamples, ^{
      LTRenderbuffer *renderbuffer = [[LTRenderbuffer alloc] initWithSize:kSize
                                              pixelFormat:$(LTGLPixelFormatRGBA8Unorm)];

      return @{
        kRenderbufferKey: renderbuffer,
        kExpectedPixelFromatKey:$(LTGLPixelFormatRGBA8Unorm)
      };
    });

    itShouldBehaveLike(kLTRenderbufferExamples, ^{
      auto drawable = [CAEAGLLayer layer];
      drawable.frame = CGRectMake(0, 0, kSize.width, kSize.height);
      LTRenderbuffer *renderbuffer = [[LTRenderbuffer alloc] initWithDrawable:drawable];

      return @{
        kRenderbufferKey: renderbuffer,
        kExpectedPixelFromatKey: $(LTGLPixelFormatRGBA8Unorm)
      };
    });
  });
});

itShouldBehaveLike(kLTRenderbufferInitExamples, @{kVersionKey: @(LTGLVersion2)});
itShouldBehaveLike(kLTRenderbufferInitExamples, @{kVersionKey: @(LTGLVersion3)});

SpecEnd
