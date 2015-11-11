// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTDefaultDeleters.h"

#import <string>

class LTMyType {
public:
  LTMyType(const std::string &name) : _name(name) {};

  const std::string name() const {
    return _name;
  }

private:
  const std::string _name;
};

typedef void (^LTMyTypeReleaseBlock)(LTMyType *myType);

static LTMyTypeReleaseBlock releaseBlock;

void LTMyTypeRelease(LTMyType *myType) {
  if (releaseBlock) {
    releaseBlock(myType);
  }
}

LTMakeDefaultDelete(LTMyType, LTMyTypeRelease);

SpecBegin(LTDefaultDeleters)

context(@"deleter for custom type", ^{
  afterEach(^{
    releaseBlock = nil;
  });

  it(@"should call deleter function when unique_ptr is destroyed", ^{
    __block BOOL released = NO;
    releaseBlock = ^(LTMyType *releasedMyType) {
      expect(@(releasedMyType->name().c_str())).to.equal(@"foo");
      released = YES;
    };

    {
      std::unique_ptr<LTMyType> myType(new LTMyType("foo"));
    }

    expect(released).to.beTruthy();
  });
});

context(@"deleter for registered types", ^{
  it(@"should delete CGColorSpace", ^{
    CGColorSpaceRef colorSpaceRef;
    CFIndex retainCount;

    {
      std::unique_ptr<CGColorSpace> colorSpace(CGColorSpaceCreateDeviceRGB());
      colorSpaceRef = (CGColorSpaceRef)CFRetain(colorSpace.get());
      retainCount = CFGetRetainCount(colorSpaceRef);
    }

    expect(CFGetRetainCount(colorSpaceRef)).to.equal(retainCount - 1);
    CGColorSpaceRelease(colorSpaceRef);
  });

  it(@"should delete CGContext", ^{
    CGContextRef contextRef;
    CFIndex retainCount;

    {
      char data[4] = {0};
      std::unique_ptr<CGColorSpace> colorSpace(CGColorSpaceCreateDeviceRGB());
      std::unique_ptr<CGContext> context(CGBitmapContextCreate(data, 1, 1, 8, 4,
                                                               colorSpace.get(),
                                                               kCGImageAlphaPremultipliedLast |
                                                               kCGBitmapByteOrderDefault));
      contextRef = (CGContextRef)CFRetain(context.get());
      retainCount = CFGetRetainCount(contextRef);
    }

    expect(CFGetRetainCount(contextRef)).to.equal(retainCount - 1);
    CGContextRelease(contextRef);
  });

  it(@"should delete CGDataProvider", ^{
    CGDataProviderRef dataProviderRef;
    CFIndex retainCount;

    {
      NSData *data = [NSData data];
      std::unique_ptr<CGDataProvider> dataProvider(CGDataProviderCreateWithCFData((CFDataRef)data));
      dataProviderRef = (CGDataProviderRef)CFRetain(dataProvider.get());
      retainCount = CFGetRetainCount(dataProviderRef);
    }

    expect(CFGetRetainCount(dataProviderRef)).to.equal(retainCount - 1);
    CGDataProviderRelease(dataProviderRef);
  });

  it(@"should delete CGImage", ^{
    CGImageRef imageRef;
    CFIndex retainCount;

    {
      UIImage *source;
      UIGraphicsBeginImageContext(CGSizeMake(1, 1)); {
        source = UIGraphicsGetImageFromCurrentImageContext();
      } UIGraphicsEndImageContext();

      std::unique_ptr<CGImage> image(CGImageCreateCopy(source.CGImage));
      imageRef = (CGImageRef)CFRetain(image.get());
      retainCount = CFGetRetainCount(imageRef);
    }

    expect(CFGetRetainCount(imageRef)).to.equal(retainCount - 1);
    CGImageRelease(imageRef);
  });

  it(@"should delete CGPath", ^{
    CGPathRef pathRef;
    CFIndex retainCount;

    {
      UIImage *source;
      UIGraphicsBeginImageContext(CGSizeMake(1, 1)); {
        source = UIGraphicsGetImageFromCurrentImageContext();
      } UIGraphicsEndImageContext();

      std::unique_ptr<CGPath> path(CGPathCreateMutable());
      pathRef = (CGPathRef)CFRetain(path.get());
      retainCount = CFGetRetainCount(pathRef);
    }

    expect(CFGetRetainCount(pathRef)).to.equal(retainCount - 1);
    CGPathRelease(pathRef);
  });

  it(@"should delete CGGradient", ^{
    CGGradientRef gradientRef;
    CFIndex retainCount;

    {
      UIImage *source;
      UIGraphicsBeginImageContext(CGSizeMake(1, 1)); {
        source = UIGraphicsGetImageFromCurrentImageContext();
      } UIGraphicsEndImageContext();

      std::unique_ptr<CGColorSpace> colorSpace(CGColorSpaceCreateDeviceRGB());
      CGFloat components[4] = {0};
      CGFloat locations[1] = {0};
      std::unique_ptr<CGGradient> image(CGGradientCreateWithColorComponents(colorSpace.get(),
                                                                            components,
                                                                            locations, 1));
      gradientRef = (CGGradientRef)CFRetain(image.get());
      retainCount = CFGetRetainCount(gradientRef);
    }

    expect(CFGetRetainCount(gradientRef)).to.equal(retainCount - 1);
    CGGradientRelease(gradientRef);
  });
});

SpecEnd
