// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTArrayBuffer.h"

#import "LTGLContext.h"
#import "LTGPUResourceExamples.h"

SpecBegin(LTArrayBuffer)

static NSString * const kLTArrayBufferInitializationExamples =
    @"LTArrayBufferInitializationExamples";

static NSString * const kLTArrayBufferModificationExamples = @"LTArrayBufferModification";

static NSString * const kLTArrayBufferExamples = @"LTArrayBufferExamples";

sharedExamplesFor(kLTArrayBufferInitializationExamples, ^(NSDictionary *dict) {
  it(@"should add initial data with a single buffer", ^{
    LTArrayBuffer *buffer = dict[@"buffer"];
    NSData *data = dict[@"data"];
    [buffer setData:data];

    expect(buffer.size).to.equal(data.length);
    expect([buffer data]).to.equal(data);
  });
  
  it(@"should add initial data by concatenating buffers", ^{
    LTArrayBuffer *buffer = dict[@"buffer"];
    NSData *data = dict[@"data"];
    NSData *otherData = [NSMutableData dataWithLength:data.length];
    [buffer setDataWithConcatenatedData:@[data, otherData]];
    
    NSMutableData *concatenatedData = [data mutableCopy];
    [concatenatedData appendData:otherData];
    expect(buffer.size).to.equal(concatenatedData.length);
    expect([buffer data]).to.equal(concatenatedData);
  });
});

sharedExamplesFor(kLTArrayBufferModificationExamples, ^(NSDictionary *dict) {
  it(@"should update data with a single buffer of the same size", ^{
    LTArrayBuffer *buffer = dict[@"buffer"];
    NSData *reversedData = dict[@"reversedData"];

    [buffer setData:dict[@"data"]];
    [buffer setData:reversedData];

    expect(buffer.size).to.equal(reversedData.length);
    expect([buffer data]).to.equal(reversedData);
  });

  it(@"should update data with concatenated buffers of the same size", ^{
    LTArrayBuffer *buffer = dict[@"buffer"];
    NSData *reversedData = dict[@"reversedData"];
    NSData *otherData = [NSMutableData dataWithLength:reversedData.length];
    
    [buffer setDataWithConcatenatedData:@[dict[@"data"], otherData]];
    [buffer setDataWithConcatenatedData:@[otherData, reversedData]];
    
    NSMutableData *concatenatedData = [otherData mutableCopy];
    [concatenatedData appendData:reversedData];
    expect(buffer.size).to.equal(concatenatedData.length);
    expect([buffer data]).to.equal(concatenatedData);
  });

  it(@"should update data with a single buffer of different size", ^{
    LTArrayBuffer *buffer = dict[@"buffer"];
    NSData *otherData = dict[@"otherData"];

    [buffer setData:dict[@"data"]];
    [buffer setData:otherData];

    expect(buffer.size).to.equal(otherData.length);
    expect([buffer data]).to.equal(otherData);
  });
  
  it(@"should update data with concatenated buffers of different size", ^{
    LTArrayBuffer *buffer = dict[@"buffer"];
    NSData *data = dict[@"data"];
    NSData *otherData = dict[@"otherData"];
    
    [buffer setData:data];
    [buffer setDataWithConcatenatedData:@[otherData, data]];
    
    NSMutableData *concatenatedData = [otherData mutableCopy];
    [concatenatedData appendData:data];
    expect(buffer.size).to.equal(concatenatedData.length);
    expect([buffer data]).to.equal(concatenatedData);
  });
});

sharedExamplesFor(kLTArrayBufferExamples, ^(NSDictionary *contextInfo) {
  beforeEach(^{
    LTGLVersion version = (LTGLVersion)[contextInfo[@"version"] unsignedIntegerValue];
    LTGLContext *context = [[LTGLContext alloc] initWithSharegroup:nil version:version];
    [LTGLContext setCurrentContext:context];
  });

  it(@"should set properties after initialization", ^{
    LTArrayBuffer *buffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeElement
                                                          usage:LTArrayBufferUsageStaticDraw];

    expect(buffer.type).to.equal(LTArrayBufferTypeElement);
    expect(buffer.usage).to.equal(LTArrayBufferUsageStaticDraw);
    expect(buffer.size).to.equal(0);
  });

  context(@"binding", ^{
    __block LTArrayBuffer *buffer;

    context(@"element array", ^{
      beforeEach(^{
        buffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeElement
                                               usage:LTArrayBufferUsageStaticDraw];
      });

      afterEach(^{
        buffer = nil;
      });

      itShouldBehaveLike(kLTResourceExamples, ^{
        return @{kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:buffer],
                 kLTResourceExamplesOpenGLParameterName: @GL_ELEMENT_ARRAY_BUFFER_BINDING};
      });
    });

    context(@"generic array", ^{
      beforeEach(^{
        buffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                               usage:LTArrayBufferUsageStaticDraw];
      });

      afterEach(^{
        buffer = nil;
      });

      itShouldBehaveLike(kLTResourceExamples, ^{
        return @{kLTResourceExamplesSUTValue: [NSValue valueWithNonretainedObject:buffer],
                 kLTResourceExamplesOpenGLParameterName: @GL_ARRAY_BUFFER_BINDING};
      });
    });

    it(@"should conform binding scope of bindAndExecute", ^{
      LTArrayBuffer *buffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                            usage:LTArrayBufferUsageStaticDraw];

      __block GLint boundBuffer;
      [buffer bindAndExecute:^{
        glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &boundBuffer);
        expect(boundBuffer).to.equal(buffer.name);
      }];

      glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &boundBuffer);
      expect(boundBuffer).to.equal(0);
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
            buffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                   usage:LTArrayBufferUsageStaticDraw];
          });

          afterEach(^{
            buffer = nil;
          });

          itShouldBehaveLike(kLTArrayBufferInitializationExamples, ^{
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
            buffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                   usage:LTArrayBufferUsageDynamicDraw];
          });

          afterEach(^{
            buffer = nil;
          });

          itShouldBehaveLike(kLTArrayBufferInitializationExamples, ^{
            return @{@"buffer": buffer, @"data": data};
          });

          itShouldBehaveLike(kLTArrayBufferModificationExamples, ^{
            return @{@"buffer": buffer, @"data": data,
                     @"reversedData": reversedData, @"otherData": otherData};
          });
        });

        context(@"stream buffer", ^{
          beforeEach(^{
            buffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeGeneric
                                                   usage:LTArrayBufferUsageStreamDraw];
          });

          afterEach(^{
            buffer = nil;
          });

          itShouldBehaveLike(kLTArrayBufferInitializationExamples, ^{
            return @{@"buffer": buffer, @"data": data};
          });

          itShouldBehaveLike(kLTArrayBufferModificationExamples, ^{
            return @{@"buffer": buffer, @"data": data,
                     @"reversedData": reversedData, @"otherData": otherData};
          });
        });
      });

      context(@"element array", ^{
        context(@"static buffer", ^{
          beforeEach(^{
            buffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeElement
                                                   usage:LTArrayBufferUsageStaticDraw];
          });

          afterEach(^{
            buffer = nil;
          });

          itShouldBehaveLike(kLTArrayBufferInitializationExamples, ^{
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
            buffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeElement
                                                   usage:LTArrayBufferUsageDynamicDraw];
          });

          afterEach(^{
            buffer = nil;
          });

          itShouldBehaveLike(kLTArrayBufferInitializationExamples, ^{
            return @{@"buffer": buffer, @"data": data};
          });

          itShouldBehaveLike(kLTArrayBufferModificationExamples, ^{
            return @{@"buffer": buffer, @"data": data,
                     @"reversedData": reversedData, @"otherData": otherData};
          });
        });

        context(@"stream buffer", ^{
          beforeEach(^{
            buffer = [[LTArrayBuffer alloc] initWithType:LTArrayBufferTypeElement
                                                   usage:LTArrayBufferUsageStreamDraw];
          });

          afterEach(^{
            buffer = nil;
          });

          itShouldBehaveLike(kLTArrayBufferInitializationExamples, ^{
            return @{@"buffer": buffer, @"data": data};
          });

          itShouldBehaveLike(kLTArrayBufferModificationExamples, ^{
            return @{@"buffer": buffer, @"data": data,
                     @"reversedData": reversedData, @"otherData": otherData};
          });
        });
      });
    });
  });
});

itShouldBehaveLike(kLTArrayBufferExamples, @{@"version": @(LTGLVersion2)});
itShouldBehaveLike(kLTArrayBufferExamples, @{@"version": @(LTGLVersion3)});

SpecEnd
