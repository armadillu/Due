/* Controller */

#import <Cocoa/Cocoa.h>

#import "constants.h"


@interface Controller : NSObject
{
    IBOutlet NSMenu* menu;
	IBOutlet NSWindow * prefsWin;
	IBOutlet NSDatePicker* calendarDate;
	IBOutlet NSTextField* projectName;
	
	NSStatusItem*	_statusItem;
	NSTimer *		timer;
	NSDictionary *	textAttributes;
	NSDictionary *	textAttributesAlt;
}


- (IBAction)do:(id)sender;
- (NSImage*) createImage:(BOOL)alternate;
- (IBAction) refresh:(id)whatever;
- (IBAction)setSettings:(id)sender;

@end
