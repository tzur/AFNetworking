// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUStructsMacros.h"

/// Dictionary key for struct member name.
extern NSString * const kLTGPUStructMemberName;
/// Dictionary key for struct member offset.
extern NSString * const kLTGPUStructMemberOffset;
/// Dictionary key for struct member type name.
extern NSString * const kLTGPUStructMemberType;
/// Dictionary key for struct member type size.
extern NSString * const kLTGPUStructMemberTypeSize;

/// @class LTGPUStructs
///
/// Repository for registration of all structs that should be represented on the GPU.
@interface LTGPUStructs : NSObject

/// Retrieves the singleton instance.
+ (instancetype)sharedInstance;

/// Registers a struct in the repository.
///
/// @param name name of the struct.
/// @param size size of the struct, in bytes.
/// @param members an array of dictionaries. Each dictionary should contain the following keys:
/// \c kLTGPUStructMemberName: member name, \c kLTGPUStructMemberOffset: offset in struct, \c
/// kLTGPUStructMemberType: member type name (string), \c kLTGPUStructMemberTypeSize: member type
/// size. The array should be ordered in the order of the struct's member declaration.
- (void)registerStructNamed:(NSString *)name ofSize:(size_t)size members:(NSArray *)members;

/// Returns struct members information for the given struct name. If the struct doesn't exist in the
/// repository, \c nil is returned.  The returned dictionary includes the \c kLTGPUStructMember*
/// keys.
- (NSArray *)structMembersForName:(NSString *)name;

@end
