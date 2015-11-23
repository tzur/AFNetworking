// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRef.h"

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

LTMakeRefReleaser(LTMyType *, LTMyTypeRelease);

SpecBegin(LTRef)

context(@"releaser for custom type", ^{
  afterEach(^{
    releaseBlock = nil;
  });

  it(@"should call release function when Ref is destroyed", ^{
    __block BOOL released = NO;
    releaseBlock = ^(LTMyType *releasedMyType) {
      expect(@(releasedMyType->name().c_str())).to.equal(@"foo");
      released = YES;
    };

    {
      lt::Ref<LTMyType *> myType(new LTMyType("foo"));
    }

    expect(released).to.beTruthy();
  });
});

context(@"move semantics", ^{
  it(@"should use move constructor correctly", ^{
    lt::Ref<LTMyType *> myType(new LTMyType("foo"));
    LTMyType *firstReference = myType.get();

    lt::Ref<LTMyType *> movedMyType = std::move(myType);
    LTMyType *movedReference = movedMyType.get();

    LTMyType *stolenReference = myType.get();

    expect(firstReference).to.equal(movedReference);
    expect(stolenReference).toNot.equal(movedReference);
  });

  it(@"should use move assignment operator correctly", ^{
    lt::Ref<LTMyType *> myType(new LTMyType("foo"));
    lt::Ref<LTMyType *> movedMyType;

    LTMyType *firstReference = myType.get();
    movedMyType = std::move(myType);

    LTMyType *movedReference = movedMyType.get();
    LTMyType *stolenReference = myType.get();

    expect(firstReference).to.equal(movedReference);
    expect(stolenReference).toNot.equal(movedReference);
  });
});

context(@"releaser for registered types", ^{
  it(@"should release CGColorSpace", ^{
    CGColorSpaceRef colorSpaceRef;
    CFIndex retainCount;

    {
      lt::Ref<CGColorSpaceRef> colorSpace(CGColorSpaceCreateDeviceRGB());
      colorSpaceRef = (CGColorSpaceRef)CFRetain(colorSpace);
      retainCount = CFGetRetainCount(colorSpaceRef);
    }

    expect(CFGetRetainCount(colorSpaceRef)).to.equal(retainCount - 1);
    CGColorSpaceRelease(colorSpaceRef);
  });

  it(@"should release CGContext", ^{
    CGContextRef contextRef;
    CFIndex retainCount;

    {
      char data[4] = {0};
      lt::Ref<CGColorSpaceRef> colorSpace(CGColorSpaceCreateDeviceRGB());
      lt::Ref<CGContextRef> context(CGBitmapContextCreate(data, 1, 1, 8, 4,
                                                          colorSpace,
                                                          kCGImageAlphaPremultipliedLast |
                                                          kCGBitmapByteOrderDefault));
      contextRef = (CGContextRef)CFRetain(context);
      retainCount = CFGetRetainCount(contextRef);
    }

    expect(CFGetRetainCount(contextRef)).to.equal(retainCount - 1);
    CGContextRelease(contextRef);
  });

  it(@"should release CGDataProvider", ^{
    CGDataProviderRef dataProviderRef;
    CFIndex retainCount;

    {
      NSData *data = [NSData data];
      lt::Ref<CGDataProviderRef> dataProvider(CGDataProviderCreateWithCFData((CFDataRef)data));
      dataProviderRef = (CGDataProviderRef)CFRetain(dataProvider);
      retainCount = CFGetRetainCount(dataProviderRef);
    }

    expect(CFGetRetainCount(dataProviderRef)).to.equal(retainCount - 1);
    CGDataProviderRelease(dataProviderRef);
  });

  it(@"should release CGImage", ^{
    CGImageRef imageRef;
    CFIndex retainCount;

    {
      UIImage *source;
      UIGraphicsBeginImageContext(CGSizeMake(1, 1)); {
        source = UIGraphicsGetImageFromCurrentImageContext();
      } UIGraphicsEndImageContext();

      lt::Ref<CGImageRef> image(CGImageCreateCopy(source.CGImage));
      imageRef = (CGImageRef)CFRetain(image);
      retainCount = CFGetRetainCount(imageRef);
    }

    expect(CFGetRetainCount(imageRef)).to.equal(retainCount - 1);
    CGImageRelease(imageRef);
  });

  it(@"should release CGPath", ^{
    CGPathRef pathRef;
    CFIndex retainCount;

    {
      UIImage *source;
      UIGraphicsBeginImageContext(CGSizeMake(1, 1)); {
        source = UIGraphicsGetImageFromCurrentImageContext();
      } UIGraphicsEndImageContext();

      lt::Ref<CGPathRef> path(CGPathCreateMutable());
      pathRef = (CGPathRef)CFRetain(path);
      retainCount = CFGetRetainCount(pathRef);
    }

    expect(CFGetRetainCount(pathRef)).to.equal(retainCount - 1);
    CGPathRelease(pathRef);
  });

  it(@"should release CGGradient", ^{
    CGGradientRef gradientRef;
    CFIndex retainCount;

    {
      UIImage *source;
      UIGraphicsBeginImageContext(CGSizeMake(1, 1)); {
        source = UIGraphicsGetImageFromCurrentImageContext();
      } UIGraphicsEndImageContext();

      lt::Ref<CGColorSpaceRef> colorSpace(CGColorSpaceCreateDeviceRGB());
      CGFloat components[4] = {0};
      CGFloat locations[1] = {0};
      lt::Ref<CGGradientRef> image(CGGradientCreateWithColorComponents(colorSpace,
                                                                       components,
                                                                       locations, 1));
      gradientRef = (CGGradientRef)CFRetain(image);
      retainCount = CFGetRetainCount(gradientRef);
    }

    expect(CFGetRetainCount(gradientRef)).to.equal(retainCount - 1);
    CGGradientRelease(gradientRef);
  });
});

SpecEnd
