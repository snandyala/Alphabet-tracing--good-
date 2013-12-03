
#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

//CONSTANTS:

//#define kBrushOpacity		(1.0 / 3.0)
#define kBrushOpacity		1.0
#define kBrushPixelStep		1
#define kBrushScale			10
#define kLuminosity			0.75
#define kSaturation			1.0
#define kAccuracyLevel      25

//CLASS INTERFACES:

@interface PaintingView : UIView
{
@private
	// The pixel dimensions of the backbuffer
	GLint backingWidth;
	GLint backingHeight;
	
	EAGLContext *context;
	
	// OpenGL names for the renderbuffer and framebuffers used to render to this view
	GLuint viewRenderbuffer, viewFramebuffer;
	
	// OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist)
	GLuint depthRenderbuffer;
	
	GLuint	brushTexture;
	CGPoint	location;
	CGPoint	previousLocation;
	Boolean	firstTouch;
	Boolean needsErase;	
    NSMutableArray *newStrokes;
    NSMutableArray *referenceStrokes;
    NSMutableData *currentPathData;
    CGPoint *verticesOfCurrentPath;
    NSMutableArray *characters;
    
    UITextField *fileNameToSaveDrawingTo;
    NSMutableArray  *strokesMatched;
    NSMutableArray *strokesMismatched;
    NSMutableDictionary *strokesWithMismatchAreas;
    UILabel *shape;
}

@property(nonatomic, readwrite) CGPoint location;
@property(nonatomic, readwrite) CGPoint previousLocation;
@property(nonatomic, retain)NSMutableArray *newStrokes;
@property(nonatomic, retain)NSMutableArray *referenceStrokes;
@property(nonatomic, retain)NSMutableData *currentPathData;
@property CGPoint *verticesOfCurrentPath;
@property(nonatomic, retain)UITextField *fileNameToSaveDrawingTo;
@property(retain,nonatomic)UILabel *shape;
@property(retain,nonatomic)NSMutableArray *characters;
@property(retain,nonatomic)NSMutableArray  *strokesMatched;
@property(retain,nonatomic)NSMutableDictionary *strokesWithMismatchAreas;
@property(retain,nonatomic)NSMutableArray *strokesMismatched;


- (void)erase;
- (void)setBrushColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;
-(IBAction)saveData;
-(IBAction)openData;
-(IBAction)compareStrokes;

@end
