// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCFExtensions.h"

SpecBegin(LTCFExtensions)

context(@"memory deallocation", ^{
  it(@"should release an existing reference", ^{
    UniChar character = 'a';
    CFMutableStringRef string = CFStringCreateMutableCopy(NULL, 0, CFSTR("abc"));
    CFStringAppendCharacters(string, &character, 1);
    expect(string).toNot.equal(NULL);
    LTCFSafeRelease(string);
    expect(^{
      CFStringAppendCharacters(string, &character, 1);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should silently ignore a NULL reference", ^{
    expect(^{
      LTCFSafeRelease(NULL);
    }).notTo.raiseAny();
  });
});

SpecEnd
