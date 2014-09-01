// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBoundedProperties.h"

#import "LTGLKitExtensions.h"

/// Returns a \c LTVector3 with epsilon in the i-th component and zeros in the rest.
LTVector3 LTVector3Epsilon(NSUInteger i) {
  LTParameterAssert(i < 3);
  LTVector3 v = LTVector3Zero;
  v.data()[i] = FLT_EPSILON;
  return v;
}

/// Returns a \c LTVector4 with epsilon in the i-th component and zeros in the rest.
LTVector4 LTVector4Epsilon(NSUInteger i) {
  LTParameterAssert(i < 4);
  LTVector4 v = LTVector4Zero;
  v.data()[i] = FLT_EPSILON;
  return v;
}

SpecBegin(LTBoundedProperties)

#pragma mark -
#pragma mark LTBoundedCGFloat
#pragma mark -

context(@"bounded CGFloat", ^{
  __block LTBoundedCGFloat *instance;
  __block LTBoundedCGFloat *instanceWithSetter;
  __block CGFloat setterOldValue;
  __block CGFloat setterNewValue;
  
  beforeEach(^{
    instance = [LTBoundedCGFloat min:0 max:1 default:0.5];
    instanceWithSetter = [LTBoundedCGFloat min:-1 max:0 default:-0.5
                              afterSetterBlock:^(CGFloat value, CGFloat oldValue) {
      setterOldValue = oldValue;
      setterNewValue = value;
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
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(setterOldValue).to.equal(instanceWithSetter.defaultValue);
    expect(setterNewValue).to.equal(instanceWithSetter.minValue);
  });
});

#pragma mark -
#pragma mark LTBoundedDouble
#pragma mark -

context(@"bounded double", ^{
  __block LTBoundedDouble *instance;
  __block LTBoundedDouble *instanceWithSetter;
  __block double setterOldValue;
  __block double setterNewValue;
  
  beforeEach(^{
    instance = [LTBoundedDouble min:0 max:1 default:0.5];
    instanceWithSetter = [LTBoundedDouble min:-1 max:0 default:-0.5
                             afterSetterBlock:^(double value, double oldValue) {
      setterOldValue = oldValue;
      setterNewValue = value;
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
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(setterOldValue).to.equal(instanceWithSetter.defaultValue);
    expect(setterNewValue).to.equal(instanceWithSetter.minValue);
  });
});

#pragma mark -
#pragma mark LTBoundedInteger
#pragma mark -

context(@"bounded NSInteger", ^{
  __block LTBoundedNSInteger *instance;
  __block LTBoundedNSInteger *instanceWithSetter;
  __block NSInteger setterOldValue;
  __block NSInteger setterNewValue;
  
  beforeEach(^{
    instance = [LTBoundedNSInteger min:0 max:5 default:1];
    instanceWithSetter = [LTBoundedNSInteger min:-5 max:0 default:-1
                                afterSetterBlock:^(NSInteger value, NSInteger oldValue) {
      setterOldValue = oldValue;
      setterNewValue = value;
    }];
  });
  
  it(@"should not initialize with the default initializer", ^{
    expect(^{
      instance = [[LTBoundedNSInteger alloc] init];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should raise when initializing with min > max", ^{
    expect(^{
      instance = [LTBoundedNSInteger min:1 max:0 default:0];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should raise when initializing with default not in range", ^{
    expect(^{
      instance = [LTBoundedNSInteger min:0 max:1 default:-1];
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instance = [LTBoundedNSInteger min:0 max:1 default:2];
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
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(setterOldValue).to.equal(instanceWithSetter.defaultValue);
    expect(setterNewValue).to.equal(instanceWithSetter.minValue);
  });
});

#pragma mark -
#pragma mark LTBoundedUInteger
#pragma mark -

context(@"bounded NSUInteger", ^{
  __block LTBoundedNSUInteger *instance;
  __block LTBoundedNSUInteger *instanceWithSetter;
  __block NSUInteger setterOldValue;
  __block NSUInteger setterNewValue;
  
  beforeEach(^{
    instance = [LTBoundedNSUInteger min:0 max:5 default:1];
    instanceWithSetter = [LTBoundedNSUInteger min:5 max:10 default:6
                                 afterSetterBlock:^(NSUInteger value, NSUInteger oldValue) {
      setterOldValue = oldValue;
      setterNewValue = value;
    }];
  });
  
  it(@"should not initialize with the default initializer", ^{
    expect(^{
      instance = [[LTBoundedNSUInteger alloc] init];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should raise when initializing with min > max", ^{
    expect(^{
      instance = [LTBoundedNSUInteger min:1 max:0 default:0];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should raise when initializing with default not in range", ^{
    expect(^{
      instance = [LTBoundedNSUInteger min:1 max:2 default:0];
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      instance = [LTBoundedNSUInteger min:0 max:1 default:2];
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
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(setterOldValue).to.equal(instanceWithSetter.defaultValue);
    expect(setterNewValue).to.equal(instanceWithSetter.minValue);
  });
});

#pragma mark -
#pragma mark LTBoundedLTVector3
#pragma mark -

context(@"bounded LTVector3", ^{
  __block LTBoundedLTVector3 *instance;
  __block LTBoundedLTVector3 *instanceWithSetter;
  __block LTVector3 setterOldValue;
  __block LTVector3 setterNewValue;
  
  beforeEach(^{
    instance =
        [LTBoundedLTVector3 min:LTVector3Zero max:LTVector3One default:0.5 * LTVector3One];
    instanceWithSetter = [LTBoundedLTVector3 min:-LTVector3One max:LTVector3Zero
                                          default:-0.5 * LTVector3One
                                 afterSetterBlock:^(LTVector3 value, LTVector3 oldValue) {
      setterOldValue = oldValue;
      setterNewValue = value;
    }];
  });
  
  it(@"should not initialize with the default initializer", ^{
    expect(^{
      instance = [[LTBoundedLTVector3 alloc] init];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should raise when initializing with min > max", ^{
    for (NSUInteger i = 0; i < 3; ++i) {
      expect(^{
        instance =
            [LTBoundedLTVector3 min:LTVector3Epsilon(i) max:LTVector3Zero default:LTVector3Zero];
      }).to.raise(NSInvalidArgumentException);
    }
  });
  
  it(@"should raise when initializing with default not in range", ^{
    for (NSUInteger i = 0; i < 3; ++i) {
      expect(^{
        instance =
            [LTBoundedLTVector3 min:LTVector3Zero max:LTVector3One default:-LTVector3Epsilon(i)];
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        instance = [LTBoundedLTVector3 min:LTVector3Zero max:LTVector3One
                                    default:LTVector3One + LTVector3Epsilon(i)];
      }).to.raise(NSInvalidArgumentException);
    }
  });
  
  it(@"should have default values", ^{
    expect(instance.minValue).to.beCloseToGLKVector(LTVector3Zero);
    expect(instance.maxValue).to.beCloseToGLKVector(LTVector3One);
    expect(instance.defaultValue).to.beCloseToGLKVector(0.5 * LTVector3One);
    expect(instance.value).to.beCloseToGLKVector(0.5 * LTVector3One);
    
    expect(instanceWithSetter.minValue).to.beCloseToGLKVector(-LTVector3One);
    expect(instanceWithSetter.maxValue).to.beCloseToGLKVector(LTVector3Zero);
    expect(instanceWithSetter.defaultValue).to.beCloseToGLKVector(-0.5 * LTVector3One);
    expect(instanceWithSetter.value).to.beCloseToGLKVector(-0.5 * LTVector3One);
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
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(setterOldValue).to.beCloseToGLKVector(instanceWithSetter.defaultValue);
    expect(setterNewValue).to.beCloseToGLKVector(instanceWithSetter.minValue);
  });
});

#pragma mark -
#pragma mark LTBoundedLTVector4
#pragma mark -

context(@"bounded LTVector4", ^{
  __block LTBoundedLTVector4 *instance;
  __block LTBoundedLTVector4 *instanceWithSetter;
  __block LTVector4 setterOldValue;
  __block LTVector4 setterNewValue;
  
  beforeEach(^{
    instance =
        [LTBoundedLTVector4 min:LTVector4Zero max:LTVector4One default:0.5 * LTVector4One];
    instanceWithSetter = [LTBoundedLTVector4 min:-LTVector4One max:LTVector4Zero
                                          default:-0.5 * LTVector4One
                                 afterSetterBlock:^(LTVector4 value, LTVector4 oldValue) {
      setterOldValue = oldValue;
      setterNewValue = value;
    }];
  });
  
  it(@"should not initialize with the default initializer", ^{
    expect(^{
      instance = [[LTBoundedLTVector4 alloc] init];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should raise when initializing with min > max", ^{
    for (NSUInteger i = 0; i < 4; ++i) {
      expect(^{
        instance =
            [LTBoundedLTVector4 min:LTVector4Epsilon(i) max:LTVector4Zero default:LTVector4Zero];
      }).to.raise(NSInvalidArgumentException);
    }
  });
  
  it(@"should raise when initializing with default not in range", ^{
    for (NSUInteger i = 0; i < 4; ++i) {
      expect(^{
        instance =
            [LTBoundedLTVector4 min:LTVector4Zero max:LTVector4One default:-LTVector4Epsilon(i)];
      }).to.raise(NSInvalidArgumentException);
      
      expect(^{
        instance = [LTBoundedLTVector4 min:LTVector4Zero max:LTVector4One
                                    default:LTVector4One + LTVector4Epsilon(i)];
      }).to.raise(NSInvalidArgumentException);
    }
  });
  
  it(@"should have default values", ^{
    expect(instance.minValue).to.beCloseToGLKVector(LTVector4Zero);
    expect(instance.maxValue).to.beCloseToGLKVector(LTVector4One);
    expect(instance.defaultValue).to.beCloseToGLKVector(0.5 * LTVector4One);
    expect(instance.value).to.beCloseToGLKVector(0.5 * LTVector4One);
    
    expect(instanceWithSetter.minValue).to.beCloseToGLKVector(-LTVector4One);
    expect(instanceWithSetter.maxValue).to.beCloseToGLKVector(LTVector4Zero);
    expect(instanceWithSetter.defaultValue).to.beCloseToGLKVector(-0.5 * LTVector4One);
    expect(instanceWithSetter.value).to.beCloseToGLKVector(-0.5 * LTVector4One);
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
    instanceWithSetter.value = instanceWithSetter.minValue;
    expect(setterOldValue).to.beCloseToGLKVector(instanceWithSetter.defaultValue);
    expect(setterNewValue).to.beCloseToGLKVector(instanceWithSetter.minValue);
  });
});

SpecEnd
