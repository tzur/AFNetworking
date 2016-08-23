// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "CIContext+PixelFormat.h"

#import "LTGLPixelFormat.h"

// TODO:(amit) remove this extension and change tests from xit to it once XCode 8 is used, as this
// property is documented but does not exist prior to it.
@interface CIContext ()
@property (readonly, nonatomic) CIFormat workingFormat;
@end

SpecBegin(CIContext_PixelFormat)

context(@"create context with correct working format precision", ^{
  xit(@"should use half float precision working format for half float precision pixel format", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *format) {
      if (format.bitDepth != LTGLPixelBitDepth16 || format.dataType != LTGLPixelDataTypeFloat) {
        return;
      }

      CIContext *context = [CIContext lt_contextWithPixelFormat:format];
      expect(context.workingFormat).to.equal(kCIFormatRGBAh);
    }];
  });

  xit(@"should use byte precision working format for byte precision pixel format", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *format) {
      if (format.bitDepth != LTGLPixelBitDepth8 || format.dataType != LTGLPixelDataTypeUnorm) {
        return;
      }

      CIContext *context = [CIContext lt_contextWithPixelFormat:format];
      expect(context.workingFormat).to.equal(kCIFormatRGBA8);
    }];
  });
});

it(@"should raise when creating context with an invalid pixel format", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *format) {
      if ((format.bitDepth == LTGLPixelBitDepth8 && format.dataType == LTGLPixelDataTypeUnorm) ||
          (format.bitDepth == LTGLPixelBitDepth16 && format.dataType == LTGLPixelDataTypeFloat)) {
        return;
      }

      expect(^{
        CIContext __unused *context = [CIContext lt_contextWithPixelFormat:format];
      }).to.raise(NSInvalidArgumentException);
    }];
});

SpecEnd
