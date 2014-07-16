// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBoundedProperties.h"

#import "LTGLKitExtensions.h"

/// Returns a \c GLKVector3 with epsilon in the i-th component and zeros in the rest.
GLKVector3 LTVector3Epsilon(NSUInteger i) {
  LTParameterAssert(i < 3);
  GLKVector3 v = GLKVector3Zero;
  v.v[i] = FLT_EPSILON;
  return v;
}

/// Returns a \c GLKVector4 with epsilon in the i-th component and zeros in the rest.
GLKVector4 LTVector4Epsilon(NSUInteger i) {
  LTParameterAssert(i < 4);
  GLKVector4 v = GLKVector4Zero;
  v.v[i] = FLT_EPSILON;
  return v;
}

SpecBegin(LTBoundedProperties)

__block BOOL customSetterCalled;

beforeEach(^{
  customSetterCalled = NO;
});

#pragma mark -
#pragma mark LTBoundedCGFloat
#pragma mark -

context(@"bounded CGFloat", ^{
  __block LTBoundedCGFloat *instance;
  __block LTBoundedCGFloat *instanceWithSetter;
  
  beforeEach(^{
    instance = [LTBoundedCGFloat min:0 max:1 default:0.5];
    instanceWithSetter = [LTBoundedCGFloat min:-1 max:0 default:-0.5 afterSetterBlock:^{
      customSetterCalled = YES;
    }];
});
  
  it(@"should not initialize with the default initializer", ^{
    expect(^{
      instance = [[LTBoundedCGFloat alloc] init];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should raise when initializing with min > max", ^{
    expect(^{
      instance = [LTBoundedCGFloat min:0.5 + FLT_EPSILON max:0.5 default:0.5];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should raise when initializing with default not in range", ^{
    expect(^{
      instance = [LTBoundedCGFloat min:0 max:1 default:-FLT_EPSILON];
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instance = [LTBoundedCGFloat min:0 max:1 default:1 + FLT_EPSILON];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should have default values", ^{
    expect(instance.minValue).to.equal(0);
    expect(instance.maxValue).to.equal(1);
    expect(instance.defaultValue).to.equal(0.5);
    expect(instance.value).to.equal(0.5);
    
    expect(instanceWithSetter.minValue).to.equal(-1);
    expect(instanceWithSetter.maxValue).to.equal(0);
    expect(instanceWithSetter.defaultValue).to.equal(-0.5);
    expect(instanceWithSetter.value).to.equal(-0.5);
  });

  it(@"should set values in range", ^{
    expect(instance.value).notTo.equal(instance.minValue);
    instance.value = instance.minValue;
    expect(instance.value).to.equal(instance.minValue);
    
    expect(instanceWithSetter.value).notTo.equal(instanceWithSetter.minValue);
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(instanceWithSetter.value).to.equal(instanceWithSetter.minValue);
  });
  
  it(@"should assert values on setters", ^{
    expect(^{
      instance.value = instance.minValue - FLT_EPSILON;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instance.value = instance.maxValue + FLT_EPSILON;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instanceWithSetter.value = instanceWithSetter.minValue - FLT_EPSILON;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instanceWithSetter.value = instanceWithSetter.maxValue + FLT_EPSILON;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should perform custom setter", ^{
    expect(customSetterCalled).to.beFalsy();
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(customSetterCalled).to.beTruthy();
  });
});

#pragma mark -
#pragma mark LTBoundedDouble
#pragma mark -

context(@"bounded double", ^{
  __block LTBoundedDouble *instance;
  __block LTBoundedDouble *instanceWithSetter;
  
  beforeEach(^{
    instance = [LTBoundedDouble min:0 max:1 default:0.5];
    instanceWithSetter = [LTBoundedDouble min:-1 max:0 default:-0.5 afterSetterBlock:^{
      customSetterCalled = YES;
    }];
  });
  
  it(@"should not initialize with the default initializer", ^{
    expect(^{
      instance = [[LTBoundedDouble alloc] init];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should raise when initializing with min > max", ^{
    expect(^{
      instance = [LTBoundedDouble min:0.5 + DBL_EPSILON max:0.5 default:0.5];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should raise when initializing with default not in range", ^{
    expect(^{
      instance = [LTBoundedDouble min:0 max:1 default:-DBL_EPSILON];
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instance = [LTBoundedDouble min:0 max:1 default:1 + DBL_EPSILON];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should have default values", ^{
    expect(instance.minValue).to.equal(0);
    expect(instance.maxValue).to.equal(1);
    expect(instance.defaultValue).to.equal(0.5);
    expect(instance.value).to.equal(0.5);
    
    expect(instanceWithSetter.minValue).to.equal(-1);
    expect(instanceWithSetter.maxValue).to.equal(0);
    expect(instanceWithSetter.defaultValue).to.equal(-0.5);
    expect(instanceWithSetter.value).to.equal(-0.5);
  });
  
  it(@"should set values in range", ^{
    expect(instance.value).notTo.equal(instance.minValue);
    instance.value = instance.minValue;
    expect(instance.value).to.equal(instance.minValue);
    
    expect(instanceWithSetter.value).notTo.equal(instanceWithSetter.minValue);
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(instanceWithSetter.value).to.equal(instanceWithSetter.minValue);
  });
  
  it(@"should assert values on setters", ^{
    expect(^{
      instance.value = instance.minValue - DBL_EPSILON;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instance.value = instance.maxValue + DBL_EPSILON;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instanceWithSetter.value = instanceWithSetter.minValue - DBL_EPSILON;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instanceWithSetter.value = instanceWithSetter.maxValue + DBL_EPSILON;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should perform custom setter", ^{
    expect(customSetterCalled).to.beFalsy();
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(customSetterCalled).to.beTruthy();
  });
});

#pragma mark -
#pragma mark LTBoundedInteger
#pragma mark -

context(@"bounded NSInteger", ^{
  __block LTBoundedInteger *instance;
  __block LTBoundedInteger *instanceWithSetter;
  
  beforeEach(^{
    instance = [LTBoundedInteger min:0 max:5 default:1];
    instanceWithSetter = [LTBoundedInteger min:-5 max:0 default:-1 afterSetterBlock:^{
      customSetterCalled = YES;
    }];
  });
  
  it(@"should not initialize with the default initializer", ^{
    expect(^{
      instance = [[LTBoundedInteger alloc] init];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should raise when initializing with min > max", ^{
    expect(^{
      instance = [LTBoundedInteger min:1 max:0 default:0];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should raise when initializing with default not in range", ^{
    expect(^{
      instance = [LTBoundedInteger min:0 max:1 default:-1];
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instance = [LTBoundedInteger min:0 max:1 default:2];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should have default values", ^{
    expect(instance.minValue).to.equal(0);
    expect(instance.maxValue).to.equal(5);
    expect(instance.defaultValue).to.equal(1);
    expect(instance.value).to.equal(1);
    
    expect(instanceWithSetter.minValue).to.equal(-5);
    expect(instanceWithSetter.maxValue).to.equal(0);
    expect(instanceWithSetter.defaultValue).to.equal(-1);
    expect(instanceWithSetter.value).to.equal(-1);
  });
  
  it(@"should set values in range", ^{
    expect(instance.value).notTo.equal(instance.minValue);
    instance.value = instance.minValue;
    expect(instance.value).to.equal(instance.minValue);
    
    expect(instanceWithSetter.value).notTo.equal(instanceWithSetter.minValue);
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(instanceWithSetter.value).to.equal(instanceWithSetter.minValue);
  });
  
  it(@"should assert values on setters", ^{
    expect(^{
      instance.value = instance.minValue - 1;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instance.value = instance.maxValue + 1;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instanceWithSetter.value = instanceWithSetter.minValue - 1;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instanceWithSetter.value = instanceWithSetter.maxValue + 1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should perform custom setter", ^{
    expect(customSetterCalled).to.beFalsy();
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(customSetterCalled).to.beTruthy();
  });
});

#pragma mark -
#pragma mark LTBoundedUInteger
#pragma mark -

context(@"bounded NSUInteger", ^{
  __block LTBoundedUInteger *instance;
  __block LTBoundedUInteger *instanceWithSetter;
  
  beforeEach(^{
    instance = [LTBoundedUInteger min:0 max:5 default:1];
    instanceWithSetter = [LTBoundedUInteger min:5 max:10 default:6 afterSetterBlock:^{
      customSetterCalled = YES;
    }];
  });
  
  it(@"should not initialize with the default initializer", ^{
    expect(^{
      instance = [[LTBoundedUInteger alloc] init];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should raise when initializing with min > max", ^{
    expect(^{
      instance = [LTBoundedUInteger min:1 max:0 default:0];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should raise when initializing with default not in range", ^{
    expect(^{
      instance = [LTBoundedUInteger min:1 max:2 default:0];
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instance = [LTBoundedUInteger min:0 max:1 default:2];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should have default values", ^{
    expect(instance.minValue).to.equal(0);
    expect(instance.maxValue).to.equal(5);
    expect(instance.defaultValue).to.equal(1);
    expect(instance.value).to.equal(1);
    
    expect(instanceWithSetter.minValue).to.equal(5);
    expect(instanceWithSetter.maxValue).to.equal(10);
    expect(instanceWithSetter.defaultValue).to.equal(6);
    expect(instanceWithSetter.value).to.equal(6);
  });
  
  it(@"should set values in range", ^{
    expect(instance.value).notTo.equal(instance.minValue);
    instance.value = instance.minValue;
    expect(instance.value).to.equal(instance.minValue);
    
    expect(instanceWithSetter.value).notTo.equal(instanceWithSetter.minValue);
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(instanceWithSetter.value).to.equal(instanceWithSetter.minValue);
  });
  
  it(@"should assert values on setters", ^{
    expect(^{
      instance.value = instance.minValue - 1;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instance.value = instance.maxValue + 1;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instanceWithSetter.value = instanceWithSetter.minValue - 1;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instanceWithSetter.value = instanceWithSetter.maxValue + 1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should perform custom setter", ^{
    expect(customSetterCalled).to.beFalsy();
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(customSetterCalled).to.beTruthy();
  });
});

#pragma mark -
#pragma mark LTBoundedGLKVector3
#pragma mark -

context(@"bounded GLKVector3", ^{
  __block LTBoundedGLKVector3 *instance;
  __block LTBoundedGLKVector3 *instanceWithSetter;
  
  beforeEach(^{
    instance =
        [LTBoundedGLKVector3 min:GLKVector3Zero max:GLKVector3One default:0.5 * GLKVector3One];
    instanceWithSetter = [LTBoundedGLKVector3 min:-GLKVector3One max:GLKVector3Zero
                                          default:-0.5 * GLKVector3One afterSetterBlock:^{
      customSetterCalled = YES;
    }];
  });
  
  it(@"should not initialize with the default initializer", ^{
    expect(^{
      instance = [[LTBoundedGLKVector3 alloc] init];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should raise when initializing with min > max", ^{
    for (NSUInteger i = 0; i < 3; ++i) {
      expect(^{
        instance =
            [LTBoundedGLKVector3 min:LTVector3Epsilon(i) max:GLKVector3Zero default:GLKVector3Zero];
      }).to.raise(NSInvalidArgumentException);
    }
  });
  
  it(@"should raise when initializing with default not in range", ^{
    for (NSUInteger i = 0; i < 3; ++i) {
      expect(^{
        instance =
            [LTBoundedGLKVector3 min:GLKVector3Zero max:GLKVector3One default:-LTVector3Epsilon(i)];
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        instance = [LTBoundedGLKVector3 min:GLKVector3Zero max:GLKVector3One
                                    default:GLKVector3One + LTVector3Epsilon(i)];
      }).to.raise(NSInvalidArgumentException);
    }
  });
  
  it(@"should have default values", ^{
    expect(instance.minValue).to.beCloseToGLKVector(GLKVector3Zero);
    expect(instance.maxValue).to.beCloseToGLKVector(GLKVector3One);
    expect(instance.defaultValue).to.beCloseToGLKVector(0.5 * GLKVector3One);
    expect(instance.value).to.beCloseToGLKVector(0.5 * GLKVector3One);
    
    expect(instanceWithSetter.minValue).to.beCloseToGLKVector(-GLKVector3One);
    expect(instanceWithSetter.maxValue).to.beCloseToGLKVector(GLKVector3Zero);
    expect(instanceWithSetter.defaultValue).to.beCloseToGLKVector(-0.5 * GLKVector3One);
    expect(instanceWithSetter.value).to.beCloseToGLKVector(-0.5 * GLKVector3One);
  });
  
  it(@"should set values in range", ^{
    expect(instance.value).notTo.beCloseToGLKVector(instance.minValue);
    instance.value = instance.minValue;
    expect(instance.value).to.beCloseToGLKVector(instance.minValue);
    
    expect(instanceWithSetter.value).notTo.beCloseToGLKVector(instanceWithSetter.minValue);
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(instanceWithSetter.value).to.beCloseToGLKVector(instanceWithSetter.minValue);
  });
  
  it(@"should assert values on setters", ^{
    for (NSUInteger i = 0; i < 3; ++i) {
      expect(^{
        instance.value = instance.minValue - LTVector3Epsilon(i);
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        instance.value = instance.maxValue + LTVector3Epsilon(i);
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        instanceWithSetter.value = instanceWithSetter.minValue - LTVector3Epsilon(i);
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        instanceWithSetter.value = instanceWithSetter.maxValue + LTVector3Epsilon(i);
      }).to.raise(NSInvalidArgumentException);
    }
  });
  
  it(@"should perform custom setter", ^{
    expect(customSetterCalled).to.beFalsy();
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(customSetterCalled).to.beTruthy();
  });
});

#pragma mark -
#pragma mark LTBoundedGLKVector4
#pragma mark -

context(@"bounded GLKVector4", ^{
  __block LTBoundedGLKVector4 *instance;
  __block LTBoundedGLKVector4 *instanceWithSetter;
  
  beforeEach(^{
    instance =
        [LTBoundedGLKVector4 min:GLKVector4Zero max:GLKVector4One default:0.5 * GLKVector4One];
    instanceWithSetter = [LTBoundedGLKVector4 min:-GLKVector4One max:GLKVector4Zero
                                          default:-0.5 * GLKVector4One afterSetterBlock:^{
      customSetterCalled = YES;
    }];
  });
  
  it(@"should not initialize with the default initializer", ^{
    expect(^{
      instance = [[LTBoundedGLKVector4 alloc] init];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should raise when initializing with min > max", ^{
    for (NSUInteger i = 0; i < 4; ++i) {
      expect(^{
        instance =
            [LTBoundedGLKVector4 min:LTVector4Epsilon(i) max:GLKVector4Zero default:GLKVector4Zero];
      }).to.raise(NSInvalidArgumentException);
    }
  });
  
  it(@"should raise when initializing with default not in range", ^{
    for (NSUInteger i = 0; i < 4; ++i) {
      expect(^{
        instance =
            [LTBoundedGLKVector4 min:GLKVector4Zero max:GLKVector4One default:-LTVector4Epsilon(i)];
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        instance = [LTBoundedGLKVector4 min:GLKVector4Zero max:GLKVector4One
                                    default:GLKVector4One + LTVector4Epsilon(i)];
      }).to.raise(NSInvalidArgumentException);
    }
  });
  
  it(@"should have default values", ^{
    expect(instance.minValue).to.beCloseToGLKVector(GLKVector4Zero);
    expect(instance.maxValue).to.beCloseToGLKVector(GLKVector4One);
    expect(instance.defaultValue).to.beCloseToGLKVector(0.5 * GLKVector4One);
    expect(instance.value).to.beCloseToGLKVector(0.5 * GLKVector4One);
    
    expect(instanceWithSetter.minValue).to.beCloseToGLKVector(-GLKVector4One);
    expect(instanceWithSetter.maxValue).to.beCloseToGLKVector(GLKVector4Zero);
    expect(instanceWithSetter.defaultValue).to.beCloseToGLKVector(-0.5 * GLKVector4One);
    expect(instanceWithSetter.value).to.beCloseToGLKVector(-0.5 * GLKVector4One);
  });
  
  it(@"should set values in range", ^{
    expect(instance.value).notTo.beCloseToGLKVector(instance.minValue);
    instance.value = instance.minValue;
    expect(instance.value).to.beCloseToGLKVector(instance.minValue);
    
    expect(instanceWithSetter.value).notTo.beCloseToGLKVector(instanceWithSetter.minValue);
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(instanceWithSetter.value).to.beCloseToGLKVector(instanceWithSetter.minValue);
  });
  
  it(@"should assert values on setters", ^{
    for (NSUInteger i = 0; i < 4; ++i) {
      expect(^{
        instance.value = instance.minValue - LTVector4Epsilon(i);
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        instance.value = instance.maxValue + LTVector4Epsilon(i);
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        instanceWithSetter.value = instanceWithSetter.minValue - LTVector4Epsilon(i);
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        instanceWithSetter.value = instanceWithSetter.maxValue + LTVector4Epsilon(i);
      }).to.raise(NSInvalidArgumentException);
    }
  });
  
  it(@"should perform custom setter", ^{
    expect(customSetterCalled).to.beFalsy();
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(customSetterCalled).to.beTruthy();
  });
});

SpecEnd
