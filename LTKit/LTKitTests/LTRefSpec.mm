// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRef.h"

SpecBegin(LTRef)

context(@"constructor", ^{
  it(@"should be empty when constructed with no reference", ^{
    lt::Ref<CGMutablePathRef> ref;

    CGMutablePathRef reference = ref.get();
    expect(reference).to.equal(nullptr);
  });

  it(@"should be empty when constructed with nullptr_t", ^{
    lt::Ref<CGMutablePathRef> ref(nullptr);

    CGMutablePathRef reference = ref.get();
    expect(reference).to.equal(nullptr);
  });

  it(@"should not change retain count on construction", ^{
    CGMutablePathRef mutablePathRef = CGPathCreateMutable();
    CFIndex beforeRetainCount = CFGetRetainCount(mutablePathRef);

    lt::Ref<CGMutablePathRef> ref(mutablePathRef);
    CFIndex afterRetainCount = CFGetRetainCount(mutablePathRef);

    expect(afterRetainCount).to.equal(beforeRetainCount);
  });

  it(@"should retain when constructing with ::retain", ^{
    CGMutablePathRef reference = CGPathCreateMutable();
    CFIndex beforeRetainCount = CFGetRetainCount(reference);

    lt::Ref<CGMutablePathRef> ref = lt::Ref<CGMutablePathRef>::retain(reference);
    CGMutablePathRef retainedReference = ref.get();
    CFIndex afterRetainCount = CFGetRetainCount(retainedReference);

    expect(retainedReference).to.equal(reference);
    expect(afterRetainCount).to.equal(beforeRetainCount + 1);

    CFRelease(reference);
  });

  it(@"should create a ref with makeRef", ^{
    CGMutablePathRef reference = CGPathCreateMutable();
    auto ref = lt::makeRef(reference);
    CGMutablePathRef constructedRef = ref.get();

    expect(constructedRef).to.equal(reference);
  });

  it(@"should create a ref with makeRef that accepts an rvalue reference", ^{
    CGMutablePathRef reference = CGPathCreateMutable();
    auto ref = lt::makeRef(std::move(reference));
    CGMutablePathRef constructedRef = ref.get();

    expect(constructedRef).to.equal(reference);
  });
});

context(@"copy constructor", ^{
  it(@"should increase retain count when copying", ^{
    CGMutablePathRef mutablePathRef = CGPathCreateMutable();
    lt::Ref<CGMutablePathRef> firstRef(mutablePathRef);

    CFIndex beforeRetainCount = CFGetRetainCount(firstRef.get());
    lt::Ref<CGMutablePathRef> secondRef(firstRef);
    CFIndex afterRetainCount = CFGetRetainCount(secondRef.get());

    CGMutablePathRef firstReference = firstRef.get();
    CGMutablePathRef secondReference = secondRef.get();

    expect(firstReference).to.equal(secondReference);
    expect(afterRetainCount).to.equal(beforeRetainCount + 1);
  });

  it(@"should copy construct to a const type", ^{
    CGMutablePathRef mutablePathRef = CGPathCreateMutable();
    lt::Ref<CGMutablePathRef> firstRef(mutablePathRef);

    CFIndex beforeRetainCount = CFGetRetainCount(firstRef.get());
    lt::Ref<CGPathRef> secondRef(firstRef);
    CFIndex afterRetainCount = CFGetRetainCount(secondRef.get());

    CGMutablePathRef firstReference = firstRef.get();
    CGPathRef secondReference = secondRef.get();

    expect(firstReference).to.equal(secondReference);
    expect(afterRetainCount).to.equal(beforeRetainCount + 1);
  });
});

context(@"assignment operator", ^{
  it(@"should increase retain count when assigning", ^{
    CGMutablePathRef mutablePathRef = CGPathCreateMutable();
    lt::Ref<CGMutablePathRef> firstRef(mutablePathRef);

    CFIndex beforeRetainCount = CFGetRetainCount(firstRef.get());
    lt::Ref<CGMutablePathRef> secondRef;
    secondRef = firstRef;
    CFIndex afterRetainCount = CFGetRetainCount(secondRef.get());

    CGMutablePathRef firstReference = firstRef.get();
    CGMutablePathRef secondReference = secondRef.get();

    expect(firstReference).to.equal(secondReference);
    expect(afterRetainCount).to.equal(beforeRetainCount + 1);
  });

  it(@"should release previous reference when assigning", ^{
    CGMutablePathRef firstReference = CGPathCreateMutable();
    lt::Ref<CGMutablePathRef> firstRef(firstReference);

    CGMutablePathRef secondReference = CGPathCreateMutable();
    CFRetain(secondReference);
    CFIndex beforeRetainCount = CFGetRetainCount(secondReference);
    lt::Ref<CGMutablePathRef> secondRef(secondReference);

    secondRef = firstRef;

    CFIndex afterRetainCount = CFGetRetainCount(secondReference);
    expect(afterRetainCount).to.equal(beforeRetainCount - 1);

    CFRelease(secondReference);
  });

  it(@"should assign construct to a const type", ^{
    CGMutablePathRef mutablePathRef = CGPathCreateMutable();
    lt::Ref<CGMutablePathRef> firstRef(mutablePathRef);

    CFIndex beforeRetainCount = CFGetRetainCount(firstRef.get());
    lt::Ref<CGPathRef> secondRef;
    secondRef = firstRef;
    CFIndex afterRetainCount = CFGetRetainCount(secondRef.get());

    CGMutablePathRef firstReference = firstRef.get();
    CGPathRef secondReference = secondRef.get();

    expect(firstReference).to.equal(secondReference);
    expect(afterRetainCount).to.equal(beforeRetainCount + 1);
  });
});

context(@"move semantics", ^{
  it(@"should use move constructor correctly", ^{
    lt::Ref<CGMutablePathRef> ref(CGPathCreateMutable());
    auto firstReference = ref.get();

    lt::Ref<CGMutablePathRef> movedRef = std::move(ref);
    CGMutablePathRef movedReference = movedRef.get();

    CGMutablePathRef stolenReference = ref.get();

    expect(firstReference).to.equal(movedReference);
    expect(stolenReference).to.equal(nullptr);
  });

  it(@"should use move constructor to a const type", ^{
    lt::Ref<CGMutablePathRef> ref(CGPathCreateMutable());
    auto firstReference = ref.get();

    lt::Ref<CGPathRef> movedRef = std::move(ref);
    CGPathRef movedReference = movedRef.get();

    CGPathRef stolenReference = ref.get();

    expect(firstReference).to.equal(movedReference);
    expect(stolenReference).to.equal(nullptr);
  });

  it(@"should use move assignment operator correctly", ^{
    lt::Ref<CGMutablePathRef> ref(CGPathCreateMutable());
    lt::Ref<CGMutablePathRef> movedRef;

    CGMutablePathRef firstReference = ref.get();
    movedRef = std::move(ref);

    CGMutablePathRef movedReference = movedRef.get();
    CGMutablePathRef stolenReference = ref.get();

    expect(firstReference).to.equal(movedReference);
    expect(stolenReference).to.equal(nullptr);
  });

  it(@"should use move assignment to a const type", ^{
    lt::Ref<CGMutablePathRef> ref(CGPathCreateMutable());
    lt::Ref<CGPathRef> movedRef;

    CGMutablePathRef firstReference = ref.get();
    movedRef = std::move(ref);

    CGPathRef movedReference = movedRef.get();
    CGMutablePathRef stolenReference = ref.get();

    expect(firstReference).to.equal(movedReference);
    expect(stolenReference).to.equal(nullptr);
  });
});

context(@"destructor", ^{
  it(@"should decrease retain count when releasing", ^{
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

context(@"getting the underlying reference", ^{
  it(@"should retrieve the underlying reference with get()", ^{
    CGMutablePathRef reference = CGPathCreateMutable();
    lt::Ref<CGMutablePathRef> ref(reference);

    CGMutablePathRef retrievedReference = ref.get();
    expect(retrievedReference).to.equal(reference);
  });
});

context(@"explicit boolean operator", ^{
  it(@"should return true when constructed with a non null reference", ^{
    lt::Ref<CGMutablePathRef> ref(CGPathCreateMutable());

    bool empty = !ref;
    expect(empty).to.beFalsy();
  });

  it(@"should return false when holding a nullptr", ^{
    lt::Ref<CGMutablePathRef> ref;

    bool empty = !ref;
    expect(empty).to.beTruthy();
  });
});


  });

context(@"reset", ^{
  it(@"should reset correctly", ^{
    lt::Ref<CGMutablePathRef> ref(CGPathCreateMutable());
    ref.reset(nullptr);

    bool empty = !ref;
    expect(empty).to.beTruthy();
  });
});

context(@"release", ^{
  it(@"should release correctly", ^{
    CGMutablePathRef reference = CGPathCreateMutable();
    CFIndex beforeRetainCount = CFGetRetainCount(reference);

    lt::Ref<CGMutablePathRef> ref(reference);
    CGMutablePathRef releasedReference = ref.release();
    CFIndex afterRetainCount = CFGetRetainCount(releasedReference);

    expect(reference).to.equal(releasedReference);
    expect(afterRetainCount).to.equal(beforeRetainCount);

    CFRelease(reference);
  });
});

context(@"releasing a ref", ^{
  it(@"should release a ref and return it", ^{
    lt::Ref<CGMutablePathRef> ref(CGPathCreateMutable());

    CGMutablePathRef rawPointer = ref.get();
    CGMutablePathRef reference = ref.release();

    bool empty = !ref;
    expect(empty).to.beTruthy();
    expect(rawPointer).to.to.equal(reference);

    CFRelease(reference);
  });
});

SpecEnd
