//
//  DictationSwitcherAppDelegate.h
//  DictationSwitcher
//
//  Created by René Fouquet on 28.07.12.
//  Copyright (c) 2012 René Fouquet. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DictationSwitcherAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *dictationSwitcherMenu;
    NSStatusItem *dictationSwitcherItem;
    id previousSender;
    NSString *DictationIMLocaleIdentifier;
    NSWindow *settingsWindow;
    BOOL dictationDisabled;
    NSMenuItem *dictationOnOff;
    NSUserDefaults *defaults;
    NSWindow *termsNotAgreedToWindow;
}

- (IBAction)switchLanguage:(id)sender;
- (IBAction)toggleDictation:(id)sender;
- (IBAction)gotToPreferences:(id)sender;
- (IBAction)openSettings:(id)sender;
- (IBAction)openAboutPanel:(id)sender;
- (IBAction)goToPreferencesFromTermsNotAgreedToWindow:(id)sender;
- (IBAction)justQuit:(id)sender;

@property (strong) IBOutlet NSMenu *dictationSwitcherMenu;

@end
