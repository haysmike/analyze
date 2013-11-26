//
//  MHAnalyzeRenderer.h
//  analyze
//
//  Created by Mike Hays on 11/15/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MHAnalyzeRenderer : NSObject

- (void)draw;
- (void)reshapeWithWidth:(GLuint)width AndHeight:(GLuint)height;

@end
