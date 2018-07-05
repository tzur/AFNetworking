// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUStruct.h"

#pragma mark -
#pragma mark LTGPUStructField
#pragma mark -

@interface LTGPUStructField ()

@property (readwrite, nonatomic) NSString *name;
@property (readwrite, nonatomic) NSString *type;
@property (readwrite, nonatomic) size_t size;
@property (readwrite, nonatomic) size_t offset;
@property (readwrite, nonatomic) GLenum componentType;
@property (readwrite, nonatomic) GLint componentCount;

@end

@implementation LTGPUStructField

- (instancetype)initWithName:(NSString *)name type:(NSString *)type size:(size_t)size
         andOffset:(size_t)offset {
  if (self = [super init]) {
    self.name = name;
    self.type = type;
    self.size = size;
    self.offset = offset;
    self.componentType = [[self class] componentTypeForFieldType:self.type];
    self.componentCount = [[self class] componentCountForFieldType:self.type size:self.size];
  }
  return self;
}

- (BOOL)isEqual:(LTGPUStructField *)field {
  if (self == field) {
    return YES;
  }

  if (![field isKindOfClass:[LTGPUStructField class]]) {
    return NO;
  }

  return [self.name isEqualToString:field.name] && [self.type isEqualToString:field.type] &&
      self.size == field.size && self.offset == field.offset;
}

- (NSUInteger)hash {
  return self.name.hash ^ self.type.hash ^ self.size ^ self.offset;
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

@interface LTGPUStruct ()

@property (readwrite, nonatomic) NSString *name;
@property (readwrite, nonatomic) size_t size;
@property (readwrite, nonatomic) NSDictionary *fields;

@end

@implementation LTGPUStruct

- (instancetype)initWithName:(NSString *)name size:(size_t)size andFields:(NSArray *)fields {
  if (self = [super init]) {
    if (size % 4 != 0) {
      LogWarning(@"For best performance, struct size must be a multiple of 4 bytes");
    }

    self.name = name;
    self.size = size;

    // Create field.name -> field mapping.
    NSMutableDictionary *fieldsDict = [NSMutableDictionary dictionary];
    for (LTGPUStructField *field in fields) {
      fieldsDict[field.name] = field;
    }
    self.fields = fieldsDict;
  }
  return self;
}

- (BOOL)isEqual:(LTGPUStruct *)gpuStruct {
  if (self == gpuStruct) {
    return YES;
  }

  if (![gpuStruct isKindOfClass:[LTGPUStruct class]]) {
    return NO;
  }

  return [self.name isEqualToString:gpuStruct.name] && self.size == gpuStruct.size &&
      [self.fields isEqualToDictionary:gpuStruct.fields];
}

- (NSUInteger)hash {
  return self.name.hash ^ self.size ^ self.fields.hash;
}

@end

#pragma mark -
#pragma mark LTGPUStructRegistry
#pragma mark -

@interface LTGPUStructRegistry ()

/// Maps between struct name (\c NSString) to its corresponding \c LTGPUStruct object.
@property (strong, nonatomic) NSMutableDictionary *structs;

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
