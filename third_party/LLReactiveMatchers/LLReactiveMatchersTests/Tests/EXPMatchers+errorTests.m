#import "EXPMatchers+error.h"

#import "LLReactiveMatchers.h"
#import "LLReactiveMatchersFixtures.h"

@interface EXPMatchers_errorTests : XCTestCase
@end

@implementation EXPMatchers_errorTests

- (void) test_nonSignalActual {
    NSArray *signal = @[@1, @2, @3];
    NSString *failureString = [NSString stringWithFormat:@"expected: actual to be a signal or recorder: %@", signal];

    assertFail(test_expect(signal).to.error(), failureString);
    assertFail(test_expect(signal).toNot.error(), failureString);
}

- (void) test_endsInError {
    RACSignal *signal = [[[LLReactiveMatchersFixtures values:@[@1, @2, @3]] concat:[RACSignal error:LLSpecError]] setNameWithFormat:@"foo"];
    NSString *failureString = @"expected: actual foo to not error, got: errored";
    
    assertPass(test_expect(signal).to.error());
    assertFail(test_expect(signal).toNot.error(), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).will.error());
    assertPass(test_expect(signal).willNot.error());
    
    assertPass(test_expect(signal).willContinueTo.error());
    assertFail(test_expect(signal).willNotContinueTo.error(), failureString);
}

- (void) test_endsInCompletion {
    RACSignal *signal = [[LLReactiveMatchersFixtures values:@[@1, @2, @3]] setNameWithFormat:@"foo"];
    NSString *failureString = @"expected: actual foo to error, got: completed";
    
    assertPass(test_expect(signal).toNot.error());
    assertFail(test_expect(signal).to.error(), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willNot.error());
    assertFail(test_expect(signal).will.error(), failureString);
    
    assertPass(test_expect(signal).willNotContinueTo.error());
    assertFail(test_expect(signal).willContinueTo.error(), failureString);
}

- (void) test_notYetCompleted {
    RACSignal *signal = [[[LLReactiveMatchersFixtures values:@[@1, @2, @3]] concat:RACSignal.never] setNameWithFormat:@"foo"];
    NSString *failureString = @"expected: actual foo to finish";
    
    assertPass(test_expect(signal).toNot.error());
    assertFail(test_expect(signal).to.error(), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willNot.error());
    assertFail(test_expect(signal).will.error(), failureString);
    
    assertPass(test_expect(signal).willNotContinueTo.error());
    assertFail(test_expect(signal).willContinueTo.error(), failureString);
}

@end
