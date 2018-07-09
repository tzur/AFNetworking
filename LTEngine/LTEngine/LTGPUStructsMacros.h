// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/LTMetaMacros.h>

/// Avoid including this file directly. To use these macros, include \c LTGPUStructs.h.

/// Prints a member of a struct.
#define _LTStructMember(CONTEXT, TYPE, MEMBER, ...) \
    TYPE MEMBER; \

/// Prints a GPU struct field for \c LTGPUStructs.
#define _LTStructDict(STRUCT, TYPE, MEMBER) \
    [[LTGPUStructField alloc] initWithName:@#MEMBER type:@#TYPE size:sizeof(TYPE) \
                                 andOffset:__builtin_offsetof(STRUCT, MEMBER)]

/// Prints a GPU struct field with normalization indication for \c LTGPUStructs.
#define _LTGPUStructFieldNormalized(STRUCT, TYPE, MEMBER, NORMALIZED) \
    [[LTGPUStructField alloc] initWithName:@#MEMBER type:@#TYPE size:sizeof(TYPE) \
                                    offset:__builtin_offsetof(STRUCT, MEMBER) \
                                normalized:NORMALIZED]

/// Declares a struct that can be placed on the GPU using \c LTVertexArray without implementing it.
/// This should be used in the header file when the same struct is shared between multiple classes.
///
/// @see LTGPUStructMake
#define LTGPUStructDeclare(STRUCT, ...) \
  typedef struct { \
    metamacro_foreach2(_LTStructMember,, _LTNull, __VA_ARGS__) \
  } STRUCT; \

/// Declares a struct that can be placed on the GPU using \c LTVertexArray without implementing it.
/// This should be used in the header file when the same struct is shared between multiple classes.
///
/// @see LTGPUStructMake
#define _LTGPUStructDeclareNormalized(STRUCT, ...) \
  typedef struct { \
    metamacro_foreach3(_LTStructMember,, _LTNull, __VA_ARGS__) \
  } STRUCT; \

/// Implements a struct that can be placed on the GPU using \c LTVertexArray.
/// This should be used inside one (and only one) of the classes using the shared struct.
///
/// @see LTGPUStructMake
#define LTGPUStructImplement(STRUCT, ...) \
  __attribute__((constructor)) static void __register##STRUCT() { \
    [[LTGPUStructRegistry sharedInstance] \
        registerStruct:[[LTGPUStruct alloc] initWithName:@#STRUCT size:sizeof(STRUCT) \
             andFields:@[metamacro_foreach2(_LTStructDict, STRUCT, _LTComma, __VA_ARGS__)]]]; \
  }

/// Implements a struct that can be placed on the GPU using \c LTVertexArray.
/// This should be used inside one (and only one) of the classes using the shared struct.
///
/// @see LTGPUStructMake
#define LTGPUStructImplementNormalized(STRUCT, ...) \
  __attribute__((constructor)) static void __register##STRUCT() { \
    [[LTGPUStructRegistry sharedInstance] \
        registerStruct:[[LTGPUStruct alloc] initWithName:@#STRUCT size:sizeof(STRUCT) \
             andFields:@[metamacro_foreach3(_LTGPUStructFieldNormalized, STRUCT, _LTComma, \
                                            __VA_ARGS__)]]]; \
  }

/// Defines a struct that can be placed on the GPU using \c LTVertexArray. The first given parameter
/// is the struct name. Struct member follows, with the member type first, then its name. Example:
/// @code
/// LTGPUStructMake(MyStruct,
///                 LTVector2, position,
///                 LTVector4, color,
///                 float, intensity);
/// @endcode
///
/// Structs are defined globally, even if their scope is limited. Avoid defining a struct with a
/// similar name twice.
///
/// @note beware from alignment constraints when creating structs. For example, \c LTVector4 is
/// 16-byte aligned. Usually, this is not required in such structs. Therefore, consider using
/// #pragma pack(n) to reduce the total size of the struct.
#define LTGPUStructMake(STRUCT, ...) \
  LTGPUStructDeclare(STRUCT, __VA_ARGS__) \
  LTGPUStructImplement(STRUCT, __VA_ARGS__)

/// Defines a struct with normalization indications that can be placed on the GPU using
/// \c LTVertexArray. The first given parameter is the struct name. Struct member follows, with the
/// member type first, then its name, and finally its normalization indication. Example:
/// @code
/// LTGPUStructMakeNormalized(MyStruct,
///                           LTVector2, position, NO,
///                           LTVector4, color, NO,
///                           GLubyte, intensity, YES);
/// @endcode
///
/// Structs are defined globally, even if their scope is limited. Avoid defining a struct with a
/// similar name twice.
///
/// @note beware from alignment constraints when creating structs. For example, \c LTVector4 is
/// 16-byte aligned. Usually, this is not required in such structs. Therefore, consider using
/// #pragma pack(n) to reduce the total size of the struct.
#define LTGPUStructMakeNormalized(STRUCT, ...) \
  _LTGPUStructDeclareNormalized(STRUCT, __VA_ARGS__) \
  LTGPUStructImplementNormalized(STRUCT, __VA_ARGS__)
