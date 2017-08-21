#import "EXPMatchers+finish.h"

#import <ReactiveObjC/ReactiveObjC.h>

#import "LLReactiveMatchers.h"
#import "LLReactiveMatchersFixtures.h"

@interface EXPMatchers_finishTests : XCTestCase
@end

@implementation EXPMatchers_finishTests

- (void) test_nonSignalActual {
    NSArray *signal = @[@1, @2, @3];
    NSString *failureString = [NSString stringWithFormat:@"expected: actual to be a signal or recorder: %@", signal];

    assertFail(test_expect(signal).to.finish(), failureString);
    assertFail(test_expect(signal).toNot.finish(), failureString);
}

- (void) test_completion {
    RACSignal *signal = [[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] setNameWithFormat:@"foo"];
    NSString *failureString = @"expected: actual foo to not finish, got: finished with completion";
    
    assertPass(test_expect(signal).to.finish());
    assertFail(test_expect(signal).toNot.finish(), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).will.finish());
    assertPass(test_expect(signal).willNot.finish());
    
    assertPass(test_expect(signal).willContinueTo.finish());
    assertFail(test_expect(signal).willNotContinueTo.finish(), failureString);
}

- (void) test_error {
    RACSignal *signal = [[[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] concat:[RACSignal error:LLSpecError]] setNameWithFormat:@"foo"];
    NSString *failureString = @"expected: actual foo to not finish, got: finished with error";
    
    assertPass(test_expect(signal).to.finish());
    assertFail(test_expect(signal).toNot.finish(), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).will.finish());
    assertPass(test_expect(signal).willNot.finish());
    
    assertPass(test_expect(signal).will.finish());
    assertFail(test_expect(signal).willNotContinueTo.finish(), failureString);
}

- (void) test_nonCompleted {
    RACSignal *signal = [[[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] concat:RACSignal.never] setNameWithFormat:@"foo"];
    NSString *failureString = @"expected: actual foo to finish";
    
    assertPass(test_expect(signal).toNot.finish());
    assertFail(test_expect(signal).to.finish(), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willNot.finish());
    assertFail(test_expect(signal).will.finish(), failureString);
    
    assertPass(test_expect(signal).willNotContinueTo.finish());
    assertFail(test_expect(signal).willContinueTo.finish(), failureString);
}

@end
