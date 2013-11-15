//
//  MHOpenGLAnalyzeView.m
//  analyze
//
//  Created by Mike Hays on 11/8/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>
#import <Accelerate/Accelerate.h>
#import <mach/mach_time.h>

#import "MHOpenGLAnalyzeView.h"

#import "MHCoreAudioShovel.h"
#import "MHFFT.h"

#define FFT_SIZE 4096
#define NUM_CHANNELS 2

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@implementation MHOpenGLAnalyzeView {
    MHCoreAudioShovel *_shovel;
    GLuint _vao;
    GLuint _vbo;
    GLuint _program;
    GLenum _err;

    Float32 *magnitude;
    int offset;

    FFTSetup fftSetup;
    Float32 *window;
    Float32 *in_real;
    Float32 *leftChannelData;
    DSPSplitComplex split_data;
    vDSP_Length LOG2N;

    MHFFT *_fft;

    CVDisplayLinkRef displayLink;
}


- (CVReturn)getFrameForTime:(const CVTimeStamp*)outputTime
{
    @autoreleasepool {
        [self drawView];
    }
	return kCVReturnSuccess;
}

// This is the renderer output callback function
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

	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void *)(self));

	// Set the display link for the current renderer
	CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);

	// Activate the display link
	CVDisplayLinkStart(displayLink);

	// Register to be notified when the window closes so we can stop the displaylink
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowWillClose:)
												 name:NSWindowWillCloseNotification
											   object:[self window]];
}

- (void)windowWillClose:(NSNotification*)notification
{
	// Stop the display link when the window is closing because default
	// OpenGL render buffers will be destroyed.  If display link continues to
	// fire without renderbuffers, OpenGL draw calls will set errors.

	CVDisplayLinkStop(displayLink);
}

- (void)initGL
{
	[[self openGLContext] makeCurrentContext];

	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];

	{
        glEnable(GL_LINE_SMOOTH);

        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

        const GLchar *vertex_code = [self loadShaderFromFile:@"analyze.vert"];
        const GLchar *fragment_code = [self loadShaderFromFile:@"analyze.frag"];

        GLint status;
        char infoLog[4096];
        GLsizei length;

        glGenVertexArrays(1, &_vao);
        glBindVertexArray(_vao);

        glGenBuffers(1, &_vbo);
        glBindBuffer(GL_ARRAY_BUFFER, _vbo);

        glVertexAttribPointer(0, 1, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));
        glEnableVertexAttribArray(0);




        GLuint vertex_shader = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vertex_shader, 1, (const GLchar **) &vertex_code, NULL);
        glCompileShader(vertex_shader);
        glGetShaderiv(vertex_shader, GL_COMPILE_STATUS, &status);
        if (status == GL_FALSE) {
            glGetShaderInfoLog(vertex_shader, 4096, &length, infoLog);
            printf("%s", infoLog);
        }

        GLuint fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fragment_shader, 1, (const GLchar **) &fragment_code, NULL);
        glCompileShader(fragment_shader);

        glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, &status);
        _program = glCreateProgram();

        glAttachShader(_program, vertex_shader);
        glAttachShader(_program, fragment_shader);
        glLinkProgram(_program);
        glGetProgramiv(_program, GL_LINK_STATUS, &status);
        if (status == GL_FALSE) {
            glGetProgramInfoLog(_program, 4096, &length, infoLog);
            printf("%s", infoLog);
        }

        glUseProgram(_program);
        
        
        //    magnitude = malloc(NUM_CHANNELS * FFT_SIZE * sizeof(Float32));
        
        _fft = [[MHFFT alloc] initWithLength:FFT_SIZE];
        _shovel = [[MHCoreAudioShovel alloc] initWithBufferSize:NUM_CHANNELS * FFT_SIZE * sizeof(Float32)];
    }
}

- (void) reshape
{
	[super reshape];

	CGLLockContext([[self openGLContext] CGLContextObj]);

    NSRect viewRectPixels = [self bounds];
	glViewport(0, 0, viewRectPixels.size.width, viewRectPixels.size.height);

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

	{
        magnitude = [_fft forward:[_shovel getBuffer]];
        glClear(GL_COLOR_BUFFER_BIT);
        glBindVertexArray(_vao);
        glBufferData(GL_ARRAY_BUFFER, FFT_SIZE / 2 * sizeof(Float32), magnitude, GL_STATIC_DRAW);
        glDrawArrays(GL_LINE_STRIP, 0, FFT_SIZE / 2);
    }

	CGLFlushDrawable([[self openGLContext] CGLContextObj]);
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)dealloc
{
	CVDisplayLinkStop(displayLink);
	CVDisplayLinkRelease(displayLink);
}

- (const GLchar *)loadShaderFromFile:(NSString *)fileName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    NSStringEncoding encoding;
    NSString *code = [[NSString alloc] initWithContentsOfFile:path usedEncoding:&encoding error:nil];
    return [code cStringUsingEncoding:encoding];
}

@end
