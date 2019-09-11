//
//  SloggerTestsObjC.m
//  Slogger
//
//  Created by David Goodine on 11/10/15.
//  Copyright © 2015 David Goodine. All rights reserved.
//

#import "SloggerTestsObjC.h"
@import Slogger;

static SloggerObjC *slog;

@implementation SloggerTestsObjC

- (void) setUp {
    // Ditching this for now (probably permanently
    // slog = [[SloggerObjC alloc] initWithDefaultLevel:LevelInfo];
}

- (void) testObjC {
//  NSLog(@"log: %@", slog);
}

@end
