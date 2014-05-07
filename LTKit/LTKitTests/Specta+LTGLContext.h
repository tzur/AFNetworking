// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLContext.h"

/// Defines a beginning of a test spec which uses LTGLContext.
#define SpecGLBegin(name) \
    SpecBegin(name) \
    \
    beforeEach(^{ \
      LTGLContext *context = [[LTGLContext alloc] init]; \
      [LTGLContext setCurrentContext:context]; \
    }); \
    \
    afterEach(^{ \
      [LTGLContext setCurrentContext:nil]; \
    });

/// End of spec that uses LTGLContext.
#define SpecGLEnd SpecEnd
