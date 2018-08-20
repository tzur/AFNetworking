#import "EXPMatchers+beSubscribedTo.h"
#import "RACSignal+LLSubscriptionCounting.h"
#import "LLReactiveMatchersHelpers.h"
#import "LLReactiveMatchersMessageBuilder.h"

#import <objc/runtime.h>

EXPMatcherImplementationBegin(beSubscribedTo, (NSInteger times))

BOOL(^correctClasses)(id actual) = ^BOOL(id actual) {
  return [actual isKindOfClass:RACSignal.class];
};

prerequisite(^BOOL(id actual) {
    return LLRMCorrectClassesForActual(actual);
});

match(^BOOL(id actual) {
    @synchronized(actual) {
        return ([actual subscriptionCount] == times);
    }
});

failureMessageForTo(^NSString *(id actual) {
    if(!correctClasses(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    
    @synchronized(actual) {
        NSInteger subscriptionCount = [actual subscriptionCount];
        if(subscriptionCount == -1) {
            return [LLReactiveMatchersMessageBuilder expectedSignalDidNotRecordSubscriptions:actual];
        }
        return [LLReactiveMatchersMessageBuilder expectedSignal:actual toBeSubscribedTo:times actual:subscriptionCount];
    }
});

failureMessageForNotTo(^NSString *(id actual) {
    if(!correctClasses(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    
    @synchronized(actual) {
        return [LLReactiveMatchersMessageBuilder expectedSignal:actual toNotBeSubscribedTo:times];
    }
});

EXPMatcherImplementationEnd
