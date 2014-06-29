#import "Controller.h"


BOOL isWeekday(NSDate * date){
	int day = [[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:date] weekday];
	const int kSunday = 1;
	const int kSaturday = 7;
	BOOL isWeekdayResult = day != kSunday && day != kSaturday;
	return isWeekdayResult;
}


@implementation Controller

-(void)awakeFromNib{
	
	[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
	NSShadow * sha=[ [NSShadow alloc] init];
	NSSize shOffset = { .width = 0.0f, .height = 0.0f};
	[sha setShadowOffset: shOffset];
	[sha setShadowColor:[NSColor grayColor]];
	[sha setShadowBlurRadius: 1];

	NSArray * objs = [NSArray  arrayWithObjects: 
						[[NSFontManager sharedFontManager] fontWithFamily:@"Lucida Grande" traits:nil	weight:3 size:9.1],
						sha,
						[NSColor colorWithDeviceWhite:0.0 alpha:1.0],
						nil
						];

	NSArray * objsAlt = [NSArray  arrayWithObjects:
					  [[NSFontManager sharedFontManager] fontWithFamily:@"Lucida Grande" traits:nil	weight:3 size:9.1],
					  sha,
					  [NSColor colorWithDeviceWhite:1.0 alpha:1.0],
					  nil
					  ];


	NSArray * keys = [NSArray  arrayWithObjects: (id)NSFontAttributeName, (id)NSShadowAttributeName, (id)NSForegroundColorAttributeName, nil ];

	if ([keys count] != [objs count] ){
		NSLog(@"Exit! Missing Lucida Grande typeface!?");
		exit(0);
	}

	textAttributes = [[NSDictionary dictionaryWithObjects:objs forKeys: keys ] retain];
	textAttributesAlt = [[NSDictionary dictionaryWithObjects:objsAlt forKeys: keys ] retain];

	[calendarDate setDateValue:[NSDate dateWithTimeIntervalSinceNow: 60 * 60 * 24 * 3]];
	[calendarDate setMinDate:[NSDate date]]; //timer cant go backwards!
	[[calendarDate cell] setDelegate:self];
	[calendarDate setAction:@selector(datePickerAction:)];

	NSUserDefaults * def = [NSUserDefaults standardUserDefaults];
	if([def stringForKey:@"projectName"]){
		[projectName setStringValue:[def stringForKey:@"projectName"]];
	}
	if([def objectForKey:@"dueDate"]){
		NSDate * restoredDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:@"dueDate"];
		[calendarDate setDateValue:restoredDate];
	}

	if([def objectForKey:@"includeWeekends"]){
		int state = [[NSUserDefaults standardUserDefaults] integerForKey:@"includeWeekends"];
		[includeWeekends setState:state];
	}

	_statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[_statusItem setHighlightMode:YES];
	[_statusItem setEnabled:YES];
	[_statusItem setMenu:menu];
	[_statusItem setTarget:self];

	[self refresh:nil];

	//every 5 min
	timer = [NSTimer scheduledTimerWithTimeInterval: 60.0 * 5.0 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer: timer forMode:NSEventTrackingRunLoopMode];
}


- (IBAction)setSettings:(id)sender;{
	[[NSUserDefaults standardUserDefaults] setObject:[calendarDate dateValue] forKey:@"dueDate"];
	[[NSUserDefaults standardUserDefaults] setObject:[projectName stringValue] forKey:@"projectName"];
	[[NSUserDefaults standardUserDefaults] setInteger: [includeWeekends state] forKey:@"includeWeekends"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self refresh:nil];
}


- (void)controlTextDidChange:(NSNotification *)notification {
	[self setSettings:nil];
	[self refresh:nil];
}


- (IBAction)datePickerAction:(id)sender{
	[self setSettings:nil];
	[self refresh:nil];
}


- (NSImage*) createImage:(BOOL)alternate{

	NSDateComponents *  dateComp = [self daysBetweenDate:[NSDate date] andDate:[calendarDate dateValue]];
	NSInteger days = [dateComp day];
	int businessDays = days; //if we count weekends, then days behave same as businessdays
	BOOL b_includeWeekends = [includeWeekends state];
	if (!b_includeWeekends){
		//calc how many "week days" we have from now to target date
		NSDate * indexDate = [NSDate date];
		businessDays = isWeekday(indexDate) ? 0 : 1; //count target date regardless
		for(int i = 0; i< days; i++){
			BOOL isWorkDay = isWeekday(indexDate);
			if(isWorkDay) businessDays++;
			indexDate = [indexDate dateByAddingTimeInterval: 60 * 60 * 24];
		}

	}

	//NSLog(@"days: %d  workDays: %d", days, businessDays);
	NSString * projectString = [NSString stringWithFormat:@"%@", [projectName stringValue]];
	NSString * timeString;

	if (days == 0){
		timeString = [NSString stringWithFormat:@"due today!"];
	}else{
		if (days==1){
			if (b_includeWeekends){
				timeString = [NSString stringWithFormat:@"due tomorrow!"];
			}else{
				int todayday = [[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:[NSDate date]] weekday];
				const int kSunday = 1;
				const int kSaturday = 7;
				bool isWeekend = (todayday == kSaturday || todayday == kSunday);
				if ( isWeekend){
					timeString = [NSString stringWithFormat:@"due next workday!"];
				}else{
					timeString = [NSString stringWithFormat:@"due tomorrow!"];
				}
			}
		}else{
			if (businessDays == 1){
				timeString = [NSString stringWithFormat:@"%d work day left", (int)businessDays];
			}else{
				timeString = [NSString stringWithFormat:@"%d work days left", (int)businessDays];
			}
		}
	}

	NSSize prjSize = [projectString sizeWithAttributes: textAttributes];
	NSSize timeSize = [timeString sizeWithAttributes: textAttributes];
	int maxW = MAX(prjSize.width, timeSize.width);

	int prjOffset = (maxW - prjSize.width) / 2;
	int timeOffset = (maxW - timeSize.width) / 2;

	NSImage * jakeImg = [NSImage imageNamed:@"jake"];
	NSRect r = NSZeroRect;
	r.size = [jakeImg size];

	int w = maxW + TRAILING_OFFSET + LEADING_OFFSET + r.size.width + IMG_SPACING ;
	NSImage * im = [ [NSImage alloc] initWithSize: NSMakeSize( w, MENU_HW ) ];

	[im lockFocus];
	[jakeImg drawAtPoint:NSZeroPoint fromRect:r operation:NSCompositeSourceOver fraction:1];

	int TEXT_V_OFFSET = [[NSScreen mainScreen] backingScaleFactor] > 1.0 ? 0 : 1;
	[projectString drawAtPoint: NSMakePoint( r.size.width + IMG_SPACING +LEADING_OFFSET + prjOffset, TEXT_V_OFFSET + MENU_HW / 2 - TEXT_V_OFFSET/2 - 1 )
				withAttributes:alternate ? textAttributesAlt : textAttributes];

	[timeString drawAtPoint: NSMakePoint( r.size.width + IMG_SPACING + LEADING_OFFSET + timeOffset, TEXT_V_OFFSET)
			 withAttributes:alternate ? textAttributesAlt : textAttributes];

	[im unlockFocus];

	return im;
}


- (NSDateComponents*)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime{
    NSDate *fromDate;
    NSDate *toDate;

    NSCalendar *calendar = [NSCalendar currentCalendar];

    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate
				 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate
				 interval:NULL forDate:toDateTime];

    NSDateComponents *difference = [calendar components:NSDayCalendarUnit
											   fromDate:fromDate toDate:toDate options:0];
    return difference;
}


- (IBAction)refresh: (id)whatever{
	NSImage* i = [self createImage: false];
	[_statusItem setImage:i];
	[i release];

	i = [self createImage: true];
	[_statusItem setAlternateImage:i];
	[i release];
}


- (IBAction)do:(id)sender{
	switch ([sender tag]) {
	case 2: //settings
		[prefsWin makeKeyAndOrderFront:self];
		[NSApp activateIgnoringOtherApps:YES];
		//[prefsWin setLevel:NSNormalWindowLevel + 1];
		break;

	case 1: //quit
		[NSApp terminate:self];
		break;

	default: break;
	}
}

@end