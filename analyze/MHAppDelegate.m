//
//  MHAppDelegate.m
//  analyze
//
//  Created by Mike Hays on 10/19/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import "MHAppDelegate.h"
#import "MHOpenGLAnalyzeView.h"
#import "MHCoreAudioShovel.h"

@implementation MHAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    MHOpenGLAnalyzeView *view = [[self window] contentView];
    [view setShovel:[[MHCoreAudioShovel alloc] init]];
}

@end
