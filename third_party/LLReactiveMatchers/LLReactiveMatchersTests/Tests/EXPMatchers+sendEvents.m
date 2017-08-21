#import "EXPMatchers+sendEvents.h"

#import <ReactiveObjC/ReactiveObjC.h>

#import "LLReactiveMatchers.h"
#import "LLReactiveMatchersFixtures.h"

@interface EXPMatchers_sendEventsTests : XCTestCase
@end

@implementation EXPMatchers_sendEventsTests

- (void) test_nonSignalActual {
    NSArray *signal = @[@1, @2, @3];
    RACSignal *expected = [LLReactiveMatchersFixtures values:@[@2, @3]];
    NSString *failureString = [NSString stringWithFormat:@"expected: actual to be a signal or recorder: %@", signal];

    assertFail(test_expect(signal).to.sendEvents(expected), failureString);
    assertFail(test_expect(signal).toNot.sendEvents(expected), failureString);
}

- (void) test_identicalEventsCompletion {
    RACSignal *signal = [[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] setNameWithFormat:@"foo"];
    RACSignal *expected = [[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] setNameWithFormat:@"bar"];
    NSString *failureString = @"expected: actual foo to not have events that are identical to expected bar";
    
    assertPass(test_expect(signal).to.sendEvents(expected));
    assertFail(test_expect(signal).toNot.sendEvents(expected), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).will.sendEvents(expected));
    assertPass(test_expect(signal).willNot.sendEvents(expected));
    
    assertPass(test_expect(signal).willContinueTo.sendEvents(expected));
    assertFail(test_expect(signal).willNotContinueTo.sendEvents(expected), failureString);
}

- (void) test_differentEventsCompletion {
    RACSignal *signal = [[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] setNameWithFormat:@"foo"];
    RACSignal *expected = [[LLReactiveMatchersFixtures values:@[@YES, @NO, @2]] setNameWithFormat:@"bar"];
    NSString *failureString = @"expected: actual foo to send values (1, 0, 2), got: (1, 0, 5) values sent";

    assertPass(test_expect(signal).toNot.sendEvents(expected));
    assertFail(test_expect(signal).to.sendEvents(expected), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willNot.sendEvents(expected));
    assertFail(test_expect(signal).will.sendEvents(expected), failureString);
    
    assertPass(test_expect(signal).willNotContinueTo.sendEvents(expected));
    assertFail(test_expect(signal).willContinueTo.sendEvents(expected), failureString);
}

- (void) test_identicalEventsIdenticalError {
    RACSignal *signal = [[[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] concat:[RACSignal error:LLSpecError]] setNameWithFormat:@"foo"];
    RACSignal *expected = [[[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] concat:[RACSignal error:LLSpecError]] setNameWithFormat:@"bar"];
    NSString *failureString = @"expected: actual foo to not have events that are identical to expected bar";
    
    assertPass(test_expect(signal).to.sendEvents(expected));
    assertFail(test_expect(signal).toNot.sendEvents(expected), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).will.sendEvents(expected));
    assertPass(test_expect(signal).willNot.sendEvents(expected));
    
    assertPass(test_expect(signal).willContinueTo.sendEvents(expected));
    assertFail(test_expect(signal).willNotContinueTo.sendEvents(expected), failureString);
}

- (void) test_identicalEventsDifferentErrors {
    RACSignal *signal = [[[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] concat:[RACSignal error:LLSpecError]] setNameWithFormat:@"foo"];
    RACSignal *expected = [[[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] concat:[RACSignal error:nil]] setNameWithFormat:@"bar"];
    NSString *failureString = @"expected: actual foo to finish in the same way as expected bar";
    
    assertPass(test_expect(signal).toNot.sendEvents(expected));
    assertFail(test_expect(signal).to.sendEvents(expected), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willNot.sendEvents(expected));
    assertFail(test_expect(signal).will.sendEvents(expected), failureString);
    
    assertPass(test_expect(signal).willNotContinueTo.sendEvents(expected));
    assertFail(test_expect(signal).willContinueTo.sendEvents(expected), failureString);
}

- (void) test_identicalEventsExpectedDidNotComplete {
    RACSignal *signal = [[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] setNameWithFormat:@"foo"];
    RACSignal *expected = [[[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] concat:RACSignal.never] setNameWithFormat:@"bar"];
    NSString *failureString = @"expected: expected bar to finish";
    
    assertPass(test_expect(signal).toNot.sendEvents(expected));
    assertFail(test_expect(signal).to.sendEvents(expected), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willNot.sendEvents(expected));
    assertFail(test_expect(signal).will.sendEvents(expected), failureString);
    
    assertPass(test_expect(signal).willNotContinueTo.sendEvents(expected));
    assertFail(test_expect(signal).willContinueTo.sendEvents(expected), failureString);
}

- (void) test_identicalValuesBothComplete {
    RACSignal *signal = [[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] setNameWithFormat:@"foo"];
    RACSignal *expected = [[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] setNameWithFormat:@"bar"];
    NSString *failureString = @"expected: actual foo to not have events that are identical to expected bar";
    
    assertPass(test_expect(signal).to.sendEvents(expected));
    assertFail(test_expect(signal).toNot.sendEvents(expected), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).will.sendEvents(expected));
    assertPass(test_expect(signal).willNot.sendEvents(expected));
    
    assertPass(test_expect(signal).willContinueTo.sendEvents(expected));
    assertFail(test_expect(signal).willNotContinueTo.sendEvents(expected), failureString);
}

- (void) test_identicalValuesDifferentCompletion {
    RACSignal *signal = [[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] setNameWithFormat:@"foo"];
    RACSignal *expected = [[[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] concat:[RACSignal error:LLSpecError]] setNameWithFormat:@"bar"];
    NSString *failureString = @"expected: actual foo to finish in the same way as expected bar";
    
    assertPass(test_expect(signal).toNot.sendEvents(expected));
    assertFail(test_expect(signal).to.sendEvents(expected), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willNot.sendEvents(expected));
    assertFail(test_expect(signal).will.sendEvents(expected), failureString);
    
    assertPass(test_expect(signal).willNotContinueTo.sendEvents(expected));
    assertFail(test_expect(signal).willContinueTo.sendEvents(expected), failureString);
}

- (void) test_differentValues {
    RACSignal *signal = [[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] setNameWithFormat:@"foo"];
    RACSignal *expected = [[LLReactiveMatchersFixtures values:@[@YES, @NO, @1]] setNameWithFormat:@"bar"];
    NSString *failureString = @"expected: actual foo to send values (1, 0, 1), got: (1, 0, 5) values sent";
    
    assertPass(test_expect(signal).toNot.sendEvents(expected));
    assertFail(test_expect(signal).to.sendEvents(expected), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willNot.sendEvents(expected));
    assertFail(test_expect(signal).will.sendEvents(expected), failureString);
    
    assertPass(test_expect(signal).willNotContinueTo.sendEvents(expected));
    assertFail(test_expect(signal).willContinueTo.sendEvents(expected), failureString);
}

- (void) test_differentValuesDifferentCompletion {
    RACSignal *signal = [[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] setNameWithFormat:@"foo"];
    RACSignal *expected = [[[LLReactiveMatchersFixtures values:@[@YES, @NO, @1]] concat:[RACSignal error:LLSpecError]] setNameWithFormat:@"bar"];
    NSString *failureString = @"expected: actual foo to send values (1, 0, 1), got: (1, 0, 5) values sent";
    
    assertPass(test_expect(signal).toNot.sendEvents(expected));
    assertFail(test_expect(signal).to.sendEvents(expected), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willNot.sendEvents(expected));
    assertFail(test_expect(signal).will.sendEvents(expected), failureString);
    
    assertPass(test_expect(signal).willNotContinueTo.sendEvents(expected));
    assertFail(test_expect(signal).willContinueTo.sendEvents(expected), failureString);
}

- (void) test_identicalValuesOneDidNotComplete {
    RACSignal *signal = [[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] setNameWithFormat:@"foo"];
    RACSignal *expected = [[[[LLReactiveMatchersFixtures values:@[@YES, @NO, @5]] concat:RACSignal.never] setNameWithFormat:@"foo"] setNameWithFormat:@"bar"];
    NSString *failureString = @"expected: expected bar to finish";
    
    assertPass(test_expect(signal).toNot.sendEvents(expected));
    assertFail(test_expect(signal).to.sendEvents(expected), failureString);
    
    signal = [signal asyncySignal];
    assertPass(test_expect(signal).willNot.sendEvents(expected));
    assertFail(test_expect(signal).will.sendEvents(expected), failureString);
    
    assertPass(test_expect(signal).willNotContinueTo.sendEvents(expected));
    assertFail(test_expect(signal).willContinueTo.sendEvents(expected), failureString);
}

@end
