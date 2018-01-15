// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "NSURL+TinCan.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSURL (TinCan)

+ (nullable NSURL *)tin_messageDirectoryURLWithAppGroup:(NSString *)appGroupID
                                                 scheme:(NSString *)scheme
                                             identifier:(NSUUID *)identifier {
  auto _Nullable schemeDirectory = [NSURL tin_messagesDirectoryURLWithAppGroup:appGroupID
                                                                        scheme:scheme];
  return [schemeDirectory URLByAppendingPathComponent:identifier.UUIDString isDirectory:YES];
}

+ (nullable NSURL *)tin_messagesDirectoryURLWithAppGroup:(NSString *)appGroupID
                                                  scheme:(NSString *)scheme {
  auto _Nullable sharedDirectory = [self tin_appGroupDirectoryURL:appGroupID];
  return [sharedDirectory URLByAppendingPathComponent:scheme isDirectory:YES];
}

+ (nullable NSURL *)tin_appGroupDirectoryURL:(NSString *)appGroupID {
  return [[NSFileManager defaultManager]
          containerURLForSecurityApplicationGroupIdentifier:appGroupID];
}

@end

NS_ASSUME_NONNULL_END
