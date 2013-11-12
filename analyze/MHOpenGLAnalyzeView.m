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

#define FFT_SIZE 4096

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@implementation MHOpenGLAnalyzeView {
    MHCoreAudioShovel *_shovel;
    GLuint _vao;
    GLuint _vbo;
    GLuint _program;
    GLenum _err;

    Float32 *magnitude;
    int offset;
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



    glPointSize(2.0);



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


    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);


    Float32 *in_real = (Float32 *) malloc(FFT_SIZE * sizeof(float));
//    Float32 *out_real = (Float32 *) malloc(FFT_SIZE * sizeof(float));
    __block DSPSplitComplex split_data;
    split_data.realp = (Float32 *) malloc(FFT_SIZE / 2 * sizeof(float));
    split_data.imagp = (Float32 *) malloc(FFT_SIZE / 2 * sizeof(float));

    Float32 *window = (Float32 *) malloc(sizeof(float) * FFT_SIZE);
    memset(window, 0, sizeof(float) * FFT_SIZE);
    vDSP_hann_window(window, FFT_SIZE, vDSP_HANN_DENORM);

//    Float32 scale = 1.0f / (float)(4.0f * FFT_SIZE);

    // allocate the fft object once
    vDSP_Length LOG2N = log2f(FFT_SIZE);
    FFTSetup fftSetup = vDSP_create_fftsetup(LOG2N, FFT_RADIX2);

    magnitude = malloc(FFT_SIZE / 2 * sizeof(Float32));

    Float32 *leftChannelData = malloc(FFT_SIZE * sizeof(Float32));
    Float32 *rightChannelData = malloc(FFT_SIZE * sizeof(Float32));
    __block DSPSplitComplex deinterleavedSamples;
//    deinterleavedSamples.realp = leftChannelData;
//    deinterleavedSamples.imagp = rightChannelData;

    _shovel = [[MHCoreAudioShovel alloc] initWithIOBlock:^(const AudioTimeStamp *inNow, const AudioBufferList *inInputData, const AudioTimeStamp *inInputTime, AudioBufferList *outOutputData, const AudioTimeStamp *inOutputTime) {
        for (int bufferIndex = 0; bufferIndex < inInputData->mNumberBuffers; bufferIndex++) {
            AudioBuffer buffer = inInputData->mBuffers[bufferIndex];
//            memcpy(data + offset * 512, buffer.mData, buffer.mDataByteSize);
            int memOffset = offset * 512 * sizeof(Float32);
            deinterleavedSamples.realp = leftChannelData + memOffset;
            deinterleavedSamples.imagp = rightChannelData + memOffset;
            vDSP_ctoz((const DSPComplex *)buffer.mData, buffer.mNumberChannels, &deinterleavedSamples, 1, 512);
        }
        offset++;
        if (offset == 8) {
            vDSP_vmul(leftChannelData, 1, window, 1, in_real, 1, FFT_SIZE);
            vDSP_ctoz((DSPComplex *) in_real, 2, &split_data, 1, FFT_SIZE / 2);

            //convert to split complex format with evens in real and odds in imag
//            vDSP_ctoz((DSPComplex *) leftChannelData, 2, &split_data, 1, FFT_SIZE / 2);

            //calc fft
            vDSP_fft_zrip(fftSetup, &split_data, 1, LOG2N, FFT_FORWARD);

            split_data.imagp[0] = 0.0;

            for (int i = 0; i < FFT_SIZE / 2; i++) {
                //compute power
                float power = split_data.realp[i]*split_data.realp[i] + split_data.imagp[i]*split_data.imagp[i];

                //compute magnitude and phase
                magnitude[i] = sqrtf(power);
                //                phase[i] = atan2f(split_data.imagp[i], split_data.realp[i]);
            }

            dispatch_async(dispatch_get_main_queue(), ^{
//                NSLog(@"gogogogog!");
                [self setNeedsDisplay:YES];
            });
        }
        offset %= 8;
    }];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

    static int i = 0;
    GLfloat whiteness = (float)i / 1024.0;
    glClearColor(whiteness, whiteness, whiteness, 0.0);

    _err = glGetError();
    glClear(GL_COLOR_BUFFER_BIT);
    glBindVertexArray(_vao);
    glBufferData(GL_ARRAY_BUFFER, FFT_SIZE / 2 * sizeof(Float32), magnitude, GL_STATIC_DRAW);


    glDrawArrays(GL_LINE_STRIP, 0, FFT_SIZE / 2);
    glSwapAPPLE();


    if (!i) {
        static uint64_t t = 0;
        double dt = (double) (mach_absolute_time() - t) / (double) 1000000000;
        if (t > 0) {
            NSLog(@"rendered 1024 times in %lf seconds, %f fps", dt, 1024.0 / (float)dt);
        }
        t = mach_absolute_time();
    }
    i++;
    i = i % 1024;

//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self setNeedsDisplay:YES];
//    });
}

- (const GLchar *)loadShaderFromFile:(NSString *)fileName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    NSStringEncoding encoding;
    NSString *code = [[NSString alloc] initWithContentsOfFile:path usedEncoding:&encoding error:nil];
    return [code cStringUsingEncoding:encoding];
}

@end
