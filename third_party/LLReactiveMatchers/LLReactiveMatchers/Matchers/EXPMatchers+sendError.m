#import "EXPMatchers+sendError.h"

#import "LLReactiveMatchersMessageBuilder.h"
#import "LLReactiveMatchersHelpers.h"

EXPMatcherImplementationBegin(sendError, (NSError *expected))

__block LLSignalTestRecorder *actualRecorder = nil;
__block LLSignalTestRecorder *expectedRecorder = nil;

void (^subscribe)(id actual) = ^(id actual) {
    if(!actualRecorder) {
        actualRecorder = LLRMRecorderForObject(actual);
    }
    if(!expectedRecorder) {
        expectedRecorder = LLRMRecorderForObject(expected);
    }
};

prerequisite(^BOOL(id actual) {
    return LLRMCorrectClassesForActual(actual) && LLRMCorrectClassesForError(expected);
});

match(^BOOL(id actual) {
    subscribe(actual);
    return actualRecorder.hasErrored && LLRMIdenticalErrors(actualRecorder, expectedRecorder);
});

failureMessageForTo(^NSString *(id actual) {
    if(!LLRMCorrectClassesForActual(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    if(!LLRMCorrectClassesForError(expected)) {
      return [LLReactiveMatchersMessageBuilder expectedShouldBeOfClass:NSError.class];
    }
    if(!(actualRecorder.hasCompleted || actualRecorder.hasErrored)) {
        return [LLReactiveMatchersMessageBuilder actualNotFinished:actualRecorder];
    }
    if(!actualRecorder.hasErrored) {
        return [[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] expectedBehaviour:@"error"] actualBehaviour:@"completed"] build];
    }
    if(!expectedRecorder.hasErrored) {
        return [[[[[LLReactiveMatchersMessageBuilder message] expected:expectedRecorder] expectedBehaviour:@"error"] actualBehaviour:@"completed"] build];
    }
    
    return [[[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] expected:expectedRecorder] renderExpectedError] actualBehaviour:@"different errors"] build];
});

failureMessageForNotTo(^NSString *(id actual) {
    if(!LLRMCorrectClassesForActual(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    
    return [[[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] expected:expectedRecorder] renderExpectedError] actualBehaviour:@"the same error"] build];
});

EXPMatcherImplementationEnd
