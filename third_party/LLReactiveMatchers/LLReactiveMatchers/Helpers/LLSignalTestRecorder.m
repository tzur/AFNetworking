//
//  LLSignalTestRecorder.m
//  LLReactiveMatchers
//
//  Created by Lawrence Lomax on 10/12/2013.
//
//

#import "LLSignalTestRecorder.h"

#import <Expecta/Expecta.h>

#import "RACSignal+LLSubscriptionCounting.h"
#import "LLReactiveMatchersHelpers.h"

@interface LLSignalTestRecorder ()

@property (nonatomic, strong) RACSignal *originalSignal;

@property (nonatomic, strong) RACReplaySubject *passthrough;
@property (nonatomic, strong) RACDisposable *disposable;

@property (nonatomic, assign) BOOL receivedCompletedEvent;
@property (nonatomic, assign) BOOL receivedErrorEvent;

@property (nonatomic, strong) NSMutableArray *receivedEvents;
@property (nonatomic, strong) NSError *receivedError;

@property (nonatomic, strong) NSMutableSet *activeThreadsInReceivedEvents;

@end

@implementation LLSignalTestRecorder

- (id) init {
    if( (self = [super init]) ) {
        self.receivedEvents = [NSMutableArray array];
        self.activeThreadsInReceivedEvents = [NSMutableSet set];
        self.passthrough = [RACReplaySubject replaySubjectWithCapacity:RACReplaySubjectUnlimitedCapacity];
        [self startCountingSubscriptions];
    }
    return self;
}

+ (instancetype) recordWithSignal:(RACSignal *)signal {
    NSAssert(signal != nil, @"Signal should not be nil");

    LLSignalTestRecorder *recorder = [[LLSignalTestRecorder alloc] init];
    [recorder subscribeToSignal:signal];
    return recorder;
}

+ (instancetype) recorderThatSendsValuesThenCompletes:(id)values {
    LLSignalTestRecorder *recorder = [LLSignalTestRecorder recroderThatSendsValues:values];
    recorder.receivedCompletedEvent = YES;
    return recorder;
}

+ (instancetype) recorderThatSendsValues:(id)values thenErrors:(NSError *)error {
    LLSignalTestRecorder *recorder = [LLSignalTestRecorder recroderThatSendsValues:values];
    recorder.receivedError = error;
    recorder.receivedErrorEvent = YES;
    return recorder;
}

+ (instancetype) recroderThatSendsValues:(id)values {
    NSAssert(values != nil, @"Values should not be nil");

    LLSignalTestRecorder *recorder = [[LLSignalTestRecorder alloc] init];
    recorder.receivedEvents = [values mutableCopy];
    recorder.activeThreadsInReceivedEvents = [NSMutableSet setWithArray:@[[NSThread currentThread]]];
    return recorder;
}

- (void) dealloc {
    [self.disposable dispose];
}

- (void) subscribeToSignal:(RACSignal *)signal {
    [self setNameWithFormat:@"TestRecorder [%@]", signal.name];
    [signal startCountingSubscriptions];

    self.originalSignal = signal;

    @rac_weakify(self);
    RACSignal *locallyRecordingSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        return [signal subscribeNext:^(id x) {
            @rac_strongify(self);
            if (!self) {
                return;
            }
            @synchronized(self) {
                [self.receivedEvents addObject:LLRMArrayValueForSignalValue(x)];
                [self.activeThreadsInReceivedEvents addObject:[NSThread currentThread]];
            }

            [subscriber sendNext:x];
        } error:^(NSError *error) {
            @rac_strongify(self);
            if (!self) {
                return;
            }
            @synchronized(self) {
                self.receivedErrorEvent = YES;
                self.receivedError = error;
            }

            [subscriber sendError:error];
        } completed:^{
            @rac_strongify(self);
            if (!self) {
                return;
            }
            @synchronized(self) {
                self.receivedCompletedEvent = YES;
            }

            [subscriber sendCompleted];
        }];
    }];

    self.disposable = [locallyRecordingSignal subscribe:self.passthrough];
}

#pragma mark RACSignal

- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
    return [self.passthrough subscribe:subscriber];
}

#pragma mark Getters

- (NSArray *) values {
    @synchronized(self) {
        return [self.receivedEvents copy];
    }
}

- (NSUInteger) valuesSentCount {
    return self.values.count;
}

- (BOOL) haveErrored {
    @synchronized(self) {
        return self.receivedErrorEvent;
    }
}

- (BOOL) hasErrored {
    @synchronized(self) {
        return self.receivedErrorEvent;
    }
}

- (NSError *) error {
    @synchronized(self) {
        return self.receivedError;
    }
}

- (BOOL) hasCompleted {
    @synchronized(self) {
        return self.receivedCompletedEvent;
    }
}

- (BOOL) haveCompleted {
    @synchronized(self) {
        return self.receivedCompletedEvent;
    }
}

- (BOOL) hasFinished {
    @synchronized(self) {
        return self.receivedCompletedEvent || self.receivedErrorEvent;
    }
}

- (BOOL) haveFinished {
    @synchronized(self) {
        return self.receivedCompletedEvent || self.receivedErrorEvent;
    }
}

- (NSSet *) operatingThreads {
    @synchronized(self) {
        return [self.activeThreadsInReceivedEvents copy];
    }
}

- (NSUInteger) operatingThreadsCount {
    return self.operatingThreads.count;
}

#pragma mark Descriptions

- (NSString *) description {
    return self.originalSignalDescription;
}

- (NSString *) originalSignalDescription {
    return self.originalSignal.name;
}

- (NSString *) valuesDescription {
    return EXPDescribeObject(self.values);
}

- (NSString *) errorDescription {
    return EXPDescribeObject(self.error);
}

@end

@implementation RACSignal(LLSignalTestRecorder)

- (LLSignalTestRecorder *) testRecorder {
    return [LLSignalTestRecorder recordWithSignal:self];
}

@end

