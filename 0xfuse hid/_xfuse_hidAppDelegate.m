//
//  _xfuse_hidAppDelegate.m
//  0xfuse hid
//
//  Created by 0xfuse on 8/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "_xfuse_hidAppDelegate.h"

#include <IOKit/IOKitLib.h>
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/hid/IOHIDDevice.h>
#include <IOKit/hid/IOHIDKeys.h>
#include <unistd.h>

_xfuse_hidAppDelegate* app_deletate;

boolean_t connected = false;

long int idVendor  = 0;
long int idProduct = 0;

int adc_value = 0;
int adc_ch    = 0;

CFTypeRef   vendor_id;
CFTypeRef   product_id;
CFStringRef str;



NSString *name;

IOHIDManagerRef         hid_manager;
CFMutableDictionaryRef  dict;
IOReturn                ret;
CFSetRef                device_set;
IOHIDDeviceRef          device_list[256];
IOHIDDeviceRef          dev_ref;
uint8_t                 *buf;
uint8_t                 *send_buf;
int                     num_devices;

@implementation _xfuse_hidAppDelegate

@synthesize window;
@synthesize state;
@synthesize device_name;
@synthesize idProduct_tf;
@synthesize idVendor_tf;
@synthesize adc_tf;
@synthesize adc_volts_tf;
@synthesize led_button;
@synthesize led_label;

static void delay_ms(unsigned int msec) {
    
    usleep(msec * 1000);
}

float perc(int value)
{
    //    printf("perc = %0.2f\n",((float)value / 255.0) *100);
    return ((float)value / 255.0) *100;
}

float volts(int value)
{
    //    printf("volts = %0.2f\n",((float)value * 5) / 255);
    return ((float)value * 5.0) / 255.5;
}

static long int hid_write(IOHIDDeviceRef dev, const unsigned char *data, size_t length)
{
	const unsigned char *data_to_send;
	size_t length_to_send;
	IOReturn res;
	
	/* Return if the device has been disconnected. */
   	if (!connected)
   		return -1;
	
	if (data[0] == 0x0) {
		/* Not using numbered Reports.
		 Don't send the report number. */
		data_to_send = data+1;
		length_to_send = length-1;
	}
	else {
		/* Using numbered Reports.
		 Send the Report Number */
		data_to_send = data;
		length_to_send = length;
	}
	
	if (connected) {
		res = IOHIDDeviceSetReport(dev,
								   kIOHIDReportTypeOutput,
								   data[0], /* Report ID*/
								   data_to_send, length_to_send);
		
		if (res == kIOReturnSuccess) {
			return length;
		}
		else
			return -1;
	}
	
	return -1;
}

static void input_callback(void *context, IOReturn result, void *sender, 
                           IOHIDReportType type, uint32_t reportID, uint8_t *report,
                           CFIndex reportLength)
{
    [app_deletate setStateText:@"Connected."];
    connected = true;
    
    [app_deletate setLedButtonHidden:NO];
    
    vendor_id = IOHIDDeviceGetProperty(sender, CFSTR(kIOHIDVendorIDKey));
    CFNumberGetValue( ( CFNumberRef ) vendor_id, kCFNumberSInt32Type, &idVendor );
    
    
    product_id = IOHIDDeviceGetProperty(sender, CFSTR(kIOHIDProductIDKey));
    CFNumberGetValue( ( CFNumberRef ) product_id, kCFNumberSInt32Type, &idProduct);
    
    str = IOHIDDeviceGetProperty(sender, CFSTR( kIOHIDProductKey ));
    if (str)
    {
        name = (NSString*)str;        
    }
    
	adc_ch    = buf[0];
    adc_value = buf[1];
    [app_deletate setLedButtonOn:buf[2]];
	
    [app_deletate refresh];
    
    //    printf("0x%lx\n0x%lx\n",idVendor,idProduct);
}

static void unplug_callback(void *hid, IOReturn ret, void *ref)
{ 
    [app_deletate clear_tf];
    [app_deletate setStateText:@"Not Connected."];
    connected = false;
    [app_deletate setLedButtonHidden:YES];
}

- (void)awakeFromNib 
{
    // GUI Init
    
    [led_button setHidden:YES];
    [led_label setHidden:YES];
    
    [state setTextColor:[NSColor colorWithDeviceRed:00 green:0xff blue:0 alpha:1]];
    
    NSImage *wallpaper = [NSImage imageNamed:@"Wallpaper.jpg"];
    [wallpaper setSize:CGSizeMake(200, 140)];
    NSColor *background = [NSColor colorWithPatternImage:wallpaper];
    [window setBackgroundColor:background];
    
    [wallpaper release];
    
}

- (IBAction)led:(id)button
{
    send_buf = (uint8_t *)malloc(64);
    send_buf[0] = ([button state] ? 1 : 0); // led state 1 on , 0 off 
    
    IOHIDDeviceSetReport(dev_ref,
                         kIOHIDReportTypeOutput,
                         send_buf[0], /* Report ID*/
                         (unsigned char*)send_buf, sizeof(send_buf)+1);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    app_deletate = self;
    
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(check_hid) userInfo:nil repeats:YES];
}

- (void)clear_tf 
{
    [device_name setStringValue:@"Device Name:"];
    [idVendor_tf setStringValue:@"idVendor:"];
    [idProduct_tf setStringValue:@"idProduct:"];
    [adc_tf setStringValue:@"ADC (CH):"];
    [adc_volts_tf setStringValue:@"ADC (CH):"];
}

- (void)refresh 
{
    [device_name setStringValue:[NSString stringWithFormat:@"Device Name:\t\t%@",name]];
    [idVendor_tf setStringValue:[NSString stringWithFormat:@"idVendor:\t\t\t\t\t0x%lx",idVendor]];
    [idProduct_tf setStringValue:[NSString stringWithFormat:@"idProduct:\t\t\t\t\t0x%lx",idProduct]];
    [adc_tf setStringValue:[NSString stringWithFormat:@"ADC (CH%d):\t\t\t\t%0.1f %%",adc_ch,perc(adc_value)]];
    [adc_volts_tf setStringValue:[NSString stringWithFormat:@"ADC (CH%d):\t\t\t\t%0.1f V",adc_ch,volts(adc_value)]];
}

- (void)check_hid
{    
    if (!connected) {
		
        // get access to the HID Manager
        hid_manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        
        if (hid_manager == NULL || CFGetTypeID(hid_manager) != IOHIDManagerGetTypeID()) {
            
            [self setStateText:@"HID/macos: unable to access HID manager"];
        }    
        
        dict = IOServiceMatching(kIOHIDDeviceKey);
        if (dict == NULL) {
            
            [self setStateText:@"HID/macos: unable to create iokit dictionary"];
        }
        
		int usage_page = 0xff20;
		int usage      = 0x0200;
        
        if (usage_page > 0) {
            CFDictionarySetValue(dict, CFSTR(kIOHIDPrimaryUsagePageKey), 
                                 CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &usage_page));
        }
        if (usage > 0) {
            CFDictionarySetValue(dict, CFSTR(kIOHIDPrimaryUsageKey),
                                 CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &usage));
        }
        IOHIDManagerSetDeviceMatching(hid_manager, dict);
        
        // now open the HID manager
        ret = IOHIDManagerOpen(hid_manager, kIOHIDOptionsTypeNone);
        if (ret != kIOReturnSuccess) {
            printf("HID/macos: Unable to open HID manager (IOHIDManagerOpen failed)");
            return;
        }
        // get a list of devices that match our requirements
        device_set = IOHIDManagerCopyDevices(hid_manager);
        if (device_set == NULL) {
            [self setStateText:@"No Devices Found."];
            return;
        }
        num_devices = (int)CFSetGetCount(device_set);
        //printf("number of devices found = %d\n", num_devices);
        if (num_devices < 1) {
            CFRelease(device_set);
            printf("HID/macos: no devices found, even though HID manager returned a set\n");
            [self setStateText:@"No Devices Found though HID manager returned a set"];
            return;
        }
        if (num_devices > 256) {
            CFRelease(device_set);
            printf("HID/macos: too many devices, we get confused if more than 256!\n");
            return;
        }
        CFSetGetValues(device_set, (const void **)&device_list);
        CFRelease(device_set);
        // open the first device in the list
        ret = IOHIDDeviceOpen(device_list[0], kIOHIDOptionsTypeNone);
        if (ret != kIOReturnSuccess) {
            printf("HID/macos: error opening device\n");
            return;
        }
        // return this device
        
        buf = (uint8_t *)malloc(0x1000);
        if (buf == NULL) {
            IOHIDDeviceRegisterRemovalCallback(device_list[0], NULL, NULL);
            IOHIDDeviceClose(device_list[0], kIOHIDOptionsTypeNone);
            printf("HID/macos: Unable to allocate memory\n");
            return;
        }
        
        dev_ref = device_list[0];
        
        // register a callback to receive input
        IOHIDDeviceRegisterInputReportCallback(dev_ref, buf, 0x1000,
                                               input_callback, NULL);
        
        
        // register a callback to find out when it's unplugged
        IOHIDDeviceScheduleWithRunLoop(dev_ref, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        IOHIDDeviceRegisterRemovalCallback(dev_ref, unplug_callback, NULL);
        
    }
}

- (void)setLedButtonOn:(int)enabled
{
    [led_button setState:enabled];
}

- (void)setLedButtonHidden:(int)hidden
{
    [led_button setHidden:hidden];
    [led_label setHidden:hidden];
}

- (void)setStateText:(NSString*)text
{    
    [state setStringValue:text];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    if (connected) {
        
        IOHIDDeviceRegisterRemovalCallback(dev_ref, NULL, NULL);
        IOHIDDeviceClose(dev_ref, kIOHIDOptionsTypeNone);
    }   
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
