//
//  MHOpenGLAnalyzeView.m
//  analyze
//
//  Created by Mike Hays on 11/8/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//


#import "MHOpenGLAnalyzeView.h"
#import "MHAnalyzeRenderer.h"

@implementation MHOpenGLAnalyzeView {
    MHAnalyzeRenderer *_renderer;

    CVDisplayLinkRef displayLink;
}


- (CVReturn)getFrameForTime:(const CVTimeStamp*)outputTime
{
    @autoreleasepool {
        [self drawView];
    }
	return kCVReturnSuccess;
}

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
									  const CVTimeStamp* now,
									  const CVTimeStamp* outputTime,
									  CVOptionFlags flagsIn,
									  CVOptionFlags* flagsOut,
									  void* displayLinkContext)
{
    CVReturn result = [(__bridge MHOpenGLAnalyzeView *)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (void)awakeFromNib
{
    NSOpenGLPixelFormatAttribute attrs[] =
	{
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAOpenGLProfile,
		NSOpenGLProfileVersion3_2Core,
		0
	};

	NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

	if (!pf)
	{
		NSLog(@"No OpenGL pixel format");
	}

    NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
	CGLEnable([context CGLContextObj], kCGLCECrashOnRemovedFunctions);
    [self setPixelFormat:pf];
    [self setOpenGLContext:context];
}

- (void)prepareOpenGL
{
	[super prepareOpenGL];
	[self initGL];
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void *)(self));
	CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);

	CVDisplayLinkStart(displayLink);

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowWillClose:)
												 name:NSWindowWillCloseNotification
											   object:[self window]];
}

- (void)windowWillClose:(NSNotification*)notification
{
	CVDisplayLinkStop(displayLink);
}

- (void)initGL
{
	[[self openGLContext] makeCurrentContext];

	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];

	_renderer = [[MHAnalyzeRenderer alloc] init];
}

- (void)reshape
{
	[super reshape];

	CGLLockContext([[self openGLContext] CGLContextObj]);

    NSRect viewRectPixels = [self bounds];
    [_renderer reshapeWithWidth:viewRectPixels.size.width AndHeight:viewRectPixels.size.height];

	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}


- (void)renewGState
{
	[[self window] disableScreenUpdatesUntilFlush];
	[super renewGState];
}

- (void)drawRect:(NSRect) theRect
{
	[self drawView];
}

- (void)drawView
{
	[[self openGLContext] makeCurrentContext];
	CGLLockContext([[self openGLContext] CGLContextObj]);

    [_renderer draw];

	CGLFlushDrawable([[self openGLContext] CGLContextObj]);
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)dealloc
{
	CVDisplayLinkStop(displayLink);
	CVDisplayLinkRelease(displayLink);
}

@end
