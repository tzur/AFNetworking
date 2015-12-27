// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRenderbuffer.h"

#import "LTGLPixelFormat.h"
#import "LTGPUResourceExamples.h"
#import "LTRenderbuffer+Writing.h"

SpecBegin(LTRenderbuffer)

static const CGSize kDrawableSize = CGSizeMake(7, 5);

__block CAEAGLLayer *drawable;
__block LTRenderbuffer *renderbuffer = nil;

beforeEach(^{
  drawable = [CAEAGLLayer layer];
  drawable.frame = CGRectMake(0, 0, kDrawableSize.width, kDrawableSize.height);

  renderbuffer = [[LTRenderbuffer alloc] initWithDrawable:drawable];
});

afterEach(^{
  drawable = nil;
  renderbuffer = nil;
});

context(@"writable framebuffer attachment", ^{
  it(@"should have a valid name", ^{
    expect(renderbuffer.name).to.beGreaterThan(0);
  });

  it(@"should have a valid size", ^{
    expect(renderbuffer.size).to.equal(kDrawableSize);
  });

  it(@"should return correct pixel format", ^{
    expect(renderbuffer.pixelFormat).to.equal($(LTGLPixelFormatRGBA8Unorm));
  });

  it(@"should have a valid generation ID after initialization", ^{
    expect(renderbuffer.generationID).toNot.beNil();
  });

  it(@"should initially have a null fill color", ^{
    expect(renderbuffer.fillColor.isNull()).to.beTruthy();
  });

  it(@"should return correct attachment type", ^{
    expect(renderbuffer.attachmentType).to.equal(LTFboAttachmentTypeRenderbuffer);
  });

  it(@"should update generation ID upon writing", ^{
    NSString *generationID = renderbuffer.generationID;
    [renderbuffer writeToAttachmentWithBlock:^{}];

    expect(renderbuffer.generationID).toNot.equal(generationID);
  });

  it(@"should set clear color and update generation ID upon clearing", ^{
    NSString *generationID = renderbuffer.generationID;
    [renderbuffer clearAttachmentWithColor:LTVector4::ones() block:^{}];

    expect(renderbuffer.fillColor).to.equal(LTVector4::ones());
    expect(renderbuffer.generationID).toNot.equal(generationID);
  });
});

context(@"presentation", ^{
  // TODO:(yaron) Add once framebuffer will support renderbuffers, as currently we cannot write into
  // them.
  pending(@"should present renderbuffer in drawable");
});

context(@"binding", ^{
  itShouldBehaveLike(kLTResourceExamples, ^{
    return @{kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:renderbuffer],
             kLTResourceExamplesOpenGLParameterName: @GL_RENDERBUFFER_BINDING};
  });
});

SpecEnd
