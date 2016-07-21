// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "UIViewController+Containment.h"

@interface WFTestViewController : UIViewController

@property (nonatomic) BOOL didMoveToParentCalled;
@property (nonatomic) BOOL willMoveToParentCalled;

@property (weak, nonatomic) UIViewController *didMoveToParent;
@property (weak, nonatomic) UIViewController *willMoveToParent;

@end

@implementation WFTestViewController

- (void)didMoveToParentViewController:(UIViewController *)parent {
  [super didMoveToParentViewController:parent];
  self.didMoveToParentCalled = YES;
  self.didMoveToParent = parent;
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
  [super willMoveToParentViewController:parent];
  self.willMoveToParentCalled = YES;
  self.willMoveToParent = parent;
}

@end

SpecBegin(UIViewController_Containment)

__block WFTestViewController *parent;
__block WFTestViewController *child;
__block UIView *subview;

beforeEach(^{
  parent = [[WFTestViewController alloc] init];
  // Child cannot be mocked since UIKit assumes the added child is a real object. Otherwise crashes
  // and mysterious errors appear. See: http://goo.gl/u4pHNj for a relevant SO question.
  child = [[WFTestViewController alloc] init];

  subview = [[UIView alloc] initWithFrame:CGRectZero];
  [parent.view addSubview:subview];
});

context(@"adding child view controller", ^{
  beforeEach(^{
    [parent wf_addChildViewController:child];
  });

  it(@"should notify child on add to parent view controller", ^{
    expect(child.didMoveToParent).to.equal(parent);
    expect(child.willMoveToParent).to.equal(parent);
  });

  it(@"should add child view to parent subviews", ^{
    expect(parent.view.subviews).to.contain(child.view);
  });
});

context(@"inserting child view controller", ^{
  context(@"below subview", ^{
    beforeEach(^{
      [parent wf_insertChildViewController:child belowSubview:subview];
    });

    it(@"should notify child on add to parent view controller", ^{
      expect(child.didMoveToParent).to.equal(parent);
      expect(child.willMoveToParent).to.equal(parent);
    });

    it(@"should add child view below subview", ^{
      expect(parent.view.subviews).to.contain(child.view);
      expect([parent.view.subviews indexOfObject:child.view])
          .to.equal([parent.view.subviews indexOfObject:subview] - 1);
    });
  });

  context(@"above subview", ^{
    beforeEach(^{
      [parent wf_insertChildViewController:child aboveSubview:subview];
    });

    it(@"should notify child on add to parent view controller", ^{
      expect(child.didMoveToParent).to.equal(parent);
      expect(child.willMoveToParent).to.equal(parent);
    });

    it(@"should add child view above subview", ^{
      expect(parent.view.subviews).to.contain(child.view);
      expect([parent.view.subviews indexOfObject:child.view])
          .to.equal([parent.view.subviews indexOfObject:subview] + 1);
    });
  });

  context(@"at index", ^{
    beforeEach(^{
      [parent wf_insertChildViewController:child atIndex:0];
    });

    it(@"should notify child on add to parent view controller", ^{
      expect(child.didMoveToParent).to.equal(parent);
      expect(child.willMoveToParent).to.equal(parent);
    });

    it(@"should add child view at index", ^{
      expect(parent.view.subviews).to.contain(child.view);
      expect([parent.view.subviews indexOfObject:child.view]).to.equal(0);
    });
  });
});

context(@"adding child view controller to a specific view", ^{
  it(@"should add child view to given view", ^{
    [parent wf_addChildViewController:child toView:subview];
    expect(subview.subviews).to.contain(child.view);
  });
});

context(@"inserting child view controller to a specific view", ^{
  __block UIView *subviewOfSubview;

  beforeEach(^{
    subviewOfSubview = [[UIView alloc] initWithFrame:CGRectZero];
    [subview addSubview:subviewOfSubview];
  });

  it(@"should insert child view to given view below subview", ^{
    [parent wf_insertChildViewController:child toView:subview belowSubview:subviewOfSubview];
    expect(subview.subviews).to.contain(child.view);
    expect([subview.subviews indexOfObject:child.view])
        .to.equal([subview.subviews indexOfObject:subviewOfSubview] - 1);
  });

  it(@"should add child view to given view above subview", ^{
    [parent wf_insertChildViewController:child toView:subview aboveSubview:subviewOfSubview];
    expect(subview.subviews).to.contain(child.view);
    expect([subview.subviews indexOfObject:child.view])
        .to.equal([subview.subviews indexOfObject:subviewOfSubview] + 1);
  });

  it(@"should add child view to given view at index", ^{
    [parent wf_insertChildViewController:child toView:subview atIndex:1];
    expect(subview.subviews).to.contain(child.view);
    expect([subview.subviews indexOfObject:child.view]).to.equal(1);
  });
});

context(@"removing child view controller", ^{
  beforeEach(^{
    [parent wf_addChildViewController:child];
    [parent wf_removeChildViewController:child];
  });

  it(@"should notify child on remove from parent view controller", ^{
    expect(child.didMoveToParentCalled).to.beTruthy();
    expect(child.didMoveToParent).to.beNil();
    expect(child.willMoveToParentCalled).to.beTruthy();
    expect(child.willMoveToParent).to.beNil();
  });

  it(@"should remove child from from parent subviews", ^{
    expect(parent.view.subviews).toNot.contain(child.view);
  });
});

SpecEnd
