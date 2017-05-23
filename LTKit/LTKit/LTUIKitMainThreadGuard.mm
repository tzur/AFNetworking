// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTUIKitMainThreadGuard.h"

#import <objc/message.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/// Derived from Mike Ash's blog:
/// http://www.mikeash.com/pyblog/friday-qa-2010-01-29-method-replacement-for-fun-and-profit.html
static BOOL LTReplaceMethodWithBlock(Class classObj, SEL originalSEL, SEL newSEL, id block) {
  if ([classObj instancesRespondToSelector:newSEL]) {
    return YES;
  }

  Method originalMethod = class_getInstanceMethod(classObj, originalSEL);

  IMP imp = imp_implementationWithBlock(block);
  BOOL methodAdded = class_addMethod(classObj, newSEL, imp,
                                     method_getTypeEncoding(originalMethod));
  if (!methodAdded) {
    return NO;
  }

  Method newMethod = class_getInstanceMethod(classObj, newSEL);
  methodAdded = class_addMethod(classObj, originalSEL, method_getImplementation(newMethod),
                                method_getTypeEncoding(originalMethod));

  // If original doesn't implement the method we want to swizzle, create it.
  if (methodAdded) {
    class_replaceMethod(classObj, newSEL, method_getImplementation(originalMethod),
                        method_getTypeEncoding(newMethod));
  } else {
    method_exchangeImplementations(originalMethod, newMethod);
  }

  return YES;
}

static SEL LTSwizzledSelectorFromSelector(SEL originalSelector) {
  auto originalSelectorName = NSStringFromSelector(originalSelector);
  return NSSelectorFromString([@"lt_swizzled_" stringByAppendingString:originalSelectorName]);
}

static BOOL LTReplaceCGRectSelector(SEL selector, LTVoidBlock block) {
  SEL newSelector = LTSwizzledSelectorFromSelector(selector);

  return LTReplaceMethodWithBlock(UIView.class, selector, newSelector,
                                  ^(__unsafe_unretained UIView *_self, CGRect rect) {
    // Check for window, since it is allowed to create a UIView and potentially mutate it not on the
    // main thread. The restriction comes into effect only when the view is added to a window.
    // Additionally, some operations are thread safe. As in
    // https://stackoverflow.com/questions/16299842/uikit-and-gcd-thread-safety
    //
    // Drawing to a graphics context in UIKit is now thread-safe. Specifically:
    // - The routines used to access and manipulate the graphics context can now correctly handle
    //   contexts residing on different threads.
    // - String and image drawing is now thread-safe.
    // - Using color and font objects in multiple threads is now safe to do.
    if (_self.window && !NSThread.isMainThread) {
      block();
    }
    ((void (*)(id, SEL, CGRect))objc_msgSend)(_self, newSelector, rect);
  });
}

static BOOL LTReplaceVoidSelector(SEL selector, LTVoidBlock block) {
  SEL newSelector = LTSwizzledSelectorFromSelector(selector);

  return LTReplaceMethodWithBlock(UIView.class, selector, newSelector,
                                  ^(__unsafe_unretained UIView *_self) {
    if (_self.window && !NSThread.isMainThread) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      dispatch_queue_t queue = dispatch_get_current_queue();
#pragma clang diagnostic pop
      // UIKit sometimes performs operations on a private background queue, such as
      // MFMailComposeController layout.
      if (!queue || !strstr(dispatch_queue_get_label(queue), "UIKit")) {
        block();
      }
    }
    ((void (*)(id, SEL))objc_msgSend)(_self, newSelector);
  });
}

BOOL LTInstallUIKitMainThreadGuard(LTVoidBlock block) {
  LTAssert(block);

  static BOOL isInstalled = NO;
  if (isInstalled) {
    LogWarning(@"LTInstallUIKitMainThreadGuard was already called, ignoring");
    return NO;
  }

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    isInstalled = YES;
  });

  BOOL success = YES;
  @autoreleasepool {
    success &= LTReplaceVoidSelector(@selector(setNeedsLayout), block);
    success &= LTReplaceVoidSelector(@selector(setNeedsDisplay), block);
    success &= LTReplaceCGRectSelector(@selector(setNeedsDisplayInRect:), block);
  }
  return success;
}

NS_ASSUME_NONNULL_END
