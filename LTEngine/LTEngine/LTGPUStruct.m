// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUStruct.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark LTGPUStructField
#pragma mark -

@implementation LTGPUStructField

- (instancetype)initWithName:(NSString *)name type:(NSString *)type size:(size_t)size
                   andOffset:(size_t)offset {
  return [self  initWithName:name type:type size:size offset:offset normalized:NO];
}

- (instancetype)initWithName:(NSString *)name type:(NSString *)type size:(size_t)size
                      offset:(size_t)offset normalized:(BOOL)normalized {
  if (self = [super init]) {
    _name = name;
    _type = type;
    _size = size;
    _offset = offset;
    _normalized = normalized;
    _componentType = [[self class] componentTypeForFieldType:self.type];
    _componentCount = [[self class] componentCountForFieldType:self.type size:self.size];
  }
  return self;
}

+ (GLenum)componentTypeForFieldType:(NSString *)type {
  if ([type isEqualToString:@"float"] ||
      [type isEqualToString:@"GLKVector2"] ||
      [type isEqualToString:@"GLKVector3"] ||
      [type isEqualToString:@"GLKVector4"] ||
      [type isEqualToString:@"LTVector2"] ||
      [type isEqualToString:@"LTVector3"] ||
      [type isEqualToString:@"LTVector4"]) {
    return GL_FLOAT;
  } else if ([type isEqualToString:@"GLbyte"]) {
    return GL_BYTE;
  } else if ([type isEqualToString:@"GLshort"]) {
    return GL_SHORT;
  } else if ([type isEqualToString:@"GLubyte"]) {
    return GL_UNSIGNED_BYTE;
  } else if ([type isEqualToString:@"GLushort"]) {
    return GL_UNSIGNED_SHORT;
  }

  [NSException raise:NSInternalInconsistencyException
              format:@"Given type '%@' is not supported as a GPU struct field", type];
  __builtin_unreachable();
}

+ (GLint)componentCountForFieldType:(NSString *)type size:(size_t)size {
  switch ([[self class] componentTypeForFieldType:type]) {
    case GL_BYTE:
      return (GLint)(size / sizeof(GLbyte));
    case GL_FLOAT:
      return (GLint)(size / sizeof(GLfloat));
    case GL_SHORT:
      return (GLint)(size / sizeof(GLshort));
    case GL_UNSIGNED_BYTE:
      return (GLint)(size / sizeof(GLubyte));
    case GL_UNSIGNED_SHORT:
      return (GLint)(size / sizeof(GLushort));
  }

  [NSException raise:NSInternalInconsistencyException
              format:@"Given type '%@' is not supported as a GPU struct field", type];
  __builtin_unreachable();
}

@end

#pragma mark -
#pragma mark LTGPUStruct
#pragma mark -

@implementation LTGPUStruct

- (instancetype)initWithName:(NSString *)name size:(size_t)size
                   andFields:(NSArray<LTGPUStructField *> *)fields {
  if (self = [super init]) {
    if (size % 4 != 0) {
      LogWarning(@"For best performance, struct size must be a multiple of 4 bytes");
    }

    _name = name;
    _size = size;

    // Create field.name -> field mapping.
    NSMutableDictionary<NSString *, LTGPUStructField *> *fieldsDict =
        [NSMutableDictionary dictionary];
    for (LTGPUStructField *field in fields) {
      fieldsDict[field.name] = field;
    }
    _fields = fieldsDict;
  }
  return self;
}

@end

#pragma mark -
#pragma mark LTGPUStructRegistry
#pragma mark -

@interface LTGPUStructRegistry ()

/// Maps between struct name (\c NSString) to its corresponding \c LTGPUStruct object.
@property (strong, nonatomic) NSMutableDictionary<NSString *, LTGPUStruct *> *structs;

@end

@implementation LTGPUStructRegistry

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    self.structs = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark -
#pragma mark Class methods
#pragma mark -

+ (instancetype)sharedInstance {
  static LTGPUStructRegistry *instance = nil;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[LTGPUStructRegistry alloc] init];
  });

  return instance;
}

#pragma mark -
#pragma mark Instance methods
#pragma mark -

- (void)registerStruct:(LTGPUStruct *)gpuStruct {
  LTAssert(!self.structs[gpuStruct.name],
           @"Tried to register struct '%@' which is already registered", gpuStruct.name);

  self.structs[gpuStruct.name] = gpuStruct;
}

- (LTGPUStruct *)structForName:(NSString *)name {
  return self.structs[name];
}

@end

NS_ASSUME_NONNULL_END
