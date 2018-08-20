#import "EXPMatchers+matchError.h"

#import "LLSignalTestRecorder.h"
#import "LLReactiveMatchersHelpers.h"
#import "LLReactiveMatchersMessageBuilder.h"

EXPMatcherImplementationBegin(matchError, (BOOL(^matchBlock)(NSError *error)) )

__block LLSignalTestRecorder *actualRecorder;
__block BOOL notErrored;

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
    
    if(actualRecorder.hasErrored) {
        notErrored = NO;
        BOOL matched = matchBlock( actualRecorder.error );
        return matched;
    }
    
    notErrored = YES;
    return NO;
});

failureMessageForTo(^NSString *(id actual) {
    if(!LLRMCorrectClassesForActual(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    if(notErrored) {
        NSString *expectedBehaviour = @"match error";
        NSString *actualBehaviour = @"did not error";
        return [[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] expectedBehaviour:expectedBehaviour] actualBehaviour:actualBehaviour] build];
    }
    
    NSString *expectedBehaviour = @"match error";
    NSString *actualBehaviour = @"did not match error";
    return [[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] expectedBehaviour:expectedBehaviour] actualBehaviour:actualBehaviour] build];
});

failureMessageForNotTo(^NSString *(id actual) {
    if(!LLRMCorrectClassesForActual(actual)) {
        return [LLReactiveMatchersMessageBuilder actualNotCorrectClass:actual];
    }
    
    NSString *expectedBehaviour = @"not match error";
    NSString *actualBehaviour = @"matched error";
    return [[[[[LLReactiveMatchersMessageBuilder message] actual:actualRecorder] expectedBehaviour:expectedBehaviour] actualBehaviour:actualBehaviour] build];
});

EXPMatcherImplementationEnd
