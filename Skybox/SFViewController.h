//
//  SFViewController.h
//  Skybox
//
//  Created by M Ilich on 11-11-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <CoreMotion/CoreMotion.h>

@interface SFViewController : GLKViewController {
    
@private    
    CMMotionManager *motionManager;
    CGFloat prevDistance;
    double viewZoom;    
}

@end

@interface SFViewController () 
{    
    GLKMatrix4 modelViewProjectionMatrix;
    GLKMatrix3 normalMatrix;
    GLuint vertexArray;
    GLuint vertexBuffer;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKTextureInfo *cubemap;
@property (strong, nonatomic) GLKSkyboxEffect *skyboxEffect;

- (void)setupGL;
- (void)tearDownGL;

@end