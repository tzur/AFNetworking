// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTIndicesArray.h"

#import "LTArrayBuffer.h"

LTSpecBegin(LTIndicesArray)

__block LTIndicesArray *array;
__block id buffer;

beforeEach(^{
  buffer = [OCMockObject mockForClass:[LTArrayBuffer class]];
});

afterEach(^{
  array = nil;
});

context(@"initialization", ^{
  it(@"should initialize with type and valid buffer", ^{
    [(LTArrayBuffer *)[[buffer stub] andReturnValue:@(LTArrayBufferTypeElement)] type];
    array = [[LTIndicesArray alloc] initWithType:LTIndicesBufferTypeByte arrayBuffer:buffer];
    expect(array.type).to.equal(LTIndicesBufferTypeByte);
    expect(array.arrayBuffer).to.beIdenticalTo(buffer);
  });
  
  it(@"should raise when initializing without buffer", ^{
    expect(^{
      array = [[LTIndicesArray alloc] initWithType:LTIndicesBufferTypeByte arrayBuffer:nil];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should raise when initializing with buffer of wrong type", ^{
    expect(^{
      [(LTArrayBuffer *)[[buffer stub] andReturnValue:@(LTArrayBufferTypeGeneric)] type];
      array = [[LTIndicesArray alloc] initWithType:LTIndicesBufferTypeByte arrayBuffer:buffer];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"properties", ^{
  beforeEach(^{
    [(LTArrayBuffer *)[[buffer stub] andReturnValue:@(LTArrayBufferTypeElement)] type];
    [(LTArrayBuffer *)[[buffer expect] andReturnValue:@(16)] size];
  });

  it(@"should return correct count for byte indices", ^{
    array = [[LTIndicesArray alloc] initWithType:LTIndicesBufferTypeByte arrayBuffer:buffer];
    expect(array.count).to.equal(16);
    [buffer verify];
 });
  
  it(@"should return correct count for short indices", ^{
    array = [[LTIndicesArray alloc] initWithType:LTIndicesBufferTypeShort arrayBuffer:buffer];
    expect(array.count).to.equal(8);
    [buffer verify];
  });
  
  it(@"should return correct count for integer indices", ^{
    array = [[LTIndicesArray alloc] initWithType:LTIndicesBufferTypeInteger arrayBuffer:buffer];
    expect(array.count).to.equal(4);
    [buffer verify];
  });
  
  it(@"count should reflect the current buffer size", ^{
    array = [[LTIndicesArray alloc] initWithType:LTIndicesBufferTypeByte arrayBuffer:buffer];
    expect(array.count).to.equal(16);
    [(LTArrayBuffer *)[[buffer expect] andReturnValue:@(32)] size];
    expect(array.count).to.equal(32);
    [buffer verify];
  });
});

LTSpecEnd
