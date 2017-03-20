// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTProgramPool.h"

#import "LTGLContext.h"
#import "LTProgram.h"

SpecBegin(LTProgramPool)

context(@"recycling", ^{
  __block LTProgramPool *pool;

  beforeEach(^{
    pool = [[LTProgramPool alloc] init];
  });

  it(@"should fetch new name for the same identifier if not recycled", ^{
    GLuint name1 = [pool nameForIdentifier:@"foo"];
    GLuint name2 = [pool nameForIdentifier:@"foo"];

    expect(glIsProgram(name1)).to.equal(GL_TRUE);
    expect(glIsProgram(name2)).to.equal(GL_TRUE);
    expect(name1).notTo.equal(name2);
  });

  it(@"should fetch recycled name for the same identifier if recycled", ^{
    GLuint name1 = [pool nameForIdentifier:@"foo"];
    [pool recycleName:name1 withIdentifier:@"foo"];

    GLuint name2 = [pool nameForIdentifier:@"foo"];

    expect(glIsProgram(name1)).to.equal(GL_TRUE);
    expect(glIsProgram(name2)).to.equal(GL_TRUE);
    expect(name1).to.equal(name2);
  });

  it(@"should delete recycled programs when flushing the pool", ^{
    GLuint name1 = [pool nameForIdentifier:@"foo"];
    [pool recycleName:name1 withIdentifier:@"foo"];
    [pool flush];

    expect(glIsProgram(name1)).to.equal(GL_FALSE);
  });

  it(@"should not delete active programs when flushing the pool", ^{
    GLuint name1 = [pool nameForIdentifier:@"foo"];
    [pool flush];

    expect(glIsProgram(name1)).to.equal(GL_TRUE);
  });
});

it(@"should have valid current pool", ^{
  expect([LTProgramPool currentPool]).notTo.beNil();
});

context(@"current pool from current context", ^{
  __block LTGLContext *context;

  beforeEach(^{
    context = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:context];
  });

  afterEach(^{
    context = nil;
    [LTGLContext setCurrentContext:nil];
  });

  it(@"should return current pool from current context", ^{
    expect([LTProgramPool currentPool]).to.equal(context.programPool);
  });

  it(@"should not have current pool without current context", ^{
    [LTGLContext setCurrentContext:nil];
    expect([LTProgramPool currentPool]).to.beNil();
  });
});

SpecEnd
