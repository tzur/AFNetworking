#import "EXPMatchers+sendValuesWithCount.h"

#import "LLReactiveMatchersMessageBuilder.h"
#import "LLReactiveMatchersHelpers.h"

EXPMatcherImplementationBegin(sendValuesWithCount, (NSUInteger expected))

__block LLSignalTestRecorder *actualRecorder;

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
    return (actualRecorder.valuesSentCount == expected);
});

failureMessageForTo(^NSString *(id actual) {
    if(!LLRMCorrectClassesForActual(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    
    NSString *expectedBehaviour = [NSString stringWithFormat:@"send %@ events", @(expected)];
    NSString *actualBehaviour = [NSString stringWithFormat:@"%@ events sent", @(actualRecorder.valuesSentCount)];
    return [[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] expectedBehaviour:expectedBehaviour] actualBehaviour:actualBehaviour] build];
});

failureMessageForNotTo(^NSString *(id actual) {
    if(!LLRMCorrectClassesForActual(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    
    NSString *expectedBehaviour = [NSString stringWithFormat:@"not send %@ events", @(expected)];
    NSString *actualBehaviour = [NSString stringWithFormat:@"%@ events sent", @(actualRecorder.valuesSentCount)];
    return [[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] expectedBehaviour:expectedBehaviour] actualBehaviour:actualBehaviour] build];
});

EXPMatcherImplementationEnd
