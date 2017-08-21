//
//  LLReactiveMatchersMessages.h
//  LLReactiveMatchers
//
//  Created by Lawrence Lomax on 12/12/2013.
//
//

#import <Foundation/Foundation.h>
#import "LLSignalTestRecorder.h"

@class RACSignal;

@interface LLReactiveMatchersMessageBuilder : NSObject

+ (instancetype) message;

- (instancetype) actual:(LLSignalTestRecorder *)actual;
- (instancetype) renderActualValues;
- (instancetype) renderActualError;
- (instancetype) actualBehaviour:(NSString *)behaviour;

- (instancetype) expected:(LLSignalTestRecorder *)actual;
- (instancetype) renderExpectedValues;
- (instancetype) renderExpectedError;
- (instancetype) renderExpectedNot;
- (instancetype) expectedBehaviour:(NSString *)behaviour;

- (NSString *) build;

+ (NSString *) actualNotCorrectClass:(id)actual;
+ (NSString *) expectedShouldBeOfClass:(Class)correctClass;
+ (NSString *) expectedNotCorrectClass:(id)expected;

+ (NSString *) actualNotFinished:(LLSignalTestRecorder *)actual;
+ (NSString *) expectedNotFinished:(LLSignalTestRecorder *)expected;


+ (NSString *) expectedSignalDidNotRecordSubscriptions:(RACSignal *)signal;
+ (NSString *) expectedSignal:(RACSignal *)signal toBeSubscribedTo:(NSInteger)expected actual:(NSInteger)actual;
+ (NSString *) expectedSignal:(RACSignal *)signal toNotBeSubscribedTo:(NSInteger)expected;

@end
