// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSFileManagerTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

id LTCreateFakeURL(NSString *name) {
  id url = OCMClassMock([NSURL class]);
  OCMStub([url getResourceValue:[OCMArg setTo:name]
                         forKey:NSURLNameKey
                          error:[OCMArg anyObjectRef]]).andReturn(YES);
  return url;
}

id LTCreateFakeURLWithError(NSError *error) {
  id url = OCMClassMock([NSURL class]);
  OCMStub([url getResourceValue:[OCMArg setTo:nil]
                         forKey:NSURLNameKey
                          error:[OCMArg setTo:error]]).andReturn(NO);
  return url;
}

void LTStubFileManager(id fileManager, NSURL *path, BOOL recursive, NSArray<NSURL *> *files) {
  NSUInteger options = recursive ? 0 : NSDirectoryEnumerationSkipsSubdirectoryDescendants;
  OCMStub([fileManager enumeratorAtURL:path includingPropertiesForKeys:OCMOCK_ANY
                               options:options
                          errorHandler:OCMOCK_ANY]).andReturn(files);
}

void LTStubFileManagerWithError(id fileManager, NSURL *path, BOOL recursive,
                                NSArray<NSURL *> *files, NSError *error) {
  NSUInteger options = recursive ? 0 : NSDirectoryEnumerationSkipsSubdirectoryDescendants;
  OCMStub([fileManager enumeratorAtURL:path includingPropertiesForKeys:OCMOCK_ANY
                               options:options
                          errorHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained BOOL (^errorHandler)(NSURL *url, NSError *error);
    [invocation getArgument:&errorHandler atIndex:5];

    for (NSURL *file in files) {
      errorHandler(file, error);
    }
  });
}

NS_ASSUME_NONNULL_END
