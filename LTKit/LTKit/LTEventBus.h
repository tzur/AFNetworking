// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

NS_ASSUME_NONNULL_BEGIN

/// Provides a mechanism for broadcasting notifications about events that happened. Anyone can
/// broadcast and anyone can register to be notified, for any event.
/// Receivers register to a \c Class, and will be notified with all events that are of that class
/// or a subclass of it.
///
/// Receivers of the events are called synchronously from \c post:.
///
/// This class is inspired by Guava's EventBus, see
/// https://code.google.com/p/guava-libraries/wiki/EventBusExplained
@interface LTEventBus : NSObject

/// Registers to be notified when events of a specific class are posted. The target's selector will
/// be called when an event of this class, or a subclass of it, is posted.
///
/// The same target can be registered multiple times without limits, and will be called once for
/// each registration that matches the posted class.
/// For example: a target registers twice, for \c NSObject class and for \c NSString class. When a
/// \c NSString object is posted, the target is called twice. This will happen even if the same
/// selector is registered for both classes.
///
/// The method specified by \c selector must return void and accept a single object parameter, as in
/// @code
/// - (void)handleEvent:(id)object;
/// @endcode
/// Calling with any other signature will raise \c NSInvalidArgumentException. \c LTEventBus
/// guarantees the selector will be called only with a subtype of the class it was registered with.
///
/// \c target is held weakly. It is \b not required to unregister before \c dealloc. Deallocated
/// targets are automatically removed.
- (void)addObserver:(id)target selector:(SEL)selector forClass:(Class)objClass;

/// Registers to be notified when events of a specific protocol are posted. The target's selector
/// will be called when an event of this protocol, or a subprotocol of it, is posted.
///
/// The same target can be registered multiple times without limits, and will be called once for
/// each registration that matches the posted protocol.
/// For example: a target registers twice, for \c id<NSObject> and for \c id<NSURLProtocolClient>.
/// When a \c id<NSURLProtocolClient> object is posted, the target is called twice.
/// This will happen even if the same selector is registered for both protocols.
///
/// The method specified by \c selector must return void and accept a single object parameter, as in
/// @code
/// - (void)handleEvent:(id)object;
/// @endcode
/// Calling with any other signature will raise \c NSInvalidArgumentException. \c LTEventBus
/// guarantees the selector will be called only with an instance that conforms to a protocol that
/// is a subprotocol of the protocol it registered with.
///
/// \c target is held weakly. It is \b not required to unregister before \c dealloc. Deallocated
/// targets are automatically removed.
- (void)addObserver:(id)target selector:(SEL)selector forProtocol:(Protocol *)protocol;

/// Unregisters \c target from all events that are of class \c objClass or a subclass of it.
///
/// This may remove more than a single registration of \c target. For example: a target registers
/// twice, for \c NSValue class and for \c NSNumber class. Calling this method with \c NSValue
/// class will remove both registrations.
- (void)removeObserver:(id)target forClass:(Class)objClass;

/// Unregisters \c target from all events that are of protocol \c protocol or a subprotocol of it.
///
/// This may remove more than a single registration of \c target. For example: a target registers
/// twice, for \c id<NSObject> and for \c id<NSURLProtocolClient>. Calling this method with \c
/// id<NSObject> will remove both registrations.
- (void)removeObserver:(id)target forProtocol:(Protocol *)protocol;

/// Posts an event. This method synchronously calls the registered selector of every target that
/// registered for this event's class, any superclass, protocol or any superprotocol.
- (void)post:(id)object;

@end

NS_ASSUME_NONNULL_END
