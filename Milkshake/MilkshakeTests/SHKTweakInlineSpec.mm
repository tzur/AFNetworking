// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SHKTweakInline.h"

#import <Specta/SpectaUtility.h>

/// Dummy object to be used in testing property binding.
@interface SHKTweakTestObject : NSObject

/// Dummy property to test tweak binding to.
@property (strong, nonatomic) id property;

@end

@implementation SHKTweakTestObject
@end

/// Used as global boolean flag to state if a certain condition occured.
@interface SHKGlobalFlag : NSObject

/// The singleton instance of this object.
+ (instancetype)sharedFlag;

/// Boolean flag to be set to \c YES to signal that in the current test case that a condition is
/// true. Returns \c YES if this flag was set to \c YES in this test case, \c NO otherwise.
@property (nonatomic) BOOL flag;

@end

@implementation SHKGlobalFlag {
  /// Contains the last test case that set \c flag to \c YES. Is \c nil if flag was set to \c no, or
  /// if \c flag was never set to \c YES.
  NSString * _Nullable _currentTestCase;
}

+ (instancetype)sharedFlag {
  static auto sharedInstance = [[SHKGlobalFlag alloc] init];
  return sharedInstance;
}

- (BOOL)flag {
  return [_currentTestCase isEqualToString:[SPTCurrentSpec description]];
}

- (void)setFlag:(BOOL)flag {
  _currentTestCase = flag ? [SPTCurrentSpec description] : nil;
}

@end

/// Returns the unique identifier for an \c FBTweak object with \c name, in \c collection inside
/// \c category.
static NSString *SHKTweakIdentifier(NSString *category, NSString *collection, NSString *name) {
  return [NSString stringWithFormat:@"FBTweak:%@-%@-%@", category, collection, name];
}

/// Searches and returns the global Tweak store for the \c FBTweak object with \c name, in
/// \c collection inside \c category. Returns \c nil if not such object exist.
static id<FBTweak> SHKFindTweak(NSString *category, NSString *collection, NSString *name) {
  auto identifier = SHKTweakIdentifier(category, collection, name);
  return [[[[FBTweakStore sharedInstance] tweakCategoryWithName:category]
           tweakCollectionWithName:collection] tweakWithIdentifier:identifier];
}

SpecBegin(SHKTweakInline)

beforeEach(^{
  [[FBTweakStore sharedInstance] reset];
});

context(@"Inline tweak", ^{
  it(@"should create a tweak", ^{
    auto tweak = SHKTweakInline(@"InlineTweak", @"Collection1", @"Name1", 6);
    expect(tweak.defaultValue).to.equal(6);
  });

  it(@"should set maximum and minimum values", ^{
    FBMutableTweak *tweak = SHKTweakInline(@"InlineTweak", @"Collection1", @"MinMax", 8, 6, 10);
    expect(tweak.defaultValue).to.equal(8);
    expect(tweak.minimumValue).to.equal(6);
    expect(tweak.maximumValue).to.equal(10);
  });

  it(@"should set possible values", ^{
    FBMutableTweak *tweak = SHKTweakInline(@"InlineTweak", @"Collection1", @"Possibles", @"bar",
                                           (@[@"foo", @"bar"]));
    expect(tweak.defaultValue).to.equal(@"bar");
    expect(tweak.possibleValues).to.equal(@[@"foo", @"bar"]);
  });
});

context(@"Tweak value", ^{
  it(@"should return default value", ^{
    expect(SHKTweakValue(@"TweakValue", @"CollectionB", @"DefaultValue", (id)@"foo"))
      .to.equal(@"foo");
  });

  it(@"should return current value if it was changed", ^{
    // FBTweaks are defined in compile-time and initialized at load time. This tweak is actually
    // defined by SHKTweakValue (...) in the 2nd next line therefore now is exists but its current
    // value is \c nil.
    FBMutableTweak * _Nullable tweak = (FBMutableTweak *)SHKFindTweak(@"TweakValue", @"CollectionB",
                                                                      @"CurrentValue");
    expect(tweak).to.beKindOf([FBMutableTweak class]);
    expect(tweak.currentValue).to.beNil();
    expect(tweak.defaultValue).to.equal(@"foo");
    tweak.currentValue = @"bar";
    expect(SHKTweakValue(@"TweakValue", @"CollectionB", @"CurrentValue", (id)@"foo"))
      .to.equal(@"bar");
  });
});

context(@"Tweak binding", ^{
  __block SHKTweakTestObject *object;

  beforeEach(^{
    object = [[SHKTweakTestObject alloc] init];
  });

  it(@"should bind default value", ^{
    SHKTweakBind(object, property, @"TweakBinding", @"Collection", @"Default", (id)@"foo");
    expect(object.property).to.equal(@"foo");
  });

  it(@"should return current value if it was changed", ^{
    FBMutableTweak * _Nullable tweak = (FBMutableTweak *)SHKFindTweak(@"TweakBinding",
                                                                      @"Collection",
                                                                      @"CurrentValue");
    expect(tweak).to.beKindOf([FBMutableTweak class]);
    SHKTweakBind(object, property, @"TweakBinding", @"Collection", @"CurrentValue", (id)@"foo");
    tweak.currentValue = @"bar";
    expect(object.property).to.equal(@"bar");
  });
});

context(@"Tweak signal", ^{
  it(@"should return default value", ^{
    expect(SHKTweakSignal(@"TweakSignal", @"CollectionC", @"DefaultValue", (id)@"foo"))
      .to.sendValues(@[@"foo"]);
  });

  it(@"should return current value if it was changed", ^{
    FBMutableTweak * _Nullable tweak = (FBMutableTweak *)SHKFindTweak(@"TweakSignal",
                                                                      @"CollectionC",
                                                                      @"CurrentValue");
    expect(tweak).to.beKindOf([FBMutableTweak class]);
    auto recorder =
        [SHKTweakSignal(@"TweakSignal", @"CollectionC", @"CurrentValue", (id)@"foo") testRecorder];
    tweak.currentValue = @"bar";
    expect(recorder).to.sendValues(@[@"foo", @"bar"]);
  });
});

context(@"Tweak action", ^{
  it(@"should return current value if it was changed", ^{
    FBActionTweak * _Nullable tweak = (FBActionTweak *)SHKFindTweak(@"TweakAction", @"CollectionD",
                                                                    @"CurrentValueA");
    expect(tweak).to.beKindOf([FBActionTweak class]);
    FBTweakAction(@"TweakAction", @"CollectionD", @"CurrentValueA", ^{
      [SHKGlobalFlag sharedFlag].flag = YES;
    });
    expect(tweak).notTo.beNil();
    dispatch_block_t block = tweak.currentValue;
    block();
    expect([SHKGlobalFlag sharedFlag].flag).to.beTruthy();
  });
});

SpecEnd
