#import "EXPMatchers+sendValues.h"

#import "LLReactiveMatchersMessageBuilder.h"
#import "LLReactiveMatchersHelpers.h"
#import "LLSignalTestRecorder.h"

EXPMatcherImplementationBegin(sendValues, (NSArray *expected))

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
    return LLRMCorrectClassesForActual(actual) && LLRMCorrectClassesForValues(expected);
});

match(^BOOL(id actual) {
    subscribe(actual);
    return LLRMContainsAllValuesEqual(actualRecorder, expectedRecorder);
});

failureMessageForTo(^NSString *(id actual) {
    if(!LLRMCorrectClassesForActual(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    if(!LLRMCorrectClassesForValues(expected)) {
      return [LLReactiveMatchersMessageBuilder expectedShouldBeOfClass:NSArray.class];
    }

    return [[[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] renderActualValues] expected:expectedRecorder] renderExpectedValues] build];
});

failureMessageForNotTo(^NSString *(id actual) {
    if(!LLRMCorrectClassesForActual(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    
    return [[[[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] renderActualValues] expected:expectedRecorder] renderExpectedValues] renderExpectedNot] build];
});

EXPMatcherImplementationEnd
