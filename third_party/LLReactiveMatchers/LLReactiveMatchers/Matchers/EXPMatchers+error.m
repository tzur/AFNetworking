#import "EXPMatchers+error.h"

#import "LLSignalTestRecorder.h"
#import "LLReactiveMatchersHelpers.h"
#import "LLReactiveMatchersMessageBuilder.h"

EXPMatcherImplementationBegin(error, (void))

__block LLSignalTestRecorder *actualRecorder = nil;

void (^subscribe)(id actual) = ^(id actual) {
    if(!actualRecorder) {
        actualRecorder = LLRMRecorderForObject(actual);
    }
};

prerequisite(^BOOL(id actual) {
    return LLRMCorrectClassesForActual(actual);
});

match(^BOOL(id actual) {
    subscribe(actual);
    
    return actualRecorder.hasErrored;
});

failureMessageForTo(^NSString *(id actual) {
    if(!LLRMCorrectClassesForActual(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    if(!(actualRecorder.hasCompleted || actualRecorder.hasErrored)) {
        return [LLReactiveMatchersMessageBuilder actualNotFinished:actualRecorder];
    }
    
    return [[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] expectedBehaviour:@"error"] actualBehaviour:@"completed"] build];
});

failureMessageForNotTo(^NSString *(id actual) {
    if(!LLRMCorrectClassesForActual(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    
    return [[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] expectedBehaviour:@"not error"] actualBehaviour:@"errored"] build];
});

EXPMatcherImplementationEnd
