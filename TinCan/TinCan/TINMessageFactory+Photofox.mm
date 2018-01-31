// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "TINMessageFactory+Photofox.h"

#import "TINMessage+UserInfo.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kTINPhotofoxImageEditAction = @"TINPhotofoxImageEditAction";
NSString * const kTINPhotofoxScheme = @"tincan-photofox";

@implementation TINMessageFactory (Photofox)

- (nullable TINMessage *)en_imageEditingRequestWithData:(NSData *)data uti:(NSString *)uti
                                                context:(id<NSSecureCoding>)context
                                         appDisplayName:(NSString *)appDisplayName
                                                  error:(NSError * __autoreleasing *)error {
  auto userInfo = @{
    kTINMessageAppDisplayName: appDisplayName,
    kTINMessageContextKey: context
  };

  return [self messageWithTargetScheme:kTINPhotofoxScheme type:$(TINMessageTypeRequest)
                                action:kTINPhotofoxImageEditAction userInfo:userInfo
                                  data:data uti:uti error:error];
}

@end

@implementation TINMessage (Photofox)

- (nullable NSString *)en_appDisplayName {
  auto displayName = (NSString * _Nullable)self.userInfo[kTINMessageAppDisplayName];
  return [displayName isKindOfClass:NSString.class] ? displayName : nil;
}

@end

NS_ASSUME_NONNULL_END
