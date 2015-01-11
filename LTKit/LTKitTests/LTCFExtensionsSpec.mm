// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCFExtensions.h"

SpecBegin(LTCFExtensions)

context(@"memory deallocation", ^{
  it(@"should release an existing reference", ^{
    UniChar character = 'a';
    CFMutableStringRef string = CFStringCreateMutableCopy(NULL, 0, CFSTR("abc"));
    CFTypeRef stringCopy = CFRetain(string);
    expect(string).toNot.equal(NULL);
    expect(stringCopy).toNot.equal(NULL);
    CFStringAppendCharacters(string, &character, 1);
    expect(CFGetRetainCount(string)).to.equal(2);
    expect(CFGetRetainCount(stringCopy)).to.equal(2);
    LTCFSafeRelease(string);
    expect(CFGetRetainCount(stringCopy)).to.equal(1);
    LTCFSafeRelease(stringCopy);
  });

  it(@"should set an existing reference to NULL", ^{
    UniChar character = 'a';
    CFMutableStringRef string = CFStringCreateMutableCopy(NULL, 0, CFSTR("abc"));
    CFStringAppendCharacters(string, &character, 1);
    LTCFSafeRelease(string);
    expect(string).to.beNil();
  });
  
  it(@"should silently ignore a NULL reference", ^{
    expect(^{
      CFTypeRef ref = NULL;
      LTCFSafeRelease(ref);
    }).notTo.raiseAny();
  });
});

SpecEnd
