

//CLASS INTERFACES:

@class PaintingWindow;
@class PaintingView;
@class SoundEffect;

@interface AppController : NSObject <UIApplicationDelegate>
{
	PaintingWindow		*window;
	PaintingView		*drawingView;

	SoundEffect			*erasingSound;
	SoundEffect			*selectSound;
	CFTimeInterval		lastTime;
}

@property (nonatomic, retain) IBOutlet PaintingWindow *window;
@property (nonatomic, retain) IBOutlet PaintingView *drawingView;

@end
