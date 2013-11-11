//
//  MHOpenGLAnalyzeView.m
//  analyze
//
//  Created by Mike Hays on 11/8/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

//#import <OpenGL/gl3.h>
#import "MHOpenGLAnalyzeView.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@implementation MHOpenGLAnalyzeView {
    GLuint _buffer;
    GLuint _program;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
//        NSOpenGLPixelFormatAttribute attr[] = {
//            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core, // Needed if using opengl 3.2 you can comment this line out to use the old version.
//            NSOpenGLPFAColorSize,     24,
//            NSOpenGLPFAAlphaSize,     8,
//            NSOpenGLPFAAccelerated,
//            NSOpenGLPFADoubleBuffer,
//            0
//        };
//        [self setPixelFormat:[[NSOpenGLPixelFormat alloc] initWithAttributes:attr]];
    }
    return self;
}

- (void)prepareOpenGL
{
//    const GLchar *vertex_code = [self loadShaderFromFile:@"analyze.vert"];
    const GLchar *fragment_code = [self loadShaderFromFile:@"analyze.frag"];

    GLint status;
    char infoLog[4096];
    GLsizei length;

    glGenBuffers(1, &_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, _buffer);
    glBufferData(GL_ARRAY_BUFFER, 4 * 2 * sizeof(GLfloat), NULL, GL_STATIC_DRAW);

    GLfloat *data = (GLfloat *) glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
    data[0] = -0.75f; data[1] = -0.5f;
    data[2] = -0.75f; data[3] =  0.75f;
    data[4] =  0.75f; data[5] = -0.75f;
    data[6] =  0.75f; data[7] =  0.5f;
    glUnmapBuffer(GL_ARRAY_BUFFER);

//    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
//    glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
    glPointSize(10.0);

    // TODO: learn more about VBOs
    // do i need to disable this when done?
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));


//    GLuint vertex_shader = glCreateShader(GL_VERTEX_SHADER);
//    glShaderSource(vertex_shader, 1, (const GLchar **) &vertex_code, NULL);
//    glCompileShader(vertex_shader);
//    glGetShaderiv(vertex_shader, GL_COMPILE_STATUS, &status);
//    if (status == GL_FALSE) {
//        glGetShaderInfoLog(vertex_shader, 4096, &length, infoLog);
//        printf("%s", infoLog);
//    }

    GLuint fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragment_shader, 1, (const GLchar **) &fragment_code, NULL);
    glCompileShader(fragment_shader);
    glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        glGetShaderInfoLog(fragment_shader, 4096, &length, infoLog);
        printf("%s", infoLog);
    }

    _program = glCreateProgram();
//    glAttachShader(_program, vertex_shader);
    glAttachShader(_program, fragment_shader);
//    glBindFragDataLocation(_program, 0, "bull_shit");
    glLinkProgram(_program);
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        glGetProgramInfoLog(_program, 4096, &length, infoLog);
        printf("%s", infoLog);
    }

    glUseProgram(_program);
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

    static int i = 0;
    GLfloat whiteness = (float)i / 1024.0;
    glClearColor(whiteness, whiteness, whiteness, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
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

//    GLint size;
//    glGetIntegerv(GL_ACTIVE_UNIFORM_MAX_LENGTH, &size);
//    NSLog(@"GL_ACTIVE_UNIFORM_MAX_LENGTH: %i", size);

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
