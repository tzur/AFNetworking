// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIShootButtonDrawer.h"

SpecBegin(CUIShootButtonDrawer)

__block id traitsMock;

beforeEach(^{
  traitsMock = OCMProtocolMock(@protocol(CUIShootButtonTraits));
});

context(@"CUIOvalDrawer", ^{
  __block CUIOvalDrawer *drawer;

  beforeEach(^{
    drawer = [[CUIOvalDrawer alloc] init];
  });
  
  it(@"should inquire the button traits for its bounds", ^{
    [drawer drawToButton:traitsMock];
    
    OCMVerify([traitsMock bounds]);
  });

  it(@"should inquire the button traits for its highlighted mode", ^{
    [drawer drawToButton:traitsMock];
    
    OCMVerify([traitsMock isHighlighted]);
  });
});

context(@"CUIRectDrawer", ^{
  __block CUIRectDrawer *drawer;
  
  beforeEach(^{
    drawer = [[CUIRectDrawer alloc] init];
  });
  
  it(@"should inquire the button traits for its bounds", ^{
    [drawer drawToButton:traitsMock];
    
    OCMVerify([traitsMock bounds]);
  });
  
  it(@"should inquire the button traits for its highlighted mode", ^{
    [drawer drawToButton:traitsMock];
    
    OCMVerify([traitsMock isHighlighted]);
  });
});

context(@"CUIArcDrawer", ^{
  __block CUIArcDrawer *drawer;
  
  beforeEach(^{
    drawer = [[CUIArcDrawer alloc] init];
  });
  
  it(@"should inquire the button traits for its bounds", ^{
    [drawer drawToButton:traitsMock];
    
    OCMVerify([traitsMock bounds]);
  });
});

context(@"CUIProgressRingDrawer", ^{
  __block CUIProgressRingDrawer *drawer;
    
  beforeEach(^{
    drawer = [[CUIProgressRingDrawer alloc] init];
  });
  
  it(@"should inquire the button traits for its bounds", ^{
    [drawer drawToButton:traitsMock];
    
    OCMVerify([traitsMock bounds]);
  });

  it(@"should inquire the button traits for its progress state", ^{
    [drawer drawToButton:traitsMock];
    
    OCMVerify([(id<CUIShootButtonTraits>)traitsMock progress]);
  });
});

SpecEnd
