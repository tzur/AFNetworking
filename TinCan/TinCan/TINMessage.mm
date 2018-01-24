// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "TINMessage.h"

#import <LTKit/LTBidirectionalMap.h>

#import "NSURL+TinCan.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kTINAppGroupID = @"group.com.lightricks.TinCan";

/// Supported \c TINMessage types.
LTEnumImplement(NSUInteger, TINMessageType,
  /// Request message type.
  TINMessageTypeRequest,
  /// Response message type.
  TINMessageTypeResponse
);

#pragma mark -
#pragma mark TINMessageType+ValueTransformer
#pragma mark -

/// Category augmenting \c TINMessageType by adding value transformation capabilities.
@interface TINMessageType (ValueTransformer)

/// Initializes with the given transformed \c messageTypeString. Returns \c nil if there is no
/// corresponding \c TINMessageType for the given \c messageTypeString.
- (nullable instancetype)initWithMessageTypeString:(NSString *)messageTypeString;

/// Returns transformed \c NSString representation of an instance.
- (NSString *)messageTypeString;

@end

@implementation TINMessageType (ValueTransformer)

- (nullable instancetype)initWithMessageTypeString:(NSString *)messageTypeString {
  if ([messageTypeString isEqual:@"request"]) {
    return [self initWithValue:TINMessageTypeRequest];
  } else if ([messageTypeString isEqual:@"response"]) {
    return [self initWithValue:TINMessageTypeResponse];
  }
  return nil;
}

- (NSString *)messageTypeString {
  switch (self.value) {
    case TINMessageTypeRequest:
      return @"request";
    case TINMessageTypeResponse:
      return @"response";
  }
}

@end

#pragma mark -
#pragma mark TINMessage
#pragma mark -

@implementation TINMessage

- (instancetype)initWithAppGroupID:(NSString *)appGroupID sourceScheme:(NSString *)sourceScheme
                      targetScheme:(NSString *)targetScheme type:(TINMessageType *)type
                            action:(NSString *)action identifier:(NSUUID *)identifier
                          userInfo:(NSDictionary<NSString *, id<NSSecureCoding>> *)info {
  if (self = [super init]) {
    _appGroupID = appGroupID;
    _sourceScheme = sourceScheme;
    _targetScheme = targetScheme;
    _type = type;
    _action = action;
    _identifier = identifier;
    _userInfo = info;
  }
  return self;
}

+ (instancetype)messageWithAppGroupID:(NSString *)appGroupID sourceScheme:(NSString *)sourceScheme
                         targetScheme:(NSString *)targetScheme type:(TINMessageType *)type
                               action:(NSString *)action identifier:(NSUUID *)identifier
                             userInfo:(NSDictionary<NSString *, id<NSSecureCoding>> *)info {
  return [[self alloc] initWithAppGroupID:appGroupID sourceScheme:sourceScheme
                             targetScheme:targetScheme type:type action:action identifier:identifier
                                 userInfo:info];
}

#pragma mark -
#pragma mark NSSecureCoding
#pragma mark -

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.appGroupID forKey:@keypath(self, appGroupID)];
  [coder encodeObject:self.sourceScheme forKey:@keypath(self, sourceScheme)];
  [coder encodeObject:self.targetScheme forKey:@keypath(self, targetScheme)];
  [coder encodeObject:self.type.messageTypeString forKey:@keypath(self, type)];
  [coder encodeObject:self.action forKey:@keypath(self, action)];
  [coder encodeObject:self.identifier forKey:@keypath(self, identifier)];
  [coder encodeObject:self.userInfo forKey:@keypath(self, userInfo)];
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
  if (self = [super init]) {
    NSString * _Nullable appGroupID = [decoder decodeObjectOfClass:NSString.class
                                                            forKey:@keypath(self, appGroupID)];
    NSString * _Nullable sourceScheme = [decoder decodeObjectOfClass:NSString.class
                                                              forKey:@keypath(self, sourceScheme)];
    NSString * _Nullable targetScheme = [decoder decodeObjectOfClass:NSString.class
                                                              forKey:@keypath(self, targetScheme)];
    NSString * _Nullable typeString = [decoder decodeObjectOfClass:NSString.class
                                                            forKey:@keypath(self, type)];
    NSString * _Nullable action = [decoder decodeObjectOfClass:NSString.class
                                                        forKey:@keypath(self, action)];
    NSUUID * _Nullable identifier = [decoder decodeObjectOfClass:NSUUID.class
                                                          forKey:@keypath(self, identifier)];
    NSDictionary * _Nullable userInfo = [decoder decodeObjectOfClass:NSDictionary.class
                                                              forKey:@keypath(self, userInfo)];

    if (!appGroupID || !sourceScheme || !targetScheme || !typeString || !action || !identifier ||
        !userInfo) {
      return nil;
    }

    auto _Nullable type = [[TINMessageType alloc] initWithMessageTypeString:nn(typeString)];
    if (!type) {
      return nil;
    }

    _appGroupID = nn(appGroupID);
    _sourceScheme = nn(sourceScheme);
    _targetScheme = nn(targetScheme);
    _type = nn(type);
    _action = nn(action);
    _identifier = nn(identifier);
    _userInfo = nn(userInfo);
  }
  return self;
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end

#pragma mark -
#pragma mark TINMessage+NSURL
#pragma mark -

NSString * const kTINMessageFileName = @".tincan";

@implementation TINMessage (NSURL)

- (nullable NSURL *)directoryURL {
  return [NSURL tin_messageDirectoryURLWithAppGroup:self.appGroupID scheme:self.targetScheme
                                         identifier:self.identifier];
}

- (nullable NSURL *)url {
  return [self.directoryURL URLByAppendingPathComponent:kTINMessageFileName];
}

@end

NS_ASSUME_NONNULL_END
