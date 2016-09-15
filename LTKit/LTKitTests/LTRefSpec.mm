// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRef.h"

class LTMyType {
public:
  LTMyType(const std::string &name) : _name(name) {};

  const std::string name() const {
    return _name;
  }

private:
  const std::string _name;
};

class LTMyDerivedType : public LTMyType {
public:
  LTMyDerivedType(const std::string &name) : LTMyType(name) {};
};

typedef void (^LTMyTypeReleaseBlock)(const LTMyType *myType);

static LTMyTypeReleaseBlock releaseBlock;

void LTMyTypeRelease(const LTMyType *myType) {
  if (releaseBlock) {
    releaseBlock(myType);
  }
  delete myType;
}

LTRefReleaserMake(LTMyType *, LTMyTypeRelease);
LTRefReleaserMake(const LTMyType *, LTMyTypeRelease);
LTRefReleaserMake(LTMyDerivedType *, LTMyTypeRelease);

SpecBegin(LTRef)

context(@"releaser for custom type", ^{
  __block BOOL released;

  beforeEach(^{
    released = NO;

    releaseBlock = ^(const LTMyType *releasedMyType) {
      expect(@(releasedMyType->name().c_str())).to.equal(@"foo");
      released = YES;
    };
  });

  afterEach(^{
    releaseBlock = nil;
  });

  it(@"should call release function when Ref is destroyed", ^{
    {
      lt::Ref<LTMyType *> myType(new LTMyType("foo"));
    }

    expect(released).to.beTruthy();
  });

  it(@"should call release function when resetting the Ref", ^{
    lt::Ref<LTMyType *> myType(new LTMyType("foo"));
    myType.reset(nullptr);

    bool empty = !myType;
    expect(empty).to.beTruthy();
  });
});

context(@"move semantics", ^{
  it(@"should use move constructor correctly", ^{
    lt::Ref<LTMyType *> myType(new LTMyType("foo"));
    LTMyType *firstReference = myType.get();

    lt::Ref<LTMyType *> movedMyType = std::move(myType);
    LTMyType *movedReference = movedMyType.get();

    LTMyType *stolenReference = myType.get();

    expect(firstReference).to.equal(movedReference);
    expect(stolenReference).toNot.equal(movedReference);
  });

  it(@"should use move constructor to a const type", ^{
    lt::Ref<LTMyType *> myType(new LTMyType("foo"));
    LTMyType *firstReference = myType.get();

    lt::Ref<const LTMyType *> movedMyType = std::move(myType);
    const LTMyType *movedReference = movedMyType.get();

    LTMyType *stolenReference = myType.get();

    expect(firstReference).to.equal(movedReference);
    expect(stolenReference).toNot.equal(movedReference);
  });

  it(@"should use move constructor to a different type", ^{
    lt::Ref<LTMyDerivedType *> myType(new LTMyDerivedType("foo"));
    LTMyType *firstReference = myType.get();

    lt::Ref<LTMyType *> movedMyType = std::move(myType);
    LTMyType *movedReference = movedMyType.get();

    LTMyType *stolenReference = myType.get();

    expect(firstReference).to.equal(movedReference);
    expect(stolenReference).toNot.equal(movedReference);
  });

  it(@"should use move assignment operator correctly", ^{
    lt::Ref<LTMyType *> myType(new LTMyType("foo"));
    lt::Ref<LTMyType *> movedMyType;

    LTMyType *firstReference = myType.get();
    movedMyType = std::move(myType);

    LTMyType *movedReference = movedMyType.get();
    LTMyType *stolenReference = myType.get();

    expect(firstReference).to.equal(movedReference);
    expect(stolenReference).toNot.equal(movedReference);
  });

  it(@"should use move assignment to a const type", ^{
    lt::Ref<LTMyType *> myType(new LTMyType("foo"));
    lt::Ref<const LTMyType *> movedMyType;

    LTMyType *firstReference = myType.get();
    movedMyType = std::move(myType);

    const LTMyType *movedReference = movedMyType.get();
    LTMyType *stolenReference = myType.get();

    expect(firstReference).to.equal(movedReference);
    expect(stolenReference).toNot.equal(movedReference);
  });

  it(@"should use move assignment to a different type", ^{
    lt::Ref<LTMyDerivedType *> myType(new LTMyDerivedType("foo"));
    lt::Ref<LTMyType *> movedMyType;

    LTMyType *firstReference = myType.get();
    movedMyType = std::move(myType);

    LTMyType *movedReference = movedMyType.get();
    LTMyType *stolenReference = myType.get();

    expect(firstReference).to.equal(movedReference);
    expect(stolenReference).toNot.equal(movedReference);
  });
});

context(@"getting the underlying reference", ^{
  it(@"should retrieve the underlying reference with get()", ^{
    LTMyType *myType = new LTMyType("foo");
    lt::Ref<LTMyType *> myTypeRef(myType);

    LTMyType *myTypeRetrieved = myTypeRef.get();
    expect(myTypeRetrieved).to.equal(myType);
  });

  it(@"should retrieve the underlying reference with implicit cast", ^{
    LTMyType *myType = new LTMyType("foo");
    lt::Ref<LTMyType *> myTypeRef(myType);

    LTMyType *myTypeRetrieved = myTypeRef.get();
    expect(myTypeRetrieved).to.equal(myType);
  });
});

context(@"explicit boolean operator", ^{
  it(@"should be empty when constructed with no ref", ^{
    lt::Ref<LTMyType *> ref;

    bool empty = !ref;
    expect(empty).to.beTruthy();
  });

  it(@"should be not empty when constructed with a valid ref", ^{
    lt::Ref<LTMyType *> ref(new LTMyType("foo"));

    bool empty = !ref;
    expect(empty).to.beFalsy();
  });

  it(@"should be empty after reset to nullptr", ^{
    lt::Ref<LTMyType *> ref(new LTMyType("foo"));
    ref.reset(nullptr);

    bool empty = !ref;
    expect(empty).to.beTruthy();
  });
});

context(@"releasing a ref", ^{
  it(@"should release a ref and return it", ^{
    lt::Ref<LTMyType *> ref(new LTMyType("foo"));

    LTMyType *rawPointer = ref.get();
    LTMyType *myType = ref.release();

    bool empty = !ref;
    expect(empty).to.beTruthy();
    expect(rawPointer).to.to.equal(myType);

    delete myType;
  });
});

context(@"releaser for core foundation objects", ^{
  it(@"should release CGMutablePathRef", ^{
    CGMutablePathRef mutablePathRef;
    CFIndex retainCount;

    {
      lt::Ref<CGMutablePathRef> mutablePath(CGPathCreateMutable());
      mutablePathRef = (CGMutablePathRef)CFRetain(mutablePath.get());
      retainCount = CFGetRetainCount(mutablePathRef);
    }

    expect(CFGetRetainCount(mutablePathRef)).to.equal(retainCount - 1);
    CFRelease(mutablePathRef);
  });
});

SpecEnd
