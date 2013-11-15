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
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSOpenGLPixelFormatAttribute attr[] = {
//            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core, // Needed if using opengl 3.2 you can comment this line out to use the old version.
//            NSOpenGLPFAColorSize,     24,
//            NSOpenGLPFAAlphaSize,     8,
            NSOpenGLPFAAccelerated,
//            NSOpenGLPFADoubleBuffer,
//            0
            NSOpenGLPFADoubleBuffer,
//            NSOpenGLPFADepthSize,       24,
            NSOpenGLPFAOpenGLProfile,   NSOpenGLProfileVersion3_2Core,
            0
        };
        [self setPixelFormat:[[NSOpenGLPixelFormat alloc] initWithAttributes:attr]];
    }
    return self;
}

- (void)prepareOpenGL
{
	CGLEnable([[self openGLContext] CGLContextObj], kCGLCECrashOnRemovedFunctions);


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

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

    magnitude = [_fft forward:[_shovel getBuffer]];
    glClear(GL_COLOR_BUFFER_BIT);
    glBindVertexArray(_vao);
    glBufferData(GL_ARRAY_BUFFER, FFT_SIZE / 2 * sizeof(Float32), magnitude, GL_STATIC_DRAW);
    glDrawArrays(GL_LINE_STRIP, 0, FFT_SIZE / 2);
    glSwapAPPLE();

    // TODO: performance analysis

    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay:YES];
    });
}

- (const GLchar *)loadShaderFromFile:(NSString *)fileName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    NSStringEncoding encoding;
    NSString *code = [[NSString alloc] initWithContentsOfFile:path usedEncoding:&encoding error:nil];
    return [code cStringUsingEncoding:encoding];
}

@end
