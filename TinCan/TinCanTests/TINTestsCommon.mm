// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "TINTestsCommon.h"

#import "NSURL+TinCan.h"
#import "TINMessage+UserInfo.h"

NS_ASSUME_NONNULL_BEGIN

/// TestHost's application group ID, used in specs.
NSString * const kTINTestHostAppGroupID = @"group.com.lightricks.TestHost";

void TINCleanupTestHostAppGroupDirectory() {
  auto _Nullable url = [NSURL tin_appGroupDirectoryURL:kTINTestHostAppGroupID];
  if (!url) {
    return;
  }
  LTAssert(url.path, @"Failed obtaining the path of url: %@", url);

  auto fileManager = [NSFileManager defaultManager];
  NSError *error;
  for (NSString *itemName in [fileManager contentsOfDirectoryAtPath:nn(url.path) error:&error]) {
    auto _Nullable itemURL = [url URLByAppendingPathComponent:itemName];
    LTAssert(itemURL, @"Failed appending: %@ to url: %@", itemName, url);
    auto success = [fileManager removeItemAtURL:nn(itemURL) error:&error];
    LTAssert(success && !error, @"Error: %@ when removing item: %@", error, itemURL);
  }
}

NS_ASSUME_NONNULL_END
