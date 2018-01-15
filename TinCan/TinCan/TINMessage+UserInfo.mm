// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "TINMessage+UserInfo.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TINMessage (UserInfo)

NSString * const kTINMessageFileNamesKey = @"TINMessageFileNames";

- (nullable NSArray<NSString *> *)fileNames {
  return (NSArray<NSString *> * _Nullable)[self.userInfo objectForKey:kTINMessageFileNamesKey];
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

@end

NS_ASSUME_NONNULL_END
