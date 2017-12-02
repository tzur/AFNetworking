// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "TINMessage.h"

#import "NSURL+TinCan.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kTINAppGroupID = @"group.com.lightricks.TinCan";

@implementation TINMessage

- (instancetype)initWithAppGroupID:(NSString *)appGroupID sourceScheme:(NSString *)sourceScheme
                      targetScheme:(NSString *)targetScheme identifier:(NSUUID *)identifier
                          userInfo:(NSDictionary<NSString *, id<NSSecureCoding>> *)info {
  if (self = [super init]) {
    _appGroupID = appGroupID;
    _sourceScheme = sourceScheme;
    _targetScheme = targetScheme;
    _identifier = identifier;
    _userInfo = info;
  }
  return self;
}

+ (instancetype)messageWithAppGroupID:(NSString *)appGroupID sourceScheme:(NSString *)sourceScheme
                         targetScheme:(NSString *)targetScheme identifier:(NSUUID *)identifier
                             userInfo:(NSDictionary<NSString *, id<NSSecureCoding>> *)info {
  return [[self alloc] initWithAppGroupID:appGroupID sourceScheme:sourceScheme
                             targetScheme:targetScheme identifier:identifier userInfo:info];
}

#pragma mark -
#pragma mark NSSecureCoding
#pragma mark -

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.appGroupID forKey:@keypath(self, appGroupID)];
  [coder encodeObject:self.sourceScheme forKey:@keypath(self, sourceScheme)];
  [coder encodeObject:self.targetScheme forKey:@keypath(self, targetScheme)];
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
    NSUUID * _Nullable identifier = [decoder decodeObjectOfClass:NSUUID.class
                                                          forKey:@keypath(self, identifier)];
    NSDictionary * _Nullable userInfo = [decoder decodeObjectOfClass:NSDictionary.class
                                                              forKey:@keypath(self, userInfo)];
    if (!appGroupID || !sourceScheme || !targetScheme || !identifier || !userInfo) {
      return nil;
    }

    _appGroupID = nn(appGroupID);
    _sourceScheme = nn(sourceScheme);
    _targetScheme = nn(targetScheme);
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
