#import "EXPMatchers+deliverValuesOnThread.h"

#import <ReactiveObjC/ReactiveObjC.h>

#import "LLReactiveMatchers.h"
#import "LLReactiveMatchersFixtures.h"

@interface EXPMatchers_deliverValuesOnThreadTests : XCTestCase
@end

@implementation EXPMatchers_deliverValuesOnThreadTests

- (void) test_noValuesIncorrect {
  RACSignal *signal = [RACSignal empty];
  NSThread *thread = [[NSThread alloc] init];
  NSString *failureString = [NSString stringWithFormat:@"First failure: expected values to be "
                             "delivered on thread %@ but no values were delivered.", thread];

  assertPass(test_expect(signal).toNot.deliverValuesOnThread(thread));
  assertFail(test_expect(signal).to.deliverValuesOnThread(thread), failureString);

  signal = [signal asyncySignal];
  assertPass(test_expect(signal).willNot.deliverValuesOnThread(thread));
  assertFail(test_expect(signal).will.deliverValuesOnThread(thread), failureString);

  assertPass(test_expect(signal).willNotContinueTo.deliverValuesOnThread(thread));
  assertFail(test_expect(signal).willContinueTo.deliverValuesOnThread(thread), failureString);
}

- (void) test_twoValuesCorrect {
  RACSubject *subject = [RACSubject subject];
  RACSignal *replayMultiThreadedSignal = [[[subject
                                         deliverOn:[RACScheduler scheduler]]
                                         merge:subject]
                                         replay];
  [subject sendNext:@"0"];
  NSString *failureString = [NSString stringWithFormat:@"First failure: expected values to not be "
                             "delivered on thread %@ but %@ were delivered on "
                             "threads %@", [NSThread mainThread], @[@0, @0],
                             [NSSet setWithArray:@[[NSThread mainThread]]]];

  assertPass(test_expect(replayMultiThreadedSignal).to.deliverValuesOnMainThread());
  assertFail(test_expect(replayMultiThreadedSignal).toNot.deliverValuesOnMainThread(),
             failureString);

  assertPass(test_expect(replayMultiThreadedSignal).will.deliverValuesOnMainThread());
  assertFail(test_expect(replayMultiThreadedSignal).willNot.deliverValuesOnMainThread(),
             failureString);

  assertPass(test_expect(replayMultiThreadedSignal).willContinueTo.deliverValuesOnMainThread());
  assertFail(test_expect(replayMultiThreadedSignal).willNotContinueTo.deliverValuesOnMainThread(),
             failureString);
}

- (void) test_twoValuesinCorrect {
  RACSubject *subject = [RACSubject subject];
  NSThread *thread = [[NSThread alloc] init];
  RACSignal *replayMultiThreadedSignal = [[[subject
                                         deliverOn:[RACScheduler scheduler]]
                                         merge:subject]
                                         replay];
  [subject sendNext:@"0"];
  NSString *failureString = [NSString stringWithFormat:@"First failure: expected values to be "
                             "delivered on thread %@ but %@ were delivered on "
                             "threads %@", thread, @[@0, @0],
                             [NSSet setWithArray:@[[NSThread mainThread]]]];

  assertPass(test_expect(replayMultiThreadedSignal).toNot.deliverValuesOnThread(thread));
  assertFail(test_expect(replayMultiThreadedSignal).to.deliverValuesOnThread(thread),
             failureString);

  assertPass(test_expect(replayMultiThreadedSignal).willNot.deliverValuesOnThread(thread));
  assertFail(test_expect(replayMultiThreadedSignal).will.deliverValuesOnThread(thread),
             failureString);

  assertPass(test_expect(replayMultiThreadedSignal).willNotContinueTo
             .deliverValuesOnThread(thread));
  assertFail(test_expect(replayMultiThreadedSignal).willContinueTo.deliverValuesOnThread(thread),
             failureString);
}

@end
