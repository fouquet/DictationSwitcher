//
//  DictationSwitcherAppDelegate.m
//  DictationSwitcher
//
//  Created by René Fouquet on 28.07.12.
//  Copyright (c) 2012 René Fouquet. All rights reserved.
//

#import "DictationSwitcherAppDelegate.h"

@implementation DictationSwitcherAppDelegate
@synthesize statusMenu;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Register standards for displayed languages in the menu (all of them!)
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [NSNumber numberWithBool:TRUE], @"en-AU",
                                                             [NSNumber numberWithBool:TRUE], @"en-GB",
                                                             [NSNumber numberWithBool:TRUE], @"en-US",
                                                             [NSNumber numberWithBool:TRUE], @"fr-FR",
                                                             [NSNumber numberWithBool:TRUE], @"de-DE",
                                                             [NSNumber numberWithBool:TRUE], @"ja-JP",
                                                             nil]];
    defaults = [[NSUserDefaults alloc] init];
    
    // Is dictation activated?
    
    [defaults addSuiteNamed:@"com.apple.assistant.support"];
    
    if ([defaults boolForKey:@"Dictation Enabled"]) {
        dictationDisabled=FALSE;
        [dictationOnOff setTitle:NSLocalizedString(@"Turn dictation off", nil)];
    } else {
        dictationDisabled=TRUE;
        [dictationOnOff setTitle:NSLocalizedString(@"Turn dictation on", nil)];
    }
    
    // Put the status item:
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:22];
    [statusItem setMenu:statusMenu];
    if (!dictationDisabled) {
        [statusItem setImage:[[NSBundle mainBundle] imageForResource:@"statusicon"]];
        [statusItem setAlternateImage:[[NSBundle mainBundle] imageForResource:@"statusicon-alt"]];
    } else {
        [statusItem setImage:[[NSBundle mainBundle] imageForResource:@"statusicon-off"]];
        [statusItem setAlternateImage:[[NSBundle mainBundle] imageForResource:@"statusicon-off-alt"]];
    }

    [statusItem setHighlightMode:YES];
    [statusItem setToolTip:@"DictationSwitcher"];
    
    // Apple's Information regarding Dictation agreed to?
    
    [defaults addSuiteNamed:@"com.apple.speech.recognition.AppleSpeechRecognition.prefs"];
    
    if (![defaults boolForKey:@"DictationIMIntroMessagePresented"]) {
        [self openTermsNotAgreedToWindow];
        [statusItem setMenu:nil];
    }
    
    // Grab the current dictation language settings:
    
    [self getCurrentLanguageSettings];
}

-(void)getCurrentLanguageSettings {
    
    // Grab the dictation language settings in the propertly list file for the dictation preference pane:
       
    NSString *settings=[defaults objectForKey:@"DictationIMLocaleIdentifier"];
    
    // Check the appropriate language:
    
        if ([settings isEqualToString:@"en-AU"]) {
            previousSender=[statusMenu itemWithTag:1];
            [[statusMenu itemWithTag:1] setState:NSOnState];
        }
        if ([settings isEqualToString:@"en-GB"]) {
            previousSender=[statusMenu itemWithTag:2];
            [[statusMenu itemWithTag:2] setState:NSOnState];
        }
        if ([settings isEqualToString:@"en-US"]) {
            previousSender=[statusMenu itemWithTag:3];
            [[statusMenu itemWithTag:3] setState:NSOnState];
        }
        if ([settings isEqualToString:@"fr-FR"]) {
            previousSender=[statusMenu itemWithTag:4];
            [[statusMenu itemWithTag:4] setState:NSOnState];
        }
        if ([settings isEqualToString:@"de-DE"]) {
            previousSender=[statusMenu itemWithTag:5];
            [[statusMenu itemWithTag:5] setState:NSOnState];
        }
        if ([settings isEqualToString:@"ja-JP"]) {
            previousSender=[statusMenu itemWithTag:6];
            [[statusMenu itemWithTag:6] setState:NSOnState];
        }
   // }
}

- (IBAction)switchLanguage:(id)sender {
    
    // Some language menu item was activated. Set the locale identifier accordingly:
    
    switch ([sender tag]) {
        case 1:
            DictationIMLocaleIdentifier=@"en-AU";
            break;
            
        case 2:
            DictationIMLocaleIdentifier=@"en-GB";
            break;
            
        case 3:
            DictationIMLocaleIdentifier=@"en-US";
            break;
            
        case 4:
            DictationIMLocaleIdentifier=@"fr-FR";
            break;
            
        case 5:
            DictationIMLocaleIdentifier=@"de-DE";
            break;
            
        case 6:
            DictationIMLocaleIdentifier=@"ja-JP";
            break;
            
        default:
            break;
    }
    
    // Deactivate the previous checkmark (if available) and set the checkmark:
    
    if ((previousSender != nil) && (previousSender != sender)) [previousSender setState:NSOffState];
    
    [sender setState:NSOnState];
    previousSender=sender;
    
    // Write the settings into the property lists:
    
    [defaults setPersistentDomain:[NSDictionary dictionaryWithObjectsAndKeys:
                                    DictationIMLocaleIdentifier, @"DictationIMLocaleIdentifier",
                                    [NSNumber numberWithBool:YES],@"DictationIMIntroMessagePresented",
                                    [NSNumber numberWithBool:YES],@"AppleIronwoodCanAutoEnable",nil]
                            forName:@"com.apple.speech.recognition.AppleSpeechRecognition.prefs"];
    
    [defaults synchronize];

    
    [defaults setPersistentDomain:[NSDictionary dictionaryWithObject:DictationIMLocaleIdentifier forKey:@"Session Language"]
                          forName:@"com.apple.assistant"];
    
    [defaults synchronize];
    
    
    // Get the DictationIM process ID:
        
    if ([NSRunningApplication runningApplicationsWithBundleIdentifier: @"com.apple.inputmethod.ironwood"]!=nil) {
        int pid=[[[NSRunningApplication runningApplicationsWithBundleIdentifier: @"com.apple.inputmethod.ironwood"] objectAtIndex:0] processIdentifier];
        
        // Kill it with fire:
        [[NSTask launchedTaskWithLaunchPath:@"/bin/kill" arguments:[NSArray arrayWithObjects:@"-hup",[NSString stringWithFormat:@"%i",pid], nil]] waitUntilExit];
    }

}

- (IBAction)toggleDictation:(id)sender {

 
    // Turn dictation on/off:

    if (!dictationDisabled) {
        dictationDisabled=TRUE;
    
        [sender setTitle:NSLocalizedString(@"Turn dictation on", nil)],
    
        [statusItem setImage:[[NSBundle mainBundle] imageForResource:@"statusicon-off"]];
        [statusItem setAlternateImage:[[NSBundle mainBundle] imageForResource:@"statusicon-off-alt"]];
    
        [defaults setPersistentDomain:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"Dictation Enabled"]
                      forName:@"com.apple.assistant.support"];
    } else {
        dictationDisabled=FALSE;

        [sender setTitle:NSLocalizedString(@"Turn dictation off", nil)],
    
        [statusItem setImage:[[NSBundle mainBundle] imageForResource:@"statusicon"]];
        [statusItem setAlternateImage:[[NSBundle mainBundle] imageForResource:@"statusicon-alt"]];

        [defaults setPersistentDomain:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"Dictation Enabled"]
                          forName:@"com.apple.assistant.support"];
    }

    [defaults synchronize];

    // Get the DictationIM process ID:

    
    if ([NSRunningApplication runningApplicationsWithBundleIdentifier: @"com.apple.inputmethod.ironwood"]!=nil) {
        int pid=[[[NSRunningApplication runningApplicationsWithBundleIdentifier: @"com.apple.inputmethod.ironwood"] objectAtIndex:0] processIdentifier];
        
        // Kill it with fire:
        [[NSTask launchedTaskWithLaunchPath:@"/bin/kill" arguments:[NSArray arrayWithObjects:@"-hup",[NSString stringWithFormat:@"%i",pid], nil]] waitUntilExit];
    }

}

- (IBAction)gotToPreferences:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Speech.prefPane"];
}

- (IBAction)openSettings:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [settingsWindow makeKeyAndOrderFront:nil];
}

- (IBAction)openAboutPanel:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:nil];
}

-(void)openTermsNotAgreedToWindow {
    [NSApp activateIgnoringOtherApps:YES];
    [termsNotAgreedToWindow makeKeyAndOrderFront:nil];
}

- (IBAction)goToPreferencesFromTermsNotAgreedToWindow:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Speech.prefPane"];
    [NSApp terminate:nil];
}

- (IBAction)justQuit:(id)sender {
    [NSApp terminate:nil];
}

@end
