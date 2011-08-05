/*
 *  _xfuse_hidAppDelegate.h
 *  0xfuse hid
 *
 *  Created by 0xfuse on 8/6/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@interface _xfuse_hidAppDelegate : NSObject <NSApplicationDelegate> {
    @private
        NSWindow *window;
        NSTextField *device_name;
        NSTextField *idVendor_tf;
        NSTextField *idProduct_tf;
        NSTextField *state;
        NSTextField *adc_tf;
        NSTextField *adc_volts_tf;
        NSButton    *led_button;
        NSTextField *led_label;
        
    }
@property (assign , readwrite) IBOutlet NSWindow *window;
@property (assign , readwrite) IBOutlet NSTextField *device_name;
@property (assign , readwrite) IBOutlet NSTextField *idVendor_tf;
@property (assign , readwrite) IBOutlet NSTextField *idProduct_tf;
@property (assign , readwrite) IBOutlet NSTextField *state;
@property (assign , readwrite) IBOutlet NSTextField *adc_tf;
@property (assign , readwrite) IBOutlet NSTextField *adc_volts_tf;
@property (assign , readwrite) IBOutlet NSButton    *led_button;
@property (assign , readwrite) IBOutlet NSTextField *led_label;
    
- (IBAction)led:(id)button;
- (void)setStateText:(NSString*)text;
- (void)refresh;
- (void)clear_tf;
- (void)setLedButtonOn:(int)enabled;
- (void)setLedButtonHidden:(int)hidden;
    
static void delay_ms(unsigned int msec);
    
@end