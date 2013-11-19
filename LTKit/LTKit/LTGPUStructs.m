// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUStructs.h"

NSString * const kLTGPUStructMemberName = @"name";
NSString * const kLTGPUStructMemberOffset = @"offset";
NSString * const kLTGPUStructMemberType = @"type";
NSString * const kLTGPUStructMemberTypeSize = @"type_size";

@interface LTGPUStructs ()
/// Maps between struct name (\c NSString) to \c NSArray of struct members, where each member is an
/// \c NSDictionary.
@property (strong, nonatomic) NSMutableDictionary *structs;
@end

@implementation LTGPUStructs

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (id)init {
  if (self = [super init]) {
    self.structs = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark -
#pragma mark Class methods
#pragma mark -

+ (instancetype)sharedInstance {
  static LTGPUStructs *instance = nil;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[LTGPUStructs alloc] init];
  });

  return instance;
}

#pragma mark -
#pragma mark Instance methods
#pragma mark -

- (void)registerStructNamed:(NSString *)name ofSize:(size_t __unused)size
                    members:(NSArray *)members {
  LTAssert(!self.structs[name], @"Tried to register struct '%@', which is already registered",
           name);

  self.structs[name] = members;
}

- (NSArray *)structMembersForName:(NSString *)name {
  return self.structs[name];
}

@end
