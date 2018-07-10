// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/LTValueObject.h>

#import "LTGPUStructsMacros.h"

NS_ASSUME_NONNULL_BEGIN

/// Holds data about a single member of a GPU struct.
@interface LTGPUStructField : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given field \c name, serialized \c type, \c size in bytes, and the
/// \c offset in the struct.
- (instancetype)initWithName:(NSString *)name type:(NSString *)type size:(size_t)size
                   andOffset:(size_t)offset;

/// Initializes with the given field \c name, serialized \c type, \c size in bytes, the \c offset in
/// the struct, and the \c normalized indication.
- (instancetype)initWithName:(NSString *)name type:(NSString *)type size:(size_t)size
                      offset:(size_t)offset normalized:(BOOL)normalized NS_DESIGNATED_INITIALIZER;

/// Name of the field.
@property (readonly, nonatomic) NSString *name;

/// Type of the field, as string.
@property (readonly, nonatomic) NSString *type;

/// Size of the field in bytes.
@property (readonly, nonatomic) size_t size;

/// Offset of the field in the struct.
@property (readonly, nonatomic) size_t offset;

/// \c YES if this field is normalized. Can be ignored if the \c type of this instance specifies a
/// floating-point type.
@property (readonly, nonatomic) BOOL normalized;

/// OpenGL component type (such as \c GL_FLOAT, \c GL_UNSIGNED_SHORT) matching the field's \c type.
@property (readonly, nonatomic) GLenum componentType;

/// OpenGL number of components (will be in the range [1, 4]).
@property (readonly, nonatomic) GLint componentCount;

@end

/// Value object holding data about a struct that can be placed on the GPU.
@interface LTGPUStruct : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given struct \c name, \c size in bytes, and \c fields.
- (instancetype)initWithName:(NSString *)name size:(size_t)size
                   andFields:(NSArray<LTGPUStructField *> *)fields NS_DESIGNATED_INITIALIZER;

/// Name of the struct.
@property (readonly, nonatomic) NSString *name;

/// Size of the struct in bytes.
@property (readonly, nonatomic) size_t size;

/// Dictionary of field name to its corresponding \c LTGPUStructField object.
@property (readonly, nonatomic) NSDictionary<NSString *, LTGPUStructField *> *fields;

@end

/// Registry of all structs that need to be represented on the GPU using LTKit.
@interface LTGPUStructRegistry : NSObject

/// Retrieves the singleton instance.
+ (instancetype)sharedInstance;

/// Registers a GPU struct in the repository.
- (void)registerStruct:(LTGPUStruct *)gpuStruct;

/// Returns struct field information for the given struct name. If the struct doesn't exist in the
/// repository, \c nil is returned.
- (LTGPUStruct *)structForName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
