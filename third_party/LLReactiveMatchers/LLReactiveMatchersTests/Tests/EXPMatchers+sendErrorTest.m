#import "EXPMatchers+sendError.h"

#import <ReactiveObjC/ReactiveObjC.h>

#import "LLReactiveMatchers.h"
#import "LLReactiveMatchersFixtures.h"

@interface EXPMatchers_sendErrorTests : XCTestCase
@end

@implementation EXPMatchers_sendErrorTests

- (void) test_nonSignalActual {
    NSArray *signal = @[@1, @2, @3];
    NSError *expected = LLSpecError;
    NSString *failureString = [NSString stringWithFormat:@"expected: actual to be a signal or recorder: %@", signal];

    assertFail(test_expect(signal).to.sendError(expected), failureString);
    assertFail(test_expect(signal).toNot.sendError(expected), failureString);
}

- (void) test_endsInCompletion {
    RACSignal *signal = [[LLReactiveMatchersFixtures values:@[@1, @2, @3]] setNameWithFormat:@"foo"];
    NSError *error = LLSpecError;
    NSString *failureString = @"expected: actual foo to error, got: completed";
    
    assertPass(test_expect(signal).toNot.sendError(error));
    assertFail(test_expect(signal).to.sendError(error), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willNot.sendError(error));
    assertFail(test_expect(signal).will.sendError(error), failureString);
    
    assertPass(test_expect(signal).willNotContinueTo.sendError(error));
    assertFail(test_expect(signal).willContinueTo.sendError(error), failureString);
}

- (void) test_notYetCompleted {
    RACSignal *signal = [[[LLReactiveMatchersFixtures values:@[@1, @2, @3]] concat:RACSignal.never] setNameWithFormat:@"foo"];
    NSError *error = LLSpecError;
    NSString *failureString = @"expected: actual foo to finish";
    
    assertPass(test_expect(signal).toNot.sendError(error));
    assertFail(test_expect(signal).to.sendError(error), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willNotContinueTo.sendError(error));
    assertFail(test_expect(signal).willContinueTo.sendError(error), failureString);
}

- (void) test_endsInSameError {
    RACSignal *signal = [[[LLReactiveMatchersFixtures values:@[@1, @2, @3]] concat:[RACSignal error:LLSpecError]] setNameWithFormat:@"foo"];
    NSError *error = LLSpecError;
    NSString *failureString = [NSString stringWithFormat:@"expected: actual foo to send error %@, got: the same error" , error];
    
    assertPass(test_expect(signal).to.sendError(error));
    assertFail(test_expect(signal).toNot.sendError(error), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willContinueTo.sendError(error));
    assertFail(test_expect(signal).willNotContinueTo.sendError(error), failureString);
}

- (void) test_endsInDifferentError {
    RACSignal *signal = [[[LLReactiveMatchersFixtures values:@[@1, @2, @3]] concat:[RACSignal error:LLSpecError]] setNameWithFormat:@"foo"];
    NSError *error = [NSError errorWithDomain:@"foo" code:1 userInfo:@{}];
    NSString *failureString = [NSString stringWithFormat:@"expected: actual foo to send error %@, got: different errors" , error];

    assertPass(test_expect(signal).toNot.sendError(error));
    assertFail(test_expect(signal).to.sendError(error), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willNot.sendError(error));
    assertFail(test_expect(signal).will.sendError(error), failureString);
    
    assertPass(test_expect(signal).willNotContinueTo.sendError(error));
    assertFail(test_expect(signal).willContinueTo.sendError(error), failureString);
}

@end
