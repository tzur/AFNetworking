// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUResourceProxy.h"

#import "LTGLContext.h"
#import "LTGPUResource.h"

@interface LTProxiedGPUResource : NSObject <LTGPUResource>
@property (strong, nonatomic) NSString *value;
@end

@implementation LTProxiedGPUResource

@synthesize context = _context;

- (instancetype)init {
  if (self = [super init]) {
    _context = [LTGLContext currentContext];
  }
  return self;
}

- (void)bind {}
- (void)unbind {}
- (void)bindAndExecute:(NS_NOESCAPE LTVoidBlock __unused)block {}

- (void)dispose {
  LTAssert(self.context == [LTGLContext currentContext]);
}

- (GLuint)name {
  return 7;
}

@end

/// Records KVO observations.
@interface LTTestObserver : NSObject

/// All changes that were recorded until now.
@property (strong, nonatomic) NSArray *changes;

@end

@implementation LTTestObserver

- (instancetype)init {
  if (self = [super init]) {
    _changes = @[];
  }
  return self;
}

- (void)observeValueForKeyPath:(NSString __unused *)keyPath
                      ofObject:(id __unused)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void __unused *)context {
  auto changes = [self.changes mutableCopy];
  [changes addObject:change[NSKeyValueChangeNewKey]];
  self.changes = [changes copy];
}

@end

SpecBegin(LTGPUResourceProxy)

context(@"proxy", ^{
  __block LTProxiedGPUResource *resource;
  __block LTGPUResourceProxy *proxy;
  __block LTProxiedGPUResource *proxiedResource;

  beforeEach(^{
    resource = [[LTProxiedGPUResource alloc] init];
    proxy = [[LTGPUResourceProxy alloc] initWithResource:resource];
    proxiedResource = (LTProxiedGPUResource *)proxy;
  });

  afterEach(^{
    proxiedResource = nil;
    proxy = nil;
    resource = nil;
  });

  it(@"should correctly perform KVO", ^{
    auto observer = [[LTTestObserver alloc] init];

    [proxiedResource addObserver:observer forKeyPath:@keypath(proxiedResource, value)
                         options:NSKeyValueObservingOptionInitial |
                                 NSKeyValueObservingOptionNew context:NULL];
    proxiedResource.value = @"foo";

    expect(observer.changes).to.equal(@[[NSNull null], @"foo"]);

    [proxiedResource removeObserver:observer forKeyPath:@keypath(proxiedResource, value)
                            context:NULL];
  });

  it(@"should correctly proxy messages", ^{
    expect(proxiedResource.name).to.equal(7);
  });

  it(@"should return proxied class", ^{
    expect(proxiedResource.class).to.equal([LTProxiedGPUResource class]);
  });

  it(@"should answer correctly to respondsToSelector:", ^{
    expect([proxiedResource respondsToSelector:@selector(name)]).to.beTruthy();
    expect([proxiedResource respondsToSelector:@selector(changes)]).to.beFalsy();
  });

  it(@"should respond to isEqual: correctly", ^{
    expect(proxiedResource).to.equal(resource);
  });

  it(@"should respond to isKindOfClass: correctly", ^{
    expect(proxiedResource).to.beKindOf(resource.class);
  });

  it(@"should return proxied hash", ^{
    expect(proxiedResource.hash).to.equal(resource.hash);
  });

  it(@"should return proxied superclass", ^{
    expect(proxiedResource.superclass).to.equal(resource.superclass);
  });

  it(@"should respond to isMemberOfClass: correctly", ^{
    expect(proxiedResource).beInstanceOf(resource.class);
  });

  it(@"should respond to conformsToProtocol: correctly", ^{
    expect(proxiedResource).conformTo(@protocol(LTGPUResource));
    expect(proxiedResource).respondTo(@selector(bind));
  });
});

it(@"should dispose on the resource's context", ^{
  auto queue = dispatch_queue_create("com.lightricks.LTEngine.ResourceProxy",
                                     DISPATCH_QUEUE_SERIAL);

  for (int i = 0; i < 1000; ++i) {
    LTVoidBlock block;

    @autoreleasepool {
      auto resource = [[LTProxiedGPUResource alloc] init];
      auto proxy = [[LTGPUResourceProxy alloc] initWithResource:resource];

      block = ^{
        @autoreleasepool {
          // Reference proxy to keep it alive.
          auto __unused localProxy = proxy;
        }
      };

      proxy = nil;
      resource = nil;
    }

    dispatch_async(queue, block);
  }

  dispatch_barrier_sync(queue, ^{});
});

SpecEnd
