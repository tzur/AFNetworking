#import "EXPMatchers+finish.h"

#import "LLSignalTestRecorder.h"
#import "LLReactiveMatchersHelpers.h"
#import "LLReactiveMatchersMessageBuilder.h"

EXPMatcherImplementationBegin(finish, (void))

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
    
    return actualRecorder.hasCompleted || actualRecorder.hasErrored;
});

failureMessageForTo(^NSString *(id actual) {
    if(!LLRMCorrectClassesForActual(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    
    return [LLReactiveMatchersMessageBuilder actualNotFinished:actualRecorder];
});

failureMessageForNotTo(^NSString *(id actual) {
    if(!LLRMCorrectClassesForActual(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    if(actualRecorder.hasErrored) {
        return [[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] expectedBehaviour:@"not finish"] actualBehaviour:@"finished with error"] build];
    }
    
    return [[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] expectedBehaviour:@"not finish"] actualBehaviour:@"finished with completion"] build];
});

EXPMatcherImplementationEnd
