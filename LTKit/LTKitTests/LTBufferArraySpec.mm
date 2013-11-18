// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBufferArray.h"

SpecBegin(LTBufferArray)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

sharedExamplesFor(@"array buffer that initializes its data", ^(NSDictionary *dict) {
  it(@"should add initial data", ^{
    LTArrayBuffer *buffer = dict[@"buffer"];
    NSData *data = dict[@"data"];
    [buffer setData:data];

    expect(buffer.size).to.equal(data.length);
    expect([buffer data]).to.equal(data);
  });
});

sharedExamplesFor(@"array buffer that modifies its contents", ^(NSDictionary *dict) {
  it(@"should update data with the same size", ^{
    LTArrayBuffer *buffer = dict[@"buffer"];
    NSData *reversedData = dict[@"reversedData"];

    [buffer setData:dict[@"data"]];
    [buffer setData:reversedData];

    expect(buffer.size).to.equal(reversedData.length);
    expect([buffer data]).to.equal(reversedData);
  });

  it(@"should update data with different size", ^{
    LTArrayBuffer *buffer = dict[@"buffer"];
    NSData *otherData = dict[@"otherData"];

    [buffer setData:dict[@"data"]];
    [buffer setData:otherData];

    expect(buffer.size).to.equal(otherData.length);
    expect([buffer data]).to.equal(otherData);
  });
});

it(@"should set properties after initialization", ^{
  LTArrayBuffer *buffer = [[LTArrayBuffer alloc] initWithType:LTBufferArrayTypeElement
                                                        usage:LTBufferArrayUsageStaticDraw];

  expect(buffer.type).to.equal(LTBufferArrayTypeElement);
  expect(buffer.usage).to.equal(LTBufferArrayUsageStaticDraw);
  expect(buffer.size).to.equal(0);
});

context(@"binding", ^{
  __block LTArrayBuffer *buffer;

  context(@"element array", ^{
    beforeEach(^{
      buffer = [[LTArrayBuffer alloc] initWithType:LTBufferArrayTypeElement
                                             usage:LTBufferArrayUsageStaticDraw];
    });

    afterEach(^{
      buffer = nil;
    });

    it(@"should bind", ^{
      [buffer bind];

      GLint boundedBuffer;
      glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &boundedBuffer);

      expect(boundedBuffer).to.equal(buffer.name);
    });

    it(@"should unbind", ^{
      [buffer bind];
      [buffer unbind];

      GLint boundedBuffer;
      glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &boundedBuffer);

      expect(boundedBuffer).to.equal(0);
    });
  });

  context(@"generic array", ^{
    beforeEach(^{
      buffer = [[LTArrayBuffer alloc] initWithType:LTBufferArrayTypeGeneric
                                             usage:LTBufferArrayUsageStaticDraw];
    });

    afterEach(^{
      buffer = nil;
    });

    it(@"should bind", ^{
      [buffer bind];

      GLint boundedBuffer;
      glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &boundedBuffer);

      expect(boundedBuffer).to.equal(buffer.name);
    });

    it(@"should unbind", ^{
      [buffer bind];
      [buffer unbind];

      GLint boundedBuffer;
      glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &boundedBuffer);

      expect(boundedBuffer).to.equal(0);
    });
  });

  it(@"should conform binding scope of bindAndExecute", ^{
    LTArrayBuffer *buffer = [[LTArrayBuffer alloc] initWithType:LTBufferArrayTypeGeneric
                                                          usage:LTBufferArrayUsageStaticDraw];

    __block GLint boundedBuffer;
    [buffer bindAndExecute:^{
      glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &boundedBuffer);
      expect(boundedBuffer).to.equal(buffer.name);
    }];

    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &boundedBuffer);
    expect(boundedBuffer).to.equal(0);
  });

  context(@"updating data", ^{
    __block LTArrayBuffer *buffer;
    __block NSData *data;
    __block NSData *reversedData;
    __block NSData *otherData;

    beforeAll(^{
      data = [@"0123456789" dataUsingEncoding:NSUTF8StringEncoding];
      reversedData = [@"9876543210" dataUsingEncoding:NSUTF8StringEncoding];
      otherData = [@"my_data_foo_bar" dataUsingEncoding:NSUTF8StringEncoding];
    });

    context(@"generic array", ^{
      context(@"static buffer", ^{
        beforeEach(^{
          buffer = [[LTArrayBuffer alloc] initWithType:LTBufferArrayTypeGeneric
                                                 usage:LTBufferArrayUsageStaticDraw];
        });

        afterEach(^{
          buffer = nil;
        });

        itShouldBehaveLike(@"array buffer that initializes its data", ^{
          return @{@"buffer": buffer, @"data": data};
        });

        it(@"should not allow second update", ^{
          [buffer setData:data];

          expect(^{
            [buffer setData:data];
          }).to.raise(kLTArrayBufferDisallowsStaticBufferUpdateException);
        });
      });

      context(@"dynamic buffer", ^{
        beforeEach(^{
          buffer = [[LTArrayBuffer alloc] initWithType:LTBufferArrayTypeGeneric
                                                 usage:LTBufferArrayUsageDynamicDraw];
        });

        afterEach(^{
          buffer = nil;
        });

        itShouldBehaveLike(@"array buffer that initializes its data", ^{
          return @{@"buffer": buffer, @"data": data};
        });

        itShouldBehaveLike(@"array buffer that modifies its contents", ^{
          return @{@"buffer": buffer, @"data": data,
                   @"reversedData": reversedData, @"otherData": otherData};
        });
      });

      context(@"stream buffer", ^{
        beforeEach(^{
          buffer = [[LTArrayBuffer alloc] initWithType:LTBufferArrayTypeGeneric
                                                 usage:LTBufferArrayUsageStreamDraw];
        });

        afterEach(^{
          buffer = nil;
        });

        itShouldBehaveLike(@"array buffer that initializes its data", ^{
          return @{@"buffer": buffer, @"data": data};
        });

        itShouldBehaveLike(@"array buffer that modifies its contents", ^{
          return @{@"buffer": buffer, @"data": data,
                   @"reversedData": reversedData, @"otherData": otherData};
        });
      });
    });

    context(@"element array", ^{
      context(@"static buffer", ^{
        beforeEach(^{
          buffer = [[LTArrayBuffer alloc] initWithType:LTBufferArrayTypeElement
                                                 usage:LTBufferArrayUsageStaticDraw];
        });

        afterEach(^{
          buffer = nil;
        });

        itShouldBehaveLike(@"array buffer that initializes its data", ^{
          return @{@"buffer": buffer, @"data": data};
        });

        it(@"should not allow second update", ^{
          [buffer setData:data];

          expect(^{
            [buffer setData:data];
          }).to.raise(kLTArrayBufferDisallowsStaticBufferUpdateException);
        });
      });

      context(@"dynamic buffer", ^{
        beforeEach(^{
          buffer = [[LTArrayBuffer alloc] initWithType:LTBufferArrayTypeElement
                                                 usage:LTBufferArrayUsageDynamicDraw];
        });

        afterEach(^{
          buffer = nil;
        });

        itShouldBehaveLike(@"array buffer that initializes its data", ^{
          return @{@"buffer": buffer, @"data": data};
        });

        itShouldBehaveLike(@"array buffer that modifies its contents", ^{
          return @{@"buffer": buffer, @"data": data,
                   @"reversedData": reversedData, @"otherData": otherData};
        });
      });

      context(@"stream buffer", ^{
        beforeEach(^{
          buffer = [[LTArrayBuffer alloc] initWithType:LTBufferArrayTypeElement
                                                 usage:LTBufferArrayUsageStreamDraw];
        });

        afterEach(^{
          buffer = nil;
        });

        itShouldBehaveLike(@"array buffer that initializes its data", ^{
          return @{@"buffer": buffer, @"data": data};
        });

        itShouldBehaveLike(@"array buffer that modifies its contents", ^{
          return @{@"buffer": buffer, @"data": data,
                   @"reversedData": reversedData, @"otherData": otherData};
        });
      });
    });
  });
});

SpecEnd
