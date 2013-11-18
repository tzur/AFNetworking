// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBufferArray.h"

#import "LTGLException.h"

//typedef struct _MyFloats {
//  float a;
//  float b;
//} MyFloats;
//
//typedef struct _MyStruct {
//  GLKVector2 a;
//  GLKVector2 b;
//} MyStruct;
//
//(_GLKVector2={?=ff}{?=ff}[2f])
//{_MyFloats=ff}
//{_MyStruct=(_GLKVector2={?=ff}{?=ff}[2f])(_GLKVector2={?=ff}{?=ff}[2f])}

@interface LTArrayBuffer ()

@property (readwrite, nonatomic) GLuint name;

/// OpenGL usage type of the buffer.
@property (readwrite, nonatomic) LTBufferArrayUsage usage;

/// Type of the buffer array.
@property (readwrite, nonatomic) LTBufferArrayType type;

/// Current size of the buffer.
@property (readwrite, nonatomic) NSUInteger size;

/// YES if the buffer is currently bounded.
@property (nonatomic) BOOL bounded;

/// Set to the previously bounded buffer, or \c 0 if the buffer is not bounded.
@property (nonatomic) GLint previousBuffer;

@end

@implementation LTArrayBuffer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (id)initWithType:(LTBufferArrayType)type usage:(LTBufferArrayUsage)usage {
  if (self = [super init]) {
    LTAssert(usage == GL_STATIC_DRAW || usage == GL_STREAM_DRAW || usage == GL_DYNAMIC_DRAW,
             @"Usage is not one of {GL_STATIC_DRAW, GL_STREAM_DRAW, GL_DYNAMIC_DRAW}");

    glGenBuffers(1, &_name);
    LTGLCheck(@"Failed generating buffer");

    self.type = type;
    self.usage = usage;
  }
  return self;
}

- (void)dealloc {
  glDeleteBuffers(1, &_name);
  LTGLCheckDbg(@"Failed to delete buffer: %d", _name);
}

#pragma mark -
#pragma mark Buffer update
#pragma mark -

- (void)setData:(NSData *)data {
  // Do not update to zero length.
  if (!data.length) {
    return;
  }

  [self bindAndExecute:^{
    switch (self.usage) {
      case LTBufferArrayUsageStaticDraw:
        // Static buffers allow only initial update.
        if (self.size) {
          [LTGLException raise:kLTArrayBufferDisallowsStaticBufferUpdateException
                        format:@"Tried to update a GL_STATIC_DRAW buffer"];
        };
        [self createBufferWithBufferData:data];
        break;
      case LTBufferArrayUsageDynamicDraw:
        // Dynamic buffers updates buffer if the data has the same size, and creates a new one for
        // different size.
        if (self.size != data.length) {
          [self createBufferWithBufferData:data];
        } else {
          [self createBufferWithSize:data.length];
          [self updateBufferWithMapping:data];
        }
        break;
      case LTBufferArrayUsageStreamDraw:
        // Stream buffers creates a new buffer for each update.
        [self createBufferWithSize:data.length];
        [self updateBufferWithMapping:data];
        break;
    }
  }];
}

- (NSData *)data {
  __block NSData *data;

  [self bindAndExecute:^{
    // This is the only way to read a buffer object, since OpenGL ES doesn't support the
    // \c GL_READ_ONLY flag with \c glMapBuffer().
    GLvoid *mappedBuffer = glMapBufferRangeEXT(self.type, 0, self.size, GL_MAP_READ_BIT_EXT);
    if (!mappedBuffer) {
      // OpenGL's documentation says: "If an error occurs, glMapBufferRange returns a NULL
      // pointer.". Throwing another exception for safety.
      LTGLCheck(@"Failed mapping buffer to memory");

      [LTGLException raise:kLTArrayBufferMappingFailedException
                    format:@"glMapBufferRangeEXT() returned NULL pointer"];
      return;
    }

    data = [NSData dataWithBytes:mappedBuffer length:self.size];

    if (!glUnmapBufferOES(self.type)) {
      // From OpenGL's documentation: "...In such situations, GL_FALSE is returned and the data
      // store contents are undefined. An application must detect this rare condition and
      // reinitialize the data store."

      // For now, throwing an exception here to notify this (rare) event happens.
      [LTGLException raise:kLTArrayBufferMappingFailedException
                    format:@"glUnmapBufferOES() returned GL_FALSE"];
    }
  }];

  return data;
}

- (void)createBufferWithSize:(GLsizeiptr)size {
  glBufferData(self.type, size, NULL, self.usage);
  LTGLCheckDbg(@"Error creating buffer with length: %d", self.size);
  self.size = size;
}

- (void)createBufferWithBufferData:(NSData *)data {
  glBufferData(self.type, data.length, data.bytes, self.usage);
  LTGLCheckDbg(@"Error creating buffer with data length: %d", data.length);
  self.size = data.length;
}

- (void)updateBufferWithMapping:(NSData *)data {
  GLvoid *mappedBuffer = glMapBufferOES(self.type, GL_WRITE_ONLY_OES);
  if (!mappedBuffer) {
    // OpenGL's documentation says: "If an error is generated, glMapBuffer returns NULL, and
    // glUnmapBuffer returns GL_FALSE.". Throwing another exception for safety.
    LTGLCheck(@"Failed mapping buffer to memory");

    [LTGLException raise:kLTArrayBufferMappingFailedException
                  format:@"glMapBufferOES() returned NULL pointer"];
    return;
  }
  memcpy(mappedBuffer, data.bytes, data.length);
  if (!glUnmapBufferOES(self.type)) {
    // From OpenGL's documentation: "...In such situations, GL_FALSE is returned and the data store
    // contents are undefined. An application must detect this rare condition and reinitialize the
    // data store."

    // For now, throwing an exception here to notify this (rare) event happens.
    [LTGLException raise:kLTArrayBufferMappingFailedException
                  format:@"glUnmapBufferOES() returned GL_FALSE"];
  }
}

#pragma mark -
#pragma mark Binding and unbinding
#pragma mark -

- (void)bind {
  if (self.bounded) {
    return;
  }

  switch (self.type) {
    case LTBufferArrayTypeGeneric:
      glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &_previousBuffer);
      break;
    case LTBufferArrayTypeElement:
      glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &_previousBuffer);
      break;
  }
  glBindBuffer(self.type, self.name);

  self.bounded = YES;
}

- (void)unbind {
  if (!self.bounded) {
    return;
  }

  glBindBuffer(self.type, _previousBuffer);

  self.previousBuffer = 0;
  self.bounded = NO;
}

- (void)bindAndExecute:(LTVoidBlock)block {
  [self bind];
  if (block) block();
  [self unbind];
}

@end
