// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTArrayBuffer.h"

#import "LTGLException.h"

@interface LTArrayBuffer ()

@property (readwrite, nonatomic) GLuint name;

/// OpenGL usage type of the buffer.
@property (readwrite, nonatomic) LTArrayBufferUsage usage;

/// Type of the buffer array.
@property (readwrite, nonatomic) LTArrayBufferType type;

/// Current size of the buffer.
@property (readwrite, nonatomic) NSUInteger size;

/// YES if the buffer is currently bound.
@property (nonatomic) BOOL bound;

/// Set to the previously bound buffer, or \c 0 if the buffer is not bound.
@property (nonatomic) GLint previousBuffer;

@end

@implementation LTArrayBuffer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (id)initWithType:(LTArrayBufferType)type usage:(LTArrayBufferUsage)usage {
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
  [self unbind];
  glDeleteBuffers(1, &_name);
  LTGLCheckDbg(@"Failed to delete buffer: %d", _name);
}

#pragma mark -
#pragma mark Buffer update
#pragma mark -

- (void)setData:(NSData *)data {
  [self setDataWithConcatenatedData:@[data]];
}

- (void)setDataWithConcatenatedData:(NSArray *)dataArray {
  // Do not update to zero length.
  NSUInteger totalLength = [self lengthOfDataInArray:dataArray];
  if (!totalLength) {
    return;
  }

  [self bindAndExecute:^{
    switch (self.usage) {
      case LTArrayBufferUsageStaticDraw:
        // Static buffers allow only initial update.
        if (self.size) {
          [LTGLException raise:kLTArrayBufferDisallowsStaticBufferUpdateException
                        format:@"Tried to update a GL_STATIC_DRAW buffer"];
        };
        [self createBufferWithBufferData:[self concatenatedData:dataArray]];
        break;
      case LTArrayBufferUsageDynamicDraw:
        // Dynamic buffers updates buffer if the data has the same size, and creates a new one for
        // different size.
        if (self.size != totalLength) {
          [self createBufferWithBufferData:[self concatenatedData:dataArray]];
        } else {
          [self createBufferWithSize:totalLength];
          [self updateBufferWithMapping:dataArray];
        }
        break;
      case LTArrayBufferUsageStreamDraw:
        // Stream buffers creates a new buffer for each update.
        [self createBufferWithSize:totalLength];
        [self updateBufferWithMapping:dataArray];
        break;
    }
  }];
}

- (NSUInteger)lengthOfDataInArray:(NSArray *)dataArray {
  return [[dataArray valueForKeyPath:@"@sum.length"] unsignedIntegerValue];
}

- (NSData *)concatenatedData:(NSArray *)dataArray {
  if (dataArray.count == 1) {
    return dataArray.firstObject;
  }
  
  NSMutableData *result = [NSMutableData dataWithCapacity:[self lengthOfDataInArray:dataArray]];
  for (NSData *data in dataArray) {
    [result appendData:data];
  }
  return result;
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
  LTGLCheckDbg(@"Error creating buffer with length: %lu", (unsigned long)self.size);
  self.size = size;
}

- (void)createBufferWithBufferData:(NSData *)data {
  glBufferData(self.type, data.length, data.bytes, self.usage);
  LTGLCheckDbg(@"Error creating buffer with data length: %lu", (unsigned long)data.length);
  self.size = data.length;
}

- (void)updateBufferWithMapping:(NSArray *)dataArray {
  char *mappedBuffer = (char *)glMapBufferOES(self.type, GL_WRITE_ONLY_OES);
  if (!mappedBuffer) {
    // OpenGL's documentation says: "If an error is generated, glMapBuffer returns NULL, and
    // glUnmapBuffer returns GL_FALSE.". Throwing another exception for safety.
    LTGLCheck(@"Failed mapping buffer to memory");

    [LTGLException raise:kLTArrayBufferMappingFailedException
                  format:@"glMapBufferOES() returned NULL pointer"];
    return;
  }
  
  NSUInteger offset = 0;
  for (NSData *data in dataArray) {
    memcpy(mappedBuffer + offset, data.bytes, data.length);
    offset += data.length;
  }
  
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
  if (self.bound) {
    return;
  }

  switch (self.type) {
    case LTArrayBufferTypeGeneric:
      glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &_previousBuffer);
      break;
    case LTArrayBufferTypeElement:
      glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &_previousBuffer);
      break;
  }
  glBindBuffer(self.type, self.name);

  self.bound = YES;
}

- (void)unbind {
  if (!self.bound) {
    return;
  }

  glBindBuffer(self.type, _previousBuffer);

  self.previousBuffer = 0;
  self.bound = NO;
}

- (void)bindAndExecute:(LTVoidBlock)block {
  LTParameterAssert(block);
  if (self.bound) {
    block();
  } else {
    [self bind];
    block();
    [self unbind];
  }
}

@end
