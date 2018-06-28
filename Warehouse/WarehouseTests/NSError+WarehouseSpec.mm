// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "NSError+Warehouse.h"

SpecBegin(NSError_Warehouse)
__block NSInteger code;
__block NSUUID *stepID;
__block NSUUID *projectID;
__block NSString *description;
__block NSError *underlyingError;
__block NSError *error;

beforeEach(^{
  code = 888;
  stepID = [[NSUUID alloc] initWithUUIDString:@"5A6CFD0C-0A1F-4572-9A41-2AA8AA072890"];
  projectID = [[NSUUID alloc] initWithUUIDString:@"30F36E05-514E-402E-B424-05AD49D28860"];
  description = @"the description of the error that caused the error";
  underlyingError = [NSError lt_errorWithCode:777];
});

context(@"whs_errorWithCode:associatedProject:description", ^{
  beforeEach(^{
    error = [NSError whs_errorWithCode:code associatedProjectID:projectID
                           description:@"%@", description];
  });

  it(@"should create an error with the given error code", ^{
    expect(error.code).to.equal(code);
  });

  it(@"should create an error with the given project ID", ^{
    expect(error.whs_associatedProjectID).to.equal(projectID);
  });

  it(@"should create an error with the given description", ^{
    expect(error.userInfo[kLTErrorDescriptionKey]).to.equal(description);
  });
});

context(@"whs_errorWithCode:associatedProject:underlyingError:description", ^{
  beforeEach(^{
    error = [NSError whs_errorWithCode:code associatedProjectID:projectID
                       underlyingError:underlyingError description:@"%@", description];
  });

  it(@"should create an error with the given error code", ^{
    expect(error.code).to.equal(code);
  });

  it(@"should create an error with the given project ID", ^{
    expect(error.whs_associatedProjectID).to.equal(projectID);
  });

  it(@"should create an error with the given description", ^{
    expect(error.userInfo[kLTErrorDescriptionKey]).to.equal(description);
  });

  it(@"should create an error with the given underlying error", ^{
    expect(error.userInfo[NSUnderlyingErrorKey]).to.equal(underlyingError);
  });
});

context(@"whs_errorWithCode:associatedProject:associatedStep:description", ^{
  beforeEach(^{
    error = [NSError whs_errorWithCode:code associatedProjectID:projectID associatedStepID:stepID
                           description:@"%@", description];
  });

  it(@"should create an error with the given error code", ^{
    expect(error.code).to.equal(code);
  });

  it(@"should create an error with the given project ID", ^{
    expect(error.whs_associatedProjectID).to.equal(projectID);
  });

  it(@"should create an error with the given step ID", ^{
    expect(error.whs_associatedStepID).to.equal(stepID);
  });

  it(@"should create an error with the given description", ^{
    expect(error.userInfo[kLTErrorDescriptionKey]).to.equal(description);
  });
});

context(@"whs_errorWithCode:associatedProject:associatedStep:underlyingError:description", ^{
  beforeEach(^{
    error = [NSError whs_errorWithCode:code associatedProjectID:projectID associatedStepID:stepID
                       underlyingError:underlyingError description:@"%@", description];
  });

  it(@"should create an error with the given error code", ^{
    expect(error.code).to.equal(code);
  });

  it(@"should create an error with the given project ID", ^{
    expect(error.whs_associatedProjectID).to.equal(projectID);
  });

  it(@"should create an error with the given step ID", ^{
    expect(error.whs_associatedStepID).to.equal(stepID);
  });

  it(@"should create an error with the given description", ^{
    expect(error.userInfo[kLTErrorDescriptionKey]).to.equal(description);
  });

  it(@"should create an error with the given underlying error", ^{
    expect(error.userInfo[NSUnderlyingErrorKey]).to.equal(underlyingError);
  });
});

SpecEnd
