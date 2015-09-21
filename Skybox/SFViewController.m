//
//  SFViewController.m
//  Skybox
//
//  Created by M Ilich on 11-11-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SFViewController.h"

@implementation SFViewController

@synthesize context = _context;
@synthesize cubemap = _cubemap;
@synthesize skyboxEffect = _skyboxEffect;

static float const zoomInMax = 20.0; // was 350.0
static float const zoomOutMin = 85.0; // was 50.0
static float const touchScale = 5.0; // was 5.0

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    viewZoom = zoomOutMin;
    
    self.view.multipleTouchEnabled = YES;
    
    // Set up the Accelerometer tracking
    if (motionManager == nil) {
        motionManager = [[CMMotionManager alloc] init];
    }
    motionManager.accelerometerUpdateInterval = 0.01;
    motionManager.deviceMotionUpdateInterval = 0.01;
    [motionManager startDeviceMotionUpdates];
    
    [self setupGL];
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (void)setupGL
{    
    [EAGLContext setCurrentContext:self.context];
    
    self.skyboxEffect = [[GLKSkyboxEffect alloc] init];
    
    glEnable(GL_DEPTH_TEST);
    
//    NSArray *cubeMapFileNames = [NSArray arrayWithObjects:
//                                 [NSString stringWithFormat:@"%@/back.png",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]], // back
//                                 [NSString stringWithFormat:@"%@/front.png",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]], // front
//                                 [NSString stringWithFormat:@"%@/bottom.png",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]], // bottom
//                                 [NSString stringWithFormat:@"%@/top.png",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]], // top
//                                 [NSString stringWithFormat:@"%@/right.png",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]], // right
//                                 [NSString stringWithFormat:@"%@/left.png",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]], // left
//                                 nil];

//    NSArray *cubeMapFileNames = [NSArray arrayWithObjects:
//                                 [[NSBundle mainBundle] pathForResource:@"cubemap1" ofType:@"png"], // back
//                                 [[NSBundle mainBundle] pathForResource:@"cubemap2" ofType:@"png"], // front
//                                 [[NSBundle mainBundle] pathForResource:@"cubemap3" ofType:@"png"], // bottom
//                                 [[NSBundle mainBundle] pathForResource:@"cubemap4" ofType:@"png"], // top
//                                 [[NSBundle mainBundle] pathForResource:@"cubemap5" ofType:@"png"], // right
//                                 [[NSBundle mainBundle] pathForResource:@"cubemap6" ofType:@"png"], // left
//                                 nil];

    NSArray *cubeMapFileNames = [NSArray arrayWithObjects:
                                 [[NSBundle mainBundle] pathForResource:@"Back" ofType:@"png"], // back
                                 [[NSBundle mainBundle] pathForResource:@"Front" ofType:@"png"], // front
                                 [[NSBundle mainBundle] pathForResource:@"Bottom" ofType:@"png"], // bottom
                                 [[NSBundle mainBundle] pathForResource:@"Top" ofType:@"png"], // top
                                 [[NSBundle mainBundle] pathForResource:@"Right" ofType:@"png"], // right
                                 [[NSBundle mainBundle] pathForResource:@"Left" ofType:@"png"], // left
                                 nil];

    NSError *error;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] 
                                                        forKey:GLKTextureLoaderOriginBottomLeft];
    self.cubemap = [GLKTextureLoader cubeMapWithContentsOfFiles:cubeMapFileNames
                                                        options:options
                                                          error:&error];
    
    self.skyboxEffect.textureCubeMap.name = self.cubemap.name;
    
    glBindVertexArrayOES(0);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteBuffers(1, &vertexBuffer);
    glDeleteVertexArraysOES(1, &vertexArray);    
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    // Set up rotation matrix and capture real orientation values from device motion manager
    CMRotationMatrix rotation;
    CMDeviceMotion *deviceMotion = motionManager.deviceMotion;		
    CMAttitude *attitude = deviceMotion.attitude;
    rotation = attitude.rotationMatrix;    
    
    GLKMatrix4 rotationMatrix = GLKMatrix4Make(rotation.m11, rotation.m21, rotation.m31, 0, rotation.m12, rotation.m22, rotation.m32, 0, rotation.m13, rotation.m23, rotation.m33, 0, 0, 0, 0, 1);
    
    GLKMatrix4 gravityFix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(-90), 1, 0, 0);
    
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(viewZoom), aspect, 0.1f, 100.0f);
   
    self.skyboxEffect.transform.projectionMatrix = projectionMatrix;    
                                                    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -3.5f);   // originally -3.5f
    
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotationMatrix);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, gravityFix);
    
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 50, 50, 50);
    self.skyboxEffect.transform.modelviewMatrix = modelViewMatrix;
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.skyboxEffect prepareToDraw];
    [self.skyboxEffect draw];
    
}

#pragma mark -
#pragma mark Touch methods

- (CGFloat)distanceBetweenTwoPoints:(CGPoint)fromPoint toPoint:(CGPoint)toPoint
{
    float xDist = fromPoint.x - toPoint.x;
    float yDist = fromPoint.y - toPoint.y;
    
    float result = sqrt( pow(xDist,2) + pow(yDist,2) );
    return result;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    NSSet *allTouches = [event allTouches];
    
    if ([allTouches count] == 2) {
        
        //Track the initial distance between two fingers.
        UITouch *touch1 = [[allTouches allObjects] objectAtIndex:0];
        UITouch *touch2 = [[allTouches allObjects] objectAtIndex:1];
        
        prevDistance = [self distanceBetweenTwoPoints:[touch1 locationInView:[self view]]
                                              toPoint:[touch2 locationInView:[self view]]];        
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    NSSet *allTouches = [event allTouches];
    
    if ([allTouches count] == 2) {
        UITouch *touch1 = [[allTouches allObjects] objectAtIndex:0];
        UITouch *touch2 = [[allTouches allObjects] objectAtIndex:1];
        
        CGFloat nextDistance = [self distanceBetweenTwoPoints:[touch1 locationInView:self.view]
                                                      toPoint:[touch2 locationInView:self.view]];
        
        if (prevDistance < nextDistance) {
            // ZOOM in
            viewZoom -= (nextDistance - prevDistance)/touchScale;
            if (viewZoom < zoomInMax) {
                viewZoom = zoomInMax;
            }
            prevDistance = nextDistance;
        } else if (prevDistance > nextDistance) {             
            // ZOOM out
            viewZoom += (prevDistance - nextDistance)/touchScale;
            if (viewZoom > zoomOutMin) {
                viewZoom = zoomOutMin;
            }
            prevDistance = nextDistance;
        }

    }
}

@end
