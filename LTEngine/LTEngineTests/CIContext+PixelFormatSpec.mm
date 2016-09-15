// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "CIContext+PixelFormat.h"

#import "LTGLPixelFormat.h"

// The working format is not available prior to iOS 10.
@interface CIContext ()

// \c workingFormat is documented to be available from iOS 9.0, however it is publicly available
// only on iOS 10.0 and above.
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_10_0
/// Working pixel format of the \c CIContext used for intermediate buffers.
@property (readonly, nonatomic) CIFormat workingFormat;
#endif

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
