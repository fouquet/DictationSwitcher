//
//  DictationSwitcherAppDelegate.m
//  DictationSwitcher
//
//  Created by René Fouquet on 28.07.12.
//  Copyright (c) 2012 René Fouquet. All rights reserved.
//

#import "DictationSwitcherAppDelegate.h"
#import "MASShortcutView.h"
#import "MASShortcutView+UserDefaults.h"
#import "MASShortcut+UserDefaults.h"
#import "MASShortcut+Monitoring.h"

NSString *const kPreferenceKeyShortcut = @"hotKey";
NSString *const kPreferenceKeyShortcutEnabled = @"hotKeyEnabled";

@implementation DictationSwitcherAppDelegate {
    __weak id _constantShortcutMonitor;
}

@synthesize shortcutView = _shortcutView;
@synthesize dictationSwitcherMenu;

- (void)awakeFromNib
{
    [self.shortcutView bind:@"enabled" toObject:self withKeyPath:@"shortcutEnabled" options:nil];
}

-(void)dealloc {
    [self.shortcutView unbind:@"enabled"];
}

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
                                                             [NSNumber numberWithBool:TRUE], @"zh-CN",
                                                             [NSNumber numberWithBool:TRUE], @"zh-HK",
                                                             [NSNumber numberWithBool:TRUE], @"zh-TW",
                                                             [NSNumber numberWithBool:TRUE], @"en-CA",
                                                             [NSNumber numberWithBool:TRUE], @"fr-CA",
                                                             [NSNumber numberWithBool:TRUE], @"fr-CH",
                                                             [NSNumber numberWithBool:TRUE], @"de-CH",
                                                             [NSNumber numberWithBool:TRUE], @"it-IT",
                                                             [NSNumber numberWithBool:TRUE], @"it-CH",
                                                             [NSNumber numberWithBool:TRUE], @"ko-KR",
                                                             [NSNumber numberWithBool:TRUE], @"es-MX",
                                                             [NSNumber numberWithBool:TRUE], @"es-ES",
                                                             [NSNumber numberWithBool:TRUE], @"es-US",
                                                             [NSNumber numberWithBool:FALSE], @"hotKeyEnabled",
                                                             [NSNumber numberWithBool:FALSE], @"showIcon",
                                                             [NSNumber numberWithInt:1], @"hotKeyFirstLanguage",
                                                             [NSNumber numberWithInt:2], @"hotKeySecondLanguage",
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
            LSSharedFileListItemRef itemRef = (__bridge  LSSharedFileListItemRef)[loginItemsArray
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
    [self setStatusBarIcon:nil];
    
    // Shortcut view will follow and modify user preferences automatically
    self.shortcutView.associatedUserDefaultsKey = kPreferenceKeyShortcut;
    
    // Activate the global keyboard shortcut if it was enabled last time
    [self resetShortcutRegistration];
}

-(void)getCurrentLanguageSettings {
    
    // Grab the dictation language settings in the propertly list file for the dictation preference pane:
    
    DictationIMLocaleIdentifier = [[NSMutableString alloc] initWithFormat:@"%@", [defaults objectForKey:@"DictationIMLocaleIdentifier"]];
    
    // Check the appropriate language:
    
        if ([DictationIMLocaleIdentifier isEqualToString:@"en-AU"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:4];
            [[dictationSwitcherMenu itemWithTag:4] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"en-GB"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:6];
            [[dictationSwitcherMenu itemWithTag:6] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"en-US"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:7];
            [[dictationSwitcherMenu itemWithTag:7] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"fr-FR"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:9];
            [[dictationSwitcherMenu itemWithTag:9] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"de-DE"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:11];
            [[dictationSwitcherMenu itemWithTag:11] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"ja-JP"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:15];
            [[dictationSwitcherMenu itemWithTag:15] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"zh-CN"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:1];
            [[dictationSwitcherMenu itemWithTag:1] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"zh-HK"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:2];
            [[dictationSwitcherMenu itemWithTag:2] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"zh-TW"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:3];
            [[dictationSwitcherMenu itemWithTag:3] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"en-CA"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:5];
            [[dictationSwitcherMenu itemWithTag:5] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"fr-CA"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:8];
            [[dictationSwitcherMenu itemWithTag:8] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"fr-CH"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:10];
            [[dictationSwitcherMenu itemWithTag:10] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"de-CH"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:12];
            [[dictationSwitcherMenu itemWithTag:12] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"it-IT"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:13];
            [[dictationSwitcherMenu itemWithTag:13] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"it-CH"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:14];
            [[dictationSwitcherMenu itemWithTag:14] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"ko-KR"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:16];
            [[dictationSwitcherMenu itemWithTag:16] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"es-MX"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:17];
            [[dictationSwitcherMenu itemWithTag:17] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"es-ES"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:18];
            [[dictationSwitcherMenu itemWithTag:18] setState:NSOnState];
        }
        if ([DictationIMLocaleIdentifier isEqualToString:@"es-US"]) {
            previousSender=[dictationSwitcherMenu itemWithTag:19];
            [[dictationSwitcherMenu itemWithTag:19] setState:NSOnState];
        }
}

- (IBAction)setStatusBarIcon:(id)sender {
    if (!dictationDisabled) {
        if ([defaults boolForKey:@"showIcon"]) {
            [dictationSwitcherItem setImage:[[NSBundle mainBundle] imageForResource:[defaults objectForKey:@"DictationIMLocaleIdentifier"]]];
            [dictationSwitcherItem setAlternateImage:[[NSBundle mainBundle] imageForResource:[defaults objectForKey:@"DictationIMLocaleIdentifier"]]];
        } else {
            [dictationSwitcherItem setImage:[[NSBundle mainBundle] imageForResource:@"statusicon"]];
            [dictationSwitcherItem setAlternateImage:[[NSBundle mainBundle] imageForResource:@"statusicon-alt"]];
        }
    } else {
        [dictationSwitcherItem setImage:[[NSBundle mainBundle] imageForResource:@"statusicon-off"]];
        [dictationSwitcherItem setAlternateImage:[[NSBundle mainBundle] imageForResource:@"statusicon-off-alt"]];
    }
}

- (IBAction)useDefaultStatusBarIcon:(id)sender{
    [self setStatusBarIcon:nil];
}

- (IBAction)switchLanguage:(id)sender {
    
    // Some language menu item was activated. Set the locale identifier accordingly:

    switch ([sender tag]) {
        case 4:
            [DictationIMLocaleIdentifier setString:@"en-AU"];
            break;
            
        case 6:
            [DictationIMLocaleIdentifier setString:@"en-GB"];
            break;
            
        case 7:
            [DictationIMLocaleIdentifier setString:@"en-US"];
            break;
            
        case 9:
            [DictationIMLocaleIdentifier setString:@"fr-FR"];
            break;
            
        case 11:
            [DictationIMLocaleIdentifier setString:@"de-DE"];
            break;
            
        case 15:
            [DictationIMLocaleIdentifier setString:@"ja-JP"];
            break;
            
        case 1:
            [DictationIMLocaleIdentifier setString:@"zh-CN"];
            break;
            
        case 2:
            [DictationIMLocaleIdentifier setString:@"zh-HK"];
            break;
            
        case 3:
            [DictationIMLocaleIdentifier setString:@"zh-TW"];
            break;
            
        case 5:
            [DictationIMLocaleIdentifier setString:@"en-CA"];
            break;
            
        case 8:
            [DictationIMLocaleIdentifier setString:@"fr-CA"];
            break;
            
        case 10:
            [DictationIMLocaleIdentifier setString:@"fr-CH"];
            break;
            
        case 12:
            [DictationIMLocaleIdentifier setString:@"de-CH"];
            break;
            
        case 13:
            [DictationIMLocaleIdentifier setString:@"it-IT"];
            break;
            
        case 14:
            [DictationIMLocaleIdentifier setString:@"it-CH"];
            break;
            
        case 16:
            [DictationIMLocaleIdentifier setString:@"ko-KR"];
            break;
            
        case 17:
            [DictationIMLocaleIdentifier setString:@"es-MX"];
            break;
            
        case 18:
            [DictationIMLocaleIdentifier setString:@"es-ES"];
            break;
        
        case 19:
            [DictationIMLocaleIdentifier setString:@"es-US"];
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
        
    NSArray* ironwoods=[NSRunningApplication runningApplicationsWithBundleIdentifier: @"com.apple.inputmethod.ironwood"];
    if (ironwoods!=nil && [ironwoods count]>0) {
        int pid=[[ironwoods objectAtIndex:0] processIdentifier];
        
        // Kill it with fire:
        [[NSTask launchedTaskWithLaunchPath:@"/bin/kill" arguments:[NSArray arrayWithObjects:@"-hup",[NSString stringWithFormat:@"%i",pid], nil]] waitUntilExit];
    }
    [self setStatusBarIcon:nil];

}

- (IBAction)toggleDictation:(id)sender {

 
    // Turn dictation on/off:

    if (!dictationDisabled) {
        dictationDisabled=TRUE;
    
        [sender setTitle:NSLocalizedString(@"Turn dictation on", nil)];

        [self setStatusBarIcon:nil];

        [defaults setPersistentDomain:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"Dictation Enabled"]
                      forName:@"com.apple.assistant.support"];
    } else {
        dictationDisabled=FALSE;

        [sender setTitle:NSLocalizedString(@"Turn dictation off", nil)];

        [self setStatusBarIcon:nil];

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

# pragma mark Window stuff

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

# pragma mark Useful methods

-(int)returnCountryIdentifier:(NSString*)countryCode {
    
    int identifier;
    
    if ([countryCode isEqualTo:@"en-AU"]) identifier = 4;
    if ([countryCode isEqualTo:@"en-GB"]) identifier = 6;
    if ([countryCode isEqualTo:@"en-US"]) identifier = 7;
    if ([countryCode isEqualTo:@"fr-FR"]) identifier = 9;
    if ([countryCode isEqualTo:@"de-DE"]) identifier = 11;
    if ([countryCode isEqualTo:@"ja-JP"]) identifier = 15;
    if ([countryCode isEqualTo:@"zh-CN"]) identifier = 1;
    if ([countryCode isEqualTo:@"zh-HK"]) identifier = 2;
    if ([countryCode isEqualTo:@"zh-TW"]) identifier = 3;
    if ([countryCode isEqualTo:@"en-CA"]) identifier = 5;
    if ([countryCode isEqualTo:@"fr-CA"]) identifier = 8;
    if ([countryCode isEqualTo:@"fr-CH"]) identifier = 10;
    if ([countryCode isEqualTo:@"de-CH"]) identifier = 12;
    if ([countryCode isEqualTo:@"it-IT"]) identifier = 13;
    if ([countryCode isEqualTo:@"it-CH"]) identifier = 14;
    if ([countryCode isEqualTo:@"ko-KR"]) identifier = 16;
    if ([countryCode isEqualTo:@"es-MX"]) identifier = 17;
    if ([countryCode isEqualTo:@"es-ES"]) identifier = 18;
    if ([countryCode isEqualTo:@"es-US"]) identifier = 19;

    return identifier;
}

-(NSString*)returnCountryCode:(int)identifier {
    
    NSString *countryCode;
    
    switch (identifier) {
        case 4:
            countryCode=@"en-AU";
            break;
        case 6:
            countryCode=@"en-GB";
            break;
        case 7:
            countryCode=@"en-US";
            break;
        case 9:
            countryCode=@"fr-FR";
            break;
        case 11:
            countryCode=@"de-DE";
            break;
        case 15:
            countryCode=@"ja-JP";
            break;
        case 1:
            countryCode=@"zh-CN";
            break;
        case 2:
            countryCode=@"zh-HK";
            break;
        case 3:
            countryCode=@"zh-TW";
            break;
        case 5:
            countryCode=@"en-CA";
            break;
        case 8:
            countryCode=@"fr-CA";
            break;
        case 10:
            countryCode=@"fr-CH";
            break;
        case 12:
            countryCode=@"de-CH";
            break;
        case 13:
            countryCode=@"it-IT";
            break;
        case 14:
            countryCode=@"it-CH";
            break;
        case 16:
            countryCode=@"ko-KR";
            break;
        case 17:
            countryCode=@"es-MX";
            break;
        case 18:
            countryCode=@"es-ES";
            break;
        case 19:
            countryCode=@"es-US";
            break;
    }

    return countryCode;
}


# pragma mark Hotkey

- (BOOL)isShortcutEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceKeyShortcutEnabled];
}

- (void)setShortcutEnabled:(BOOL)enabled {
    if (self.shortcutEnabled != enabled) {
        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kPreferenceKeyShortcutEnabled];
        [self resetShortcutRegistration];
    }
}

- (void)resetShortcutRegistration {
    if (self.shortcutEnabled) {
        [MASShortcut registerGlobalShortcutWithUserDefaultsKey:kPreferenceKeyShortcut handler:^{
            if ([defaults integerForKey:@"hotKeyMode"]==0) { // All languages
                NSString *currentLanguage=[defaults objectForKey:@"DictationIMLocaleIdentifier"];
                    for (int i=[self returnCountryIdentifier:currentLanguage];i<20;i++) {
                        if (i==19) i=0;
                        if ([defaults boolForKey:[self returnCountryCode:i+1]]) {
                            NSControl *sender=[dictationSwitcherMenu itemWithTag:i+1];
                            [self switchLanguage:sender];
                            return;
                        }
                    }
            } else { // Two predefined languages
                if ([defaults integerForKey:@"hotKeyPrevLang"]==[defaults integerForKey:@"hotKeyFirstLanguage"]) {
                    NSControl *sender=[dictationSwitcherMenu itemWithTag:[defaults integerForKey:@"hotKeySecondLanguage"]];
                    [self switchLanguage:sender];
                    [defaults setInteger:[defaults integerForKey:@"hotKeySecondLanguage"] forKey:@"hotKeyPrevLang"];
                } else {
                    NSControl *sender=[dictationSwitcherMenu itemWithTag:[defaults integerForKey:@"hotKeyFirstLanguage"]];
                    [self switchLanguage:sender];
                    [defaults setInteger:[defaults integerForKey:@"hotKeyFirstLanguage"] forKey:@"hotKeyPrevLang"];
                }
            }
        }];
    }
    else {
        [MASShortcut unregisterGlobalShortcutWithUserDefaultsKey:kPreferenceKeyShortcut];
    }
}



@end
