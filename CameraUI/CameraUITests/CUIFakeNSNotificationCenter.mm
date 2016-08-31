// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIFakeNSNotificationCenter.h"

#import "NSObject+DynamicDispatch.h"

NS_ASSUME_NONNULL_BEGIN

/// Holds the observer posting data.
@interface CUIObserverPostingData : NSObject
@property (weak, nonatomic) id observer;
@property (nonatomic) SEL notificationSelector;
@property (strong, nonatomic, nullable) NSString *notificationName;
@property (strong, nonatomic, nullable) id notificationSender;
@end

@implementation CUIObserverPostingData
@end

/// Runs the inner block when \c runBlock: is called.
@interface CUIBlockRunner : NSObject
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithBlock:(void (^)(NSNotification *note))block;
- (void)runBlock:(NSNotification *)note;
@property (readonly, nonatomic) void (^block)(NSNotification *note);
@end

@implementation CUIBlockRunner
- (instancetype)initWithBlock:(void (^)(NSNotification *note))block {
  if (self = [super init]) {
    _block = [block copy];
  }
  return self;
}
- (void)runBlock:(NSNotification *)note {
  self.block(note);
}
@end

@interface CUIFakeNSNotificationCenter ()
@property (strong, nonatomic) NSMutableArray<CUIObserverPostingData *> *observers;
@end

@implementation CUIFakeNSNotificationCenter

- (instancetype)init {
  if (self = [super init]) {
    self.observers = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSString *)aName
             object:(nullable id)notificationSender {
  CUIObserverPostingData *observerPostingData = [[CUIObserverPostingData alloc] init];
  observerPostingData.observer = observer;
  observerPostingData.notificationSelector = aSelector;
  observerPostingData.notificationName = aName;
  observerPostingData.notificationSender = notificationSender;
  [self.observers addObject:observerPostingData];
}

- (id <NSObject>)addObserverForName:(nullable NSString *)name object:(nullable id)obj
                              queue:(nullable NSOperationQueue __unused *)queue
                         usingBlock:(void (^)(NSNotification *note))block {
  CUIBlockRunner *blockRunner = [[CUIBlockRunner alloc] initWithBlock:block];
  [self addObserver:blockRunner selector:@selector(runBlock:) name:name object:obj];
  return blockRunner;
}

- (void)postNotification:(NSNotification *)notification {
  for (CUIObserverPostingData *observerPostingData in self.observers) {
    if (observerPostingData.notificationName &&
        ![observerPostingData.notificationName isEqualToString:notification.name]) {
      continue;
    }
    if (observerPostingData.notificationSender &&
        observerPostingData.notificationSender != notification.object) {
      continue;
    }
    [observerPostingData.observer lt_dispatchSelector:observerPostingData.notificationSelector
                                           withObject:notification];
  }
}

- (void)postNotificationName:(NSString *)aName object:(nullable id)anObject {
  [self postNotificationName:aName object:anObject userInfo:nil];
}

- (void)postNotificationName:(NSString *)aName object:(nullable id)anObject
                    userInfo:(nullable NSDictionary *)aUserInfo {
  [self postNotification:[NSNotification notificationWithName:aName object:anObject
                                                     userInfo:aUserInfo]];
}

- (void)removeObserver:(id)observer {
  self.observers = [[self.observers.rac_sequence
      filter:^BOOL(CUIObserverPostingData *observerPostingData) {
        return observerPostingData.observer != observer;
      }].array mutableCopy];
}

- (void)removeObserver:(id)observer name:(nullable NSString *)aName object:(nullable id)anObject {
  self.observers = [[self.observers.rac_sequence
      filter:^BOOL(CUIObserverPostingData *observerPostingData) {
        return (observerPostingData.observer != observer ||
                observerPostingData.notificationName != aName ||
                observerPostingData.notificationSender != anObject);
      }].array mutableCopy];
}

- (NSUInteger)currentlyConnectedObserverCount {
  return self.observers.count;
}

@end

NS_ASSUME_NONNULL_END
