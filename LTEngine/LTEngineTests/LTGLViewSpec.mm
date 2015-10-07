// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "LTGLView.h"

#import "LTGLContext.h"

SpecBegin(LTGLView)

__block LTGLContext *glContext;

beforeEach(^{
  glContext = [LTGLContext currentContext];
});

context(@"opengl context restoration", ^{
  it(@"should preserve opengl context after deallocation", ^{
    LTGLContext *expectedContext = glContext;
    @autoreleasepool {
      LTGLView __unused *glView = [[LTGLView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)
                                                          context:glContext.context];
    }
    expect([EAGLContext currentContext]).to.beIdenticalTo(expectedContext.context);
  });

  it(@"should preserve the latest opengl context after deallocation", ^{
    LTGLContext *expectedContext = [[LTGLContext alloc] init];
    @autoreleasepool {
      LTGLView *glView = [[LTGLView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)
                                                 context:glContext.context];
      [LTGLContext setCurrentContext:expectedContext];

      // This line should have no real effect, it is added just to make sure glView will not be
      // deallocated before OpenGL context is updated (due to optimizations).
      glView.context = glContext.context;
    }
    expect([EAGLContext currentContext]).to.beIdenticalTo(expectedContext.context);
  });
});

SpecEnd
