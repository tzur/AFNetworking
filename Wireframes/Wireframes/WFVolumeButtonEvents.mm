// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "WFVolumeButtonEvents.h"

#import "WFVolumeButtonEvent+NotificationName.h"

NS_ASSUME_NONNULL_BEGIN

/// Supported volume button events.
LTEnumImplement(NSUInteger, WFVolumeButtonEvent,
  /// Volume up button pressed.
  WFVolumeButtonEventVolumeUpPress,
  /// Volume up button released.
  WFVolumeButtonEventVolumeUpRelease,
  /// Volume down button pressed.
  WFVolumeButtonEventVolumeDownPress,
  /// Volume down button released.
  WFVolumeButtonEventVolumeDownRelease
);

/// When \c enable is \c YES the system will post
/// \c _UIApplicationVolume{Up,Down}Button{Up,Down}Notification notifications using the default
/// notification center upon device's volume button presses and releases.
///
/// @important it uses <tt>-[UIApplication setWantsVolumeButtonEvents:]</tt> undocumented API, of
/// the given \c application instance, which enables generation of volume button events by the
/// system. The exploration of its behaviour conducted by experimentation.
static void WFSetWantsVolumeButtonEvents(UIApplication *application, BOOL enable) {
  auto selector = NSSelectorFromString(@"setWantsVolumeButtonEvents:");
  auto _Nullable methodSignature = [application methodSignatureForSelector:selector];
  if (![application respondsToSelector:selector] || !methodSignature) {
    return;
  }
  auto invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
  invocation.selector = selector;
  [invocation setArgument:&enable atIndex:2];
  [invocation invokeWithTarget:application];
}

static NSMapTable<UIApplication *, NSNumber *> *WFApplicationListenersMap() {
  /// Maps instances of \c UIApplication to the number of volume button listeners for this
  /// application.
  static NSMapTable<UIApplication *, NSNumber *> *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory |
           NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory];

  });
  return map;
}

static NSLock *WFApplicationListenersMapLock() {
  /// Protects the \c applicationListenersMap from concurent mutations.
  static NSLock *lock;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    lock = [[NSLock alloc] init];
  });
  return lock;
}

static void WFAddVolumeButtonEventListenerForApplication(UIApplication *application) {
  auto lock = WFApplicationListenersMapLock();
  [lock lock];

  auto applicationListenersMap = WFApplicationListenersMap();
  auto _Nullable listeners = [applicationListenersMap objectForKey:application];
  if (!listeners) {
    WFSetWantsVolumeButtonEvents(application, YES);
    [applicationListenersMap setObject:@1U forKey:application];
    [lock unlock];
    return;
  }

  auto eventListenersCount = listeners.unsignedIntValue;
  ++eventListenersCount;
  [applicationListenersMap setObject:@(eventListenersCount) forKey:application];

  [lock unlock];
}

static void WFRemoveVolumeButtonEventListenerForApplication(UIApplication *application) {
  auto lock = WFApplicationListenersMapLock();
  [lock lock];

  auto applicationListenersMap = WFApplicationListenersMap();
  auto _Nullable listeners = [applicationListenersMap objectForKey:application];
  if (!listeners) {
    [lock unlock];
    return;
  }

  auto eventListenersCount = listeners.unsignedIntegerValue;
  --eventListenersCount;
  if (!eventListenersCount) {
    WFSetWantsVolumeButtonEvents(application, NO);
    [applicationListenersMap removeObjectForKey:application];
  } else {
    [applicationListenersMap setObject:@(eventListenersCount) forKey:application];
  }

  [lock unlock];
}

RACSignal<NSNumber *> *WFVolumeButtonEvents() {
  return WFVolumeButtonEvents([UIApplication sharedApplication]);
}

RACSignal<NSNumber *> *WFVolumeButtonEvents(UIApplication *application) {
  return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    WFAddVolumeButtonEventListenerForApplication(application);
    auto notificationCenter = [NSNotificationCenter defaultCenter];

    auto notificationSignals = [NSMutableArray<RACSignal *> array];
    [WFVolumeButtonEvent enumerateEnumUsingBlock:^(WFVolumeButtonEvent *value) {
      auto signal = [notificationCenter rac_addObserverForName:value.notificationName
                                                        object:nil];
      [notificationSignals addObject:signal];
    }];

    auto notificationDisposable = [[[RACSignal merge:notificationSignals]
        map:^WFVolumeButtonEvent * _Nullable(NSNotification * _Nullable notification) {
          return [WFVolumeButtonEvent volumeButtonEventFromNotificationName:nn(notification.name)];
        }]
        subscribe:subscriber];
    auto changesDisposable = [RACDisposable disposableWithBlock:^{
      WFRemoveVolumeButtonEventListenerForApplication(application);
    }];

    return [RACCompoundDisposable compoundDisposableWithDisposables:@[
      notificationDisposable,
      changesDisposable
    ]];
  }];
}

NS_ASSUME_NONNULL_END
