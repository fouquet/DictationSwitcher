//
//  DictationSwitcherAppDelegate.m
//  DictationSwitcher
//
//  Created by René Fouquet on 28.07.12.
//  Copyright (c) 2012 René Fouquet. All rights reserved.
//

#import "DictationSwitcherAppDelegate.h"

@implementation DictationSwitcherAppDelegate
@synthesize dictationSwitcherMenu;

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
                                                             [NSNumber numberWithBool:TRUE], @"showIcon",
                                                             [NSNumber numberWithBool:FALSE], @"openAtLogin",
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
    
    dictationSwitcherItem = [[NSStatusBar systemStatusBar] statusItemWithLength:22];
    [dictationSwitcherItem setMenu:dictationSwitcherMenu];

    [dictationSwitcherItem setHighlightMode:YES];
    [dictationSwitcherItem setToolTip:@"DictationSwitcher"];
    
    // Apple's Information regarding Dictation agreed to?
    
    [defaults addSuiteNamed:@"com.apple.speech.recognition.AppleSpeechRecognition.prefs"];
    
    if (![defaults boolForKey:@"DictationIMIntroMessagePresented"]) {
        [self openTermsNotAgreedToWindow];
        [dictationSwitcherItem setMenu:nil];
    }
    
    // See if we're set as a login item
    
    // First, assume we are not
    
    [defaults setBool:FALSE forKey:@"openAtLogin"];
    
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    
    // Create a reference to the shared file list, search the list:
    
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems, NULL);
    
    if (loginItems) {
        UInt32 seedValue;
        NSArray  *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
        for(int i = 0 ; i< [loginItemsArray count]; i++){
            LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray
                                                                                 objectAtIndex:i];
            
            if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
                NSString * urlPath = [(__bridge NSURL*)url path];
                if ([urlPath compare:appPath] == NSOrderedSame){
                    
                    // We are!
                    
                    [defaults setBool:TRUE forKey:@"openAtLogin"];
                }
            }
        }
    }

    
    // Grab the current dictation language settings:
    
    [self getCurrentLanguageSettings];
    //Set status bar icon according to settings
    [self setStatusBarIcon];
}

-(void)getCurrentLanguageSettings {
    
    // Grab the dictation language settings in the propertly list file for the dictation preference pane:
       

    //[DictationIMLocaleIdentifier setString:[NSString stringWithFormat:@"%@", [defaults objectForKey:@"DictationIMLocaleIdentifier"]]];
    DictationIMLocaleIdentifier = [[NSMutableString alloc] initWithFormat:@"%@", [defaults objectForKey:@"DictationIMLocaleIdentifier"]];
    // Check the appropriate language:
    
        if ([DictationIMLocaleIdentifier isEqualToString:@"en-AU"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:1];
            [[dictationSwitcherMenu itemWithTag:1] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"en-GB"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:2];
            [[dictationSwitcherMenu itemWithTag:2] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"en-US"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:3];
            [[dictationSwitcherMenu itemWithTag:3] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"fr-FR"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:4];
            [[dictationSwitcherMenu itemWithTag:4] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"de-DE"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:5];
            [[dictationSwitcherMenu itemWithTag:5] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"ja-JP"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:6];
            [[dictationSwitcherMenu itemWithTag:6] setState:NSOnState];
        }
}

- (void)setStatusBarIcon{
    if (!dictationDisabled) {
        if([defaults boolForKey:@"showIcon"]){
            [dictationSwitcherItem setImage:[[NSBundle mainBundle] imageForResource:DictationIMLocaleIdentifier]];
            [dictationSwitcherItem setAlternateImage:[[NSBundle mainBundle] imageForResource:DictationIMLocaleIdentifier]];
        } else {
            [dictationSwitcherItem setImage:[[NSBundle mainBundle] imageForResource:@"statusicon"]];
            [dictationSwitcherItem setAlternateImage:[[NSBundle mainBundle] imageForResource:@"statusicon-alt"]];
        }
    } else {
        [dictationSwitcherItem setImage:[[NSBundle mainBundle] imageForResource:@"statusicon-off"]];
        [dictationSwitcherItem setAlternateImage:[[NSBundle mainBundle] imageForResource:@"statusicon-off-alt"]];
    }
}

-(IBAction)useDefaultStatusBarIcon:(id)sender{
    [self setStatusBarIcon];
}

- (IBAction)switchLanguage:(id)sender {
    
    // Some language menu item was activated. Set the locale identifier accordingly:
    
    switch ([sender tag]) {
        case 1:
            [DictationIMLocaleIdentifier setString:@"en-AU"];
            break;
            
        case 2:
            [DictationIMLocaleIdentifier setString:@"en-GB"];
            break;
            
        case 3:
            [DictationIMLocaleIdentifier setString:@"en-US"];
            break;
            
        case 4:
            [DictationIMLocaleIdentifier setString:@"fr-FR"];
            break;
            
        case 5:
            [DictationIMLocaleIdentifier setString:@"de-DE"];
            break;
            
        case 6:
            [DictationIMLocaleIdentifier setString:@"ja-JP"];
            break;
            
        default:
            break;
    }
    [self setStatusBarIcon];
    
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
    
        [sender setTitle:NSLocalizedString(@"Turn dictation on", nil)];

        [self setStatusBarIcon];

        [defaults setPersistentDomain:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"Dictation Enabled"]
                      forName:@"com.apple.assistant.support"];
    } else {
        dictationDisabled=FALSE;

        [sender setTitle:NSLocalizedString(@"Turn dictation off", nil)];

        [self setStatusBarIcon];

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

-(IBAction)openAtLogin:(id)sender {
    
    if([sender state]==NSOnState) {
        
        // Grab the Application Bundle path:
        
        NSString * appPath = [[NSBundle mainBundle] bundlePath];
        CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
        
        // Create a reference to the shared file list and insert the item:
        
        LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                                kLSSharedFileListSessionLoginItems, NULL);
        if (loginItems) {
            LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
                                                                         kLSSharedFileListItemLast, NULL, NULL,
                                                                         url, NULL, NULL);
            if (item){
                CFRelease(item);
            }
        }
        
        CFRelease(loginItems);
        
    } else {
        
        // Grab the Application Bundle path:
        
        NSString *appPath = [[NSBundle mainBundle] bundlePath];
        CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
        
        // Create a reference to the shared file list, search the list and remove the item:
        
        LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                                kLSSharedFileListSessionLoginItems, NULL);
        
        if (loginItems) {
            UInt32 seedValue;
            NSArray  *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
            for(int i = 0 ; i< [loginItemsArray count]; i++){
                LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray
                                                                                     objectAtIndex:i];
                
                if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
                    NSString * urlPath = [(__bridge NSURL*)url path];
                    if ([urlPath compare:appPath] == NSOrderedSame){
                        LSSharedFileListItemRemove(loginItems,itemRef);
                    }
                }
            }
        }

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
