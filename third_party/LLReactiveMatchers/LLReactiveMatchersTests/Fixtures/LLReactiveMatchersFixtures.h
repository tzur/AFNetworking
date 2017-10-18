//
//  LLReactiveMatchersFixtures.h
//  LLReactiveMatchers
//
//  Created by Lawrence Lomax on 6/12/2013.
//
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/RACSignal.h>

extern NSString *const LLReactiveMatcherFixtureErrorDomain;
extern NSError * LLReactiveMatchersFixtureError(void);

#define LLSpecError LLReactiveMatchersFixtureError()

@interface LLReactiveMatchersFixtures : NSObject

/// Values are sent and completes synchronously
+ (RACSignal *) values:(NSArray *)values;

@end

@interface RACSignal (LLRMTestHelpers)

// Delays events a little by sending them on a background scheduler
- (RACSignal *) asyncySignal;

@end
