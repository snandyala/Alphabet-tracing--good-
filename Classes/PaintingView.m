

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "PaintingView.h"

//CLASS IMPLEMENTATIONS:

// A class extension to declare private methods
@interface PaintingView (private)

- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;

@end

@implementation PaintingView

@synthesize  location;
@synthesize  previousLocation;
@synthesize newStrokes;
@synthesize referenceStrokes;
@synthesize currentPathData;
@synthesize verticesOfCurrentPath;
@synthesize fileNameToSaveDrawingTo;
@synthesize shape;
@synthesize characters;
@synthesize strokesMatched;
@synthesize strokesWithMismatchAreas;
@synthesize strokesMismatched;

int currentCharacterNumber = 0;
int lengthOfCurrentPath = 1;

// Implement this to override the default layer class (which is [CALayer class]).
// We do this so that our view will be backed by a layer that is capable of OpenGL ES rendering.
+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

-(void)createNextShape{
    [self erase];
    currentCharacterNumber = currentCharacterNumber + 1;
    if(currentCharacterNumber == [characters count]){
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"End" message:@"There are no more characters" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [av show];
    }else{
        [self.shape setText:[characters objectAtIndex:currentCharacterNumber]];
        [fileNameToSaveDrawingTo setText:[characters objectAtIndex:currentCharacterNumber]];
    }
}

-(void)setFileNameShape{
    [self.shape setText:[fileNameToSaveDrawingTo  text]];
}

-(void)addControls{
    UILabel *alphabet = [[UILabel alloc] initWithFrame:CGRectMake(50,100,400,400)];
    NSMutableArray *temp = [NSMutableArray arrayWithObjects:@"A",@"我",@"C",@"D",@"E",@"F",@"G",@"H",@"I", nil];
    self.characters  = temp;
    
    [alphabet setFont:[UIFont fontWithName:@"Verdana" size:300.0f]];
    [alphabet setText:@"A"];
    [alphabet setTextColor:[UIColor whiteColor]];
    [alphabet setBackgroundColor:[UIColor clearColor]];
    [alphabet setAlpha:0.3f];
    [self addSubview:alphabet];
    
    self.shape = alphabet;
    
    [alphabet release];
    
    
    //Save button
    UIButton *saveButon = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [saveButon setTitle:@"Save" forState:UIControlStateNormal];
    
    [saveButon setFrame:CGRectMake(0,0,70,70)];
    
    [self addSubview:saveButon];
    
    [saveButon addTarget:self action:@selector(saveData) forControlEvents:UIControlEventTouchUpInside];
    
    
    
    //Open button
    UIButton *openButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [openButton setTitle:@"Open" forState:UIControlStateNormal];
    
    [openButton setFrame:CGRectMake(80,0,70,70)];
    
    [self addSubview:openButton];
    
    [openButton addTarget:self action:@selector(openData) forControlEvents:UIControlEventTouchUpInside];
    
    
    //Compare button
    UIButton *compareButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [compareButton setTitle:@"Compare" forState:UIControlStateNormal];
    
    [compareButton setFrame:CGRectMake(160,0,70,70)];
    
    [self addSubview:compareButton];
    
    [compareButton addTarget:self action:@selector(compareStrokes) forControlEvents:UIControlEventTouchUpInside];
    
    //Start Creating Shapes button
    UIButton *createNextShapeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [createNextShapeButton setTitle:@"Next" forState:UIControlStateNormal];
    
    [createNextShapeButton setFrame:CGRectMake(240,0,70,70)];
    
    [self addSubview:createNextShapeButton];
    
    [createNextShapeButton addTarget:self action:@selector(createNextShape) forControlEvents:UIControlEventTouchUpInside];
    
    
    //Which pattern to load
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(20,80,70,30)];
    [tf setBackgroundColor:[UIColor grayColor]];
    self.fileNameToSaveDrawingTo = tf;
    [tf setText:@"A"];
    [self addSubview:tf];
    

}

// The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder {
	
	NSMutableArray*	recordedPaths;
	CGImageRef		brushImage;
	CGContextRef	brushContext;
	GLubyte			*brushData;
	size_t			width, height;
    
    if ((self = [super initWithCoder:coder])) {
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
		eaglLayer.opaque = YES;
		// In this application, we want to retain the EAGLDrawable contents after a call to presentRenderbuffer.
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		
		if (!context || ![EAGLContext setCurrentContext:context]) {
			[self release];
			return nil;
		}
		
		// Create a texture from an image
		// First create a UIImage object from the data in a image file, and then extract the Core Graphics image
		brushImage = [UIImage imageNamed:@"Particle.png"].CGImage;
		
		// Get the width and height of the image
		width = CGImageGetWidth(brushImage);
		height = CGImageGetHeight(brushImage);
		
		// Texture dimensions must be a power of 2. If you write an application that allows users to supply an image,
		// you'll want to add code that checks the dimensions and takes appropriate action if they are not a power of 2.
		
		// Make sure the image exists
		if(brushImage) {
			// Allocate  memory needed for the bitmap context
			brushData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
			// Use  the bitmatp creation function provided by the Core Graphics framework. 
			brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, CGImageGetColorSpace(brushImage), kCGImageAlphaPremultipliedLast);
			// After you create the context, you can draw the  image to the context.
			CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), brushImage);
			// You don't need the context at this point, so you need to release it to avoid memory leaks.
			CGContextRelease(brushContext);
			// Use OpenGL ES to generate a name for the texture.
			glGenTextures(1, &brushTexture);
			// Bind the texture name. 
			glBindTexture(GL_TEXTURE_2D, brushTexture);
			// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			// Specify a 2D texture image, providing the a pointer to the image data in memory
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
			// Release  the image data; it's no longer needed
            free(brushData);
		}
		
		// Set the view's scale factor
		self.contentScaleFactor = 1.0;
	
		// Setup OpenGL states
		glMatrixMode(GL_PROJECTION);
		CGRect frame = self.bounds;
		CGFloat scale = self.contentScaleFactor;
		// Setup the view port in Pixels
		glOrthof(0, frame.size.width * scale, 0, frame.size.height * scale, -1, 1);
		glViewport(0, 0, frame.size.width * scale, frame.size.height * scale);
		glMatrixMode(GL_MODELVIEW);
		
		glDisable(GL_DITHER);
		glEnable(GL_TEXTURE_2D);
		glEnableClientState(GL_VERTEX_ARRAY);
		
	    glEnable(GL_BLEND);
		// Set a blending function appropriate for premultiplied alpha pixel data
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
		
		glEnable(GL_POINT_SPRITE_OES);
		glTexEnvf(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE);
		glPointSize(width / kBrushScale);
		
		// Make sure to start with a cleared buffer
		needsErase = YES;
		
		// Playback recorded path, which is "Shake Me"
		recordedPaths = [NSMutableArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Recording" ofType:@"data"]];


        
        self.newStrokes = [NSMutableArray arrayWithCapacity:0];
        

        
		//if([recordedPaths count])
		//	[self performSelector:@selector(playback:) withObject:recordedPaths afterDelay:0.2];
	}
    
    [self addControls];
	
	return self;
}

// If our view is resized, we'll be asked to layout subviews.
// This is the perfect opportunity to also update the framebuffer so that it is
// the same size as our display area.
-(void)layoutSubviews
{
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	[self createFramebuffer];
	
	// Clear the framebuffer the first time it is allocated
	if (needsErase) {
		[self erase];
		needsErase = NO;
	}
}

- (BOOL)createFramebuffer
{
	// Generate IDs for a framebuffer object and a color renderbuffer
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	// This call associates the storage for the current render buffer with the EAGLDrawable (our CAEAGLLayer)
	// allowing us to draw into a buffer that will later be rendered to screen wherever the layer is (which corresponds with our view).
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	// For this sample, we also need a depth buffer, so we'll create and attach one via another renderbuffer.
	glGenRenderbuffersOES(1, &depthRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	
	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	return YES;
}

// Clean up any buffers we have allocated.
- (void)destroyFramebuffer
{
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer)
	{
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}

// Releases resources when they are not longer needed.
- (void) dealloc
{
	if (brushTexture)
	{
		glDeleteTextures(1, &brushTexture);
		brushTexture = 0;
	}
	
	if([EAGLContext currentContext] == context)
	{
		[EAGLContext setCurrentContext:nil];
	}
	
	[context release];
	[super dealloc];
}

// Erases the screen
- (void) erase
{
    
    [newStrokes removeAllObjects];
    
	[EAGLContext setCurrentContext:context];
	
	// Clear the buffer
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);
	
	// Display the buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

// Drawings a line onscreen based on where the user touches
- (void) renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
	static GLfloat*		vertexBuffer = NULL;
	static NSUInteger	vertexMax = 64;
	NSUInteger			vertexCount = 0,
						count,
						i;
	
	[EAGLContext setCurrentContext:context];
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	
	// Convert locations from Points to Pixels
	CGFloat scale = self.contentScaleFactor;
	start.x *= scale;
	start.y *= scale;
	end.x *= scale;
	end.y *= scale;
    
    
    // Put the lady bug here in an image view to start with
    UIImageView *imgView = [[[UIImageView alloc] initWithFrame:CGRectMake(start.x, 460-start.y, 16, 16)] autorelease];
    NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"Green" ofType:@"png"];
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
    [imgView setImage:img];
    [img release];
 //   [self addSubview:imgView];
    
   /* 
    UIView *tempView = [[UIView alloc] initWithFrame:CGRectMake(start.x,start.y,30,30)];
    [tempView setBackgroundColor:[UIColor whiteColor]];
    [self addSubview:tempView];
    [tempView release];
*/
    //    NSLog(@"X and Y : %f  %f",start.x,start.y);
	
	// Allocate vertex array buffer
	if(vertexBuffer == NULL)
		vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
	
	// Add points to the buffer so there are drawing points every X pixels
	count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / kBrushPixelStep), 1);
	for(i = 0; i < count; ++i) {
		if(vertexCount == vertexMax) {
			vertexMax = 2 * vertexMax;
			vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
		}
		
		vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
		vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
		vertexCount += 1;
	}
	
	// Render the vertex array
	glVertexPointer(2, GL_FLOAT, 0, vertexBuffer);
	glDrawArrays(GL_POINTS, 0, vertexCount);
	
	// Display the buffer
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

// Reads previously recorded points and draws them onscreen. This is the Shake Me message that appears when the application launches.
- (void) playback:(NSMutableArray*)recordedPaths
{
	NSData*				data = [recordedPaths objectAtIndex:0];
	CGPoint*			point = (CGPoint*)[data bytes];
	NSUInteger			count = [data length] / sizeof(CGPoint),
						i;
	
    // Show the starting point, for now we are showing an image of a bug as a starting and ending point for each path
    UIImageView *imgView1 = [[[UIImageView alloc] initWithFrame:CGRectMake(point->x, 460-point->y, 16, 16)] autorelease];
    NSString *imgFilepath1 = [[NSBundle mainBundle] pathForResource:@"Green" ofType:@"png"];
    UIImage *img1 = [[UIImage alloc] initWithContentsOfFile:imgFilepath1];
    [imgView1 setImage:img1];
    [img1 release];
    [self addSubview:imgView1];
    
	// Render the current path
	for(i = 0; i < count - 1; ++i, ++point){
		[self renderLineFromPoint:*point toPoint:*(point + 1)];
    }
    
    // Show the ending point
    UIImageView *imgView2 = [[[UIImageView alloc] initWithFrame:CGRectMake(point->x, 460-point->y, 16, 16)] autorelease];
    NSString *imgFilepath2 = [[NSBundle mainBundle] pathForResource:@"Green" ofType:@"png"];
    UIImage *img2 = [[UIImage alloc] initWithContentsOfFile:imgFilepath2];
    [imgView2 setImage:img2];
    [img2 release];
    [self addSubview:imgView2];
	
	// Render the next path after a short delay, recursive call to playback to play all the recorded paths
	[recordedPaths removeObjectAtIndex:0];
	if([recordedPaths count])
		[self performSelector:@selector(playback:) withObject:recordedPaths afterDelay:0.01];
}


// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setBrushColorWithRed:0.0 green:0.0 blue:1.0];
	CGRect				bounds = [self bounds];
    UITouch*	touch = [[event touchesForView:self] anyObject];
	firstTouch = YES;
	// Convert touch point from UIView referential to OpenGL one (upside-down flip)
	location = [touch locationInView:self];
	location.y = bounds.size.height - location.y;
    
    lengthOfCurrentPath = 1;
    self.currentPathData = [NSMutableData dataWithLength:0];
    self.verticesOfCurrentPath = (CGPoint *)malloc(sizeof(CGPoint)*lengthOfCurrentPath);
    
    verticesOfCurrentPath[lengthOfCurrentPath - 1] = location;

}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{  
   	  
	CGRect				bounds = [self bounds];
	UITouch*			touch = [[event touchesForView:self] anyObject];
		
	// Convert touch point from UIView referential to OpenGL one (upside-down flip)
	if (firstTouch) {
		firstTouch = NO;
		previousLocation = [touch previousLocationInView:self];
		previousLocation.y = bounds.size.height - previousLocation.y;
	} else {
		location = [touch locationInView:self];
	    location.y = bounds.size.height - location.y;
		previousLocation = [touch previousLocationInView:self];
		previousLocation.y = bounds.size.height - previousLocation.y;
	}
    
//    NSLog(@"P x and y are  %f %f",previousLocation.x,previousLocation.y);
//    NSLog(@"C x and y are  %f %f",location.x,location.y);
		
	// Render the st
	[self renderLineFromPoint:previousLocation toPoint:location];
    
        lengthOfCurrentPath = lengthOfCurrentPath + 1;
    verticesOfCurrentPath = (CGPoint *)realloc(verticesOfCurrentPath,sizeof(CGPoint)*lengthOfCurrentPath);
    

    verticesOfCurrentPath[lengthOfCurrentPath - 1] = previousLocation;

}


// See if the two paths are the same, if there is a difference in any points then it fails
-(BOOL)comparePathPath1:(NSData *)path1 withPath2:(NSData *)path2{
    
	CGPoint*			pointOnPath1 = (CGPoint*)[path1 bytes];
	NSUInteger			countOnPath1 = [path1 length] / sizeof(CGPoint),i1;    
    
	CGPoint*			pointOnPath2 = (CGPoint*)[path2 bytes];
	NSUInteger			countOnPath2 = [path2 length] / sizeof(CGPoint),i2;
    
    int distance;
    
    BOOL result1 = NO;
    BOOL result2 = NO;
    
    BOOL path1IsSubsetOfPath2 = NO;
    BOOL path2IsSubsetOfPath1 = NO;
	
	// See if Path1 is a subset of Path2
	for(i1 = 0; i1 < countOnPath1 - 1; ++i1, ++pointOnPath1){
        result1 = NO;
        path1IsSubsetOfPath2 = NO;
        pointOnPath2 = (CGPoint*)[path2 bytes];
        for(i2 = 0; i2 < countOnPath2 - 1; ++i2, ++pointOnPath2){
            
            distance = ceil(sqrtf((pointOnPath1->x - pointOnPath2->x) * (pointOnPath1->x - pointOnPath2->x) + (pointOnPath1->y - pointOnPath2->y) * (pointOnPath1->y - pointOnPath2->y)));
            
            if(distance < kAccuracyLevel){
                result1 = YES;
                path1IsSubsetOfPath2 = YES;
            }
        }
        
        if(result1==NO){
            /* This will show where the newStroke is different from referenceStroke.
               We are showing only one point now, but ideally it should highlight the whole path which is wrong
               But that will complicate the whole thing. For now let us just show it as one point where there is a discrepancy
             
               The way we have it here is wrong though, because even though this path matches some other path later, this error will
               still be shown. What we need to do is keep this data but show it later, if the newStroke does not match any other stroke
            */
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(pointOnPath1->x, 480-pointOnPath1->y, 20.0, 20.0)];
            [view setBackgroundColor:[UIColor whiteColor]];
            
            [strokesWithMismatchAreas setObject:view forKey:path1];
       //     [self addSubview:view];
            [view release];
            break;
        }
    }
    
    if(path1IsSubsetOfPath2){
        NSLog(@"Path 1 is subset of Path 2, You over drew it");
    }
    
    pointOnPath2 = (CGPoint*)[path2 bytes];
    
    // See if Path2 is a subset of Path1
	for(i2 = 0; i2 < countOnPath2 - 1; ++i2, ++pointOnPath2){
        result2 = NO;
        path2IsSubsetOfPath1 = NO;
        pointOnPath1 = (CGPoint*)[path1 bytes];
        for(i1 = 0; i1 < countOnPath1 - 1; ++i1, ++pointOnPath1){
            
            distance = ceil(sqrtf((pointOnPath1->x - pointOnPath2->x) * (pointOnPath1->x - pointOnPath2->x) + (pointOnPath1->y - pointOnPath2->y) * (pointOnPath1->y - pointOnPath2->y)));
            
            if(distance < kAccuracyLevel){
                result2 = YES;
                path2IsSubsetOfPath1 = YES;
            }
        }
  
    
        if(result2==NO){
            /* This will show where reference stroke is differing from the newStroke. This is not as important as 
               where newStroke is different from the reference stroke
             
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(pointOnPath2->x, 480-pointOnPath2->y, 20.0, 20.0)];
            [view setBackgroundColor:[UIColor whiteColor]];
            [self addSubview:view];
             
             */
            break;
        }
    }
    
    if(path2IsSubsetOfPath1){
        NSLog(@"Path 2 is subset of Path 1, You still need to complete it");
    }
    
 /*   
    if(path1IsSubsetOfPath2 && path2IsSubsetOfPath1){
        result = YES;
        NSLog(@"You drew exactly matching");
    }else{
        result = NO;
        NSLog(@"The shapes are not exactly matching");
    }
 */
    
    return (result1 && result2);
}


// Handles the end of a touch event when the touch is a tap.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGRect				bounds = [self bounds];
    UITouch*	touch = [[event touchesForView:self] anyObject];
	if (firstTouch) {
		firstTouch = NO;
		previousLocation = [touch previousLocationInView:self];
		previousLocation.y = bounds.size.height - previousLocation.y;
		[self renderLineFromPoint:previousLocation toPoint:location];
	}
    
    NSLog(@"One path is completed");
    
    currentPathData = [NSData dataWithBytes:verticesOfCurrentPath length:sizeof(CGPoint)*lengthOfCurrentPath];
    
    
    [newStrokes addObject:[currentPathData copy]];
  /*  
    if([newStrokes count]>1){
        if([self comparePathPath1:[newStrokes objectAtIndex:0] withPath2:[newStrokes objectAtIndex:1]]){
            NSLog(@"The paths are close enough");
            [self erase];
            [newStrokes removeAllObjects];
        }else{
            NSLog(@"The paths are not close enough");
            [self erase];
            [newStrokes removeAllObjects];
        }
    }
    */
}

-(void)colorStrokeGreen:(id)stroke{
    
    
    NSData*				data = stroke;
	CGPoint*			point = (CGPoint*)[data bytes];
	NSUInteger			count = [data length] / sizeof(CGPoint),
    i;
    
    [self setBrushColorWithRed:0.0 green:1.0 blue:0.0];
	
	// Render the current path
	for(i = 0; i < count - 1; ++i, ++point)
		[self renderLineFromPoint:*point toPoint:*(point + 1)];
    
}

-(void)colorStrokeWhite:(id)stroke{
    
    
    NSData*				data = stroke;
	CGPoint*			point = (CGPoint*)[data bytes];
	NSUInteger			count = [data length] / sizeof(CGPoint),
    i;
    
    [self setBrushColorWithRed:1.0 green:1.0 blue:1.0];
	
	// Render the current path
	for(i = 0; i < count - 1; ++i, ++point)
		[self renderLineFromPoint:*point toPoint:*(point + 1)];
    
}


-(void)colorStrokesMatchedGreen{
    for(int i=0;i<[strokesMatched count];i++){
        [self colorStrokeGreen:[strokesMatched objectAtIndex:i]];
    }
}

-(void)colorStrokesMismatchedWhite{
    
    for(int i=0;i<[strokesMismatched count];i++){
        [self colorStrokeWhite:[strokesMismatched objectAtIndex:i]];
    }
    


}
         
-(void)showMismatchedAreas{
    
    NSArray *keys = [strokesWithMismatchAreas allKeys];
    
    for(int i=0;i<[keys count];i++){
//        [self addSubview:[strokesWithMismatchAreas objectForKey:[keys objectAtIndex:i]]];
    }
             
}

-(IBAction)compareStrokes{
    int numberOfStrokesToCompare = MIN([newStrokes count],[referenceStrokes count]);
    
    self.strokesMatched = [NSMutableArray arrayWithCapacity:0];
    
    self.strokesMismatched = [NSMutableArray arrayWithCapacity:0];
    
    self.strokesWithMismatchAreas = [NSMutableDictionary dictionaryWithCapacity:0];
    
    BOOL matched=NO;
    
    
    for(int i=0;i<[newStrokes count];i++){
        [strokesMismatched addObject:[newStrokes objectAtIndex:i]];
    }
    
    int numberOfStrokesMatched = 0;
    
    for(int i=0;i<[newStrokes count];i++){
        matched=NO;
        for(int j=0;j<[referenceStrokes count];j++){
            if([self comparePathPath1:[newStrokes objectAtIndex:i] withPath2:[referenceStrokes objectAtIndex:j]]){
                NSLog(@"Shape %d matches with %d",i,j);
                numberOfStrokesMatched = numberOfStrokesMatched + 1;
                [strokesMatched addObject:[newStrokes objectAtIndex:i]];
                break;
            }
        }

    }
    
    if(numberOfStrokesMatched == [referenceStrokes count]){
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Good Job" message:@"Excellent job" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [av show];
        [av release];
    }else{
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Try Again" message:@"Try Again" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [av show];
        [av release];
    }
    
    [strokesMismatched removeObjectsInArray:strokesMatched];
    [strokesWithMismatchAreas removeObjectsForKeys:strokesMatched];
    
    [self colorStrokesMatchedGreen];
    

    [self colorStrokesMismatchedWhite];
    
    [self showMismatchedAreas];
}


-(IBAction)saveData{
    
    [fileNameToSaveDrawingTo resignFirstResponder];
    
    NSArray* documentPaths =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                        NSUserDomainMask,
                                        NO);
    NSString* documentPath = [documentPaths objectAtIndex:0];
    
    NSLog(@"The file path where it is written is %@",[documentPath stringByExpandingTildeInPath]);
    
    NSError *err;
    BOOL success = [newStrokes writeToFile:[[documentPath stringByExpandingTildeInPath] stringByAppendingFormat:@"/%@",[fileNameToSaveDrawingTo text]] atomically:YES];
    
    if(!success){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"File writing error" message:@"File error" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
    }
}

-(IBAction)openData{
    [self setBrushColorWithRed:1.0 green:0.0 blue:0.0];
    [fileNameToSaveDrawingTo resignFirstResponder];
    [self erase];
    [self setFileNameShape];
    [newStrokes removeAllObjects];
    
    NSMutableArray *recordedPaths;
    [self erase];
    NSArray* documentPaths =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                        NSUserDomainMask,
                                        NO);
    NSString* documentPath = [documentPaths objectAtIndex:0];
    
    
    
    NSLog(@"The file path where it is going to be read from is %@",[documentPath stringByExpandingTildeInPath]);
    
   recordedPaths = [NSMutableArray arrayWithContentsOfFile:[[documentPath stringByExpandingTildeInPath] stringByAppendingFormat:@"/%@",[fileNameToSaveDrawingTo text]]];
    
    self.referenceStrokes = [recordedPaths copy];
   
   NSLog(@"The number of paths stored is %d",[recordedPaths count]);
    
   if([recordedPaths count])
    	[self performSelector:@selector(playback:) withObject:recordedPaths afterDelay:0.2];

}

// Handles the end of a touch event.
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	// If appropriate, add code necessary to save the state of the application.
	// This application is not saving state.
}

- (void)setBrushColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue
{
	// Set the brush color using premultiplied alpha values
	glColor4f(red	* kBrushOpacity,
			  green * kBrushOpacity,
			  blue	* kBrushOpacity,
			  kBrushOpacity);
}

@end
