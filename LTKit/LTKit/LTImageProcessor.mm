// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"

@interface LTImageProcessor ()

@property (strong, nonatomic) NSMutableDictionary *inputModel;
@property (strong, nonatomic) NSArray *inputs;
@property (strong, nonatomic) NSMutableArray *mutableOutputs;

@end

@implementation LTImageProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInputs:(NSArray *)inputs outputs:(NSArray *)outputs {
  if (self = [super init]) {
    [self validateInputs:inputs andOutputs:outputs];

    self.inputs = inputs;
    self.mutableOutputs = [outputs copy];
    self.inputModel = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)validateInputs:(NSArray *)inputs andOutputs:(NSArray *)outputs {
  LTParameterAssert(inputs.count, @"Given input array should contain at least one texture");
  LTParameterAssert(outputs.count, @"Given output array should contain at least one texture");

  for (id obj in [inputs arrayByAddingObjectsFromArray:outputs]) {
    LTParameterAssert([obj isKindOfClass:[LTTexture class]],
                      @"Given object is not of type LTTexture");
  }
}

#pragma mark -
#pragma mark Abstract methods
#pragma mark -

- (id<LTImageProcessorOutput>)process {
  LTAssert(NO, @"-[LTImageProcessor process] is an abstract method that should be overridden by "
           "subclasses");
}

#pragma mark -
#pragma mark Input model
#pragma mark -

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
  LTAssert(obj, @"Given object must not be nil");
  self.inputModel[key] = obj;
}

- (id)objectForKeyedSubscript:(NSString *)key {
  return self.inputModel[key];
}

#pragma mark -
#pragma mark Inputs / Outputs
#pragma mark -

- (NSArray *)outputs {
  return [self.mutableOutputs copy];
}

@end
