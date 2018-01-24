// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "TINMessage+UserInfo.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TINMessage (UserInfo)

NSString * const kTINMessageFileNamesKey = @"TINMessageFileNames";
NSString * const kTINMessageContextKey = @"TINMessageContext";

- (nullable NSArray<NSString *> *)fileNames {
  auto fileNames = (NSArray<NSString *> * _Nullable)self.userInfo[kTINMessageFileNamesKey];
  return [fileNames isKindOfClass:NSArray.class] ? fileNames : nil;
}

- (nullable NSArray<NSURL *> *)fileURLs {
  if (!self.fileNames) {
    return nil;
  }

  auto fileURLs = [NSMutableArray arrayWithCapacity:self.fileNames.count];
  for (NSString *fileName in self.fileNames) {
    if (fileName.isAbsolutePath) {
      return nil;
    }

    auto _Nullable fileURL = [self.directoryURL URLByAppendingPathComponent:nn(fileName)];
    if (!fileURL) {
      return nil;
    }

    if (![fileURL.path.stringByStandardizingPath
          hasPrefix:nn(self.directoryURL.path.stringByStandardizingPath)]) {
      return nil;
    }
    [fileURLs addObject:nn(fileURL)];
  }

  return [fileURLs copy];
}

- (nullable NSDictionary<NSString *, id<NSSecureCoding>> *)context {
  auto context = (NSDictionary<NSString *, id<NSSecureCoding>> * _Nullable)
      self.userInfo[kTINMessageContextKey];
  return [context isKindOfClass:NSDictionary.class] ? context : nil;
}

@end

NS_ASSUME_NONNULL_END
