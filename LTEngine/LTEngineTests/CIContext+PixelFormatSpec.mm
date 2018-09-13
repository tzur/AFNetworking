// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "CIContext+PixelFormat.h"

#import "LTGLPixelFormat.h"

SpecBegin(CIContext_PixelFormat)

context(@"create context with correct working format precision", ^{
  xit(@"should use half float precision working format for half float precision pixel format", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *format) {
      if (format.dataType != LTGLPixelDataType16Float) {
        return;
      }

      CIContext *context = [CIContext lt_contextWithPixelFormat:format];
      expect(context.workingFormat).to.equal(kCIFormatRGBAh);
    }];
  });

  xit(@"should use byte precision working format for byte precision pixel format", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *format) {
      if (format.dataType != LTGLPixelDataType8Unorm) {
        return;
      }

      CIContext *context = [CIContext lt_contextWithPixelFormat:format];
      expect(context.workingFormat).to.equal(kCIFormatRGBA8);
    }];
  });
});

it(@"should raise when creating context with an invalid pixel format", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *format) {
      if (format.dataType == LTGLPixelDataType8Unorm ||
          format.dataType == LTGLPixelDataType16Float) {
        return;
      }

      expect(^{
        CIContext __unused *context = [CIContext lt_contextWithPixelFormat:format];
      }).to.raise(NSInvalidArgumentException);
    }];
});

context(@"caching contexts", ^{
  afterEach(^{
    [CIContext lt_clearContextCache];
  });

  it(@"should cache contexts", ^{
    CIContext *firstContext = [CIContext lt_contextWithPixelFormat:$(LTGLPixelFormatRGBA8Unorm)];
    CIContext *secondContext = [CIContext lt_contextWithPixelFormat:$(LTGLPixelFormatRGBA8Unorm)];

    CIContext *otherContext = [CIContext lt_contextWithPixelFormat:$(LTGLPixelFormatRGBA16Float)];

    expect(firstContext).to.beIdenticalTo(secondContext);
    expect(firstContext).notTo.beIdenticalTo(otherContext);
  });

  it(@"should clear context cache", ^{
    CIContext *firstContext = [CIContext lt_contextWithPixelFormat:$(LTGLPixelFormatRGBA8Unorm)];
    [CIContext lt_clearContextCache];
    CIContext *secondContext = [CIContext lt_contextWithPixelFormat:$(LTGLPixelFormatRGBA8Unorm)];

    expect(firstContext).notTo.beIdenticalTo(secondContext);
  });

  it(@"should cache contexts between threads", ^{
    CIContext *firstContext = [CIContext lt_contextWithPixelFormat:$(LTGLPixelFormatRGBA8Unorm)];

    __block CIContext *secondContext;
    waitUntil(^(DoneCallback done) {
      dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        secondContext = [CIContext lt_contextWithPixelFormat:$(LTGLPixelFormatRGBA8Unorm)];
        done();
      });
    });

    expect(firstContext).to.beIdenticalTo(secondContext);
  });
});

SpecEnd
