//
//  MPDevice.m
//
//  Copyright 2015 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPDevice.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <mach/machine.h>
#import "MPStateMachine.h"
#import "NSUserDefaults+mParticle.h"
#import <objc/runtime.h>
#import <mach-o/ldsyms.h>
#import <dlfcn.h>
#import <mach-o/arch.h>
#import <mach-o/dyld.h>
#import "MPNotificationController.h"
#import "MPConstants.h"

#if !defined(MP_NO_IDFA)
#import "AdSupport/ASIdentifierManager.h"
#endif

NSString *const kMPDeviceInformationKey = @"di";
NSString *const kMPDeviceBrandKey = @"b";
NSString *const kMPDeviceProductKey = @"p";
NSString *const kMPDeviceNameKey = @"dn";
NSString *const kMPDeviceAdvertiserIdKey = @"aid";
NSString *const kMPDeviceAppVendorIdKey = @"vid";
NSString *const kMPDeviceManufacturerKey = @"dma";
NSString *const kMPDevicePlatformKey = @"dp";
NSString *const kMPDeviceOSKey = @"dosv";
NSString *const kMPDeviceModelKey = @"dmdl";
NSString *const kMPScreenHeightKey = @"dsh";
NSString *const kMPScreenWidthKey = @"dsw";
NSString *const kMPDeviceLocaleCountryKey = @"dlc";
NSString *const kMPDeviceLocaleLanguageKey = @"dll";
NSString *const kMPNetworkCountryKey = @"nc";
NSString *const kMPNetworkCarrierKey = @"nca";
NSString *const kMPMobileNetworkCodeKey = @"mnc";
NSString *const kMPMobileCountryCodeKey = @"mcc";
NSString *const kMPTimezoneOffsetKey = @"tz";
NSString *const kMPTimezoneDescriptionKey = @"tzn";
NSString *const kMPDeviceJailbrokenKey = @"jb";
NSString *const kMPDeviceArchitectureKey = @"arc";
NSString *const kMPDeviceRadioKey = @"dr";
NSString *const floatingPointFormat = @"%0.0f";
NSString *const signerIdentityString = @"signeridentity";
NSString *const kMPDeviceIsTabletKey = @"it";
NSString *const kMPDeviceIdentifierKey = @"deviceIdentifier";
NSString *const kMPDeviceLimitAdTrackingKey = @"lat";

static NSDictionary *jailbrokenInfo;

int main(int argc, char *argv[]);

@interface MPDevice() {
    NSCalendar *calendar;
    NSDictionary *deviceInfo;
    CTTelephonyNetworkInfo *telephonyNetworkInfo;
}

@end


@implementation MPDevice

@synthesize advertiserId = _advertiserId;
@synthesize architecture = _architecture;
@synthesize deviceIdentifier = _deviceIdentifier;
@synthesize model = _model;
@synthesize vendorId = _vendorId;
@synthesize radioAccessTechnology = _radioAccessTechnology;
@synthesize screenSize = _screenSize;

+ (void)initialize {
    jailbrokenInfo = nil;
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    telephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}

#pragma mark Accessors
- (NSString *)advertiserId {
    if (_advertiserId) {
        return _advertiserId;
    }
    
    Class MPIdentifierManager = NSClassFromString(@"ASIdentifierManager");
    if (MPIdentifierManager) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString(@"sharedManager");
        id<NSObject> adIdentityManager = [MPIdentifierManager performSelector:selector];
        
        selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL advertisingTrackingEnabled = (BOOL)[adIdentityManager performSelector:selector];
        if (advertisingTrackingEnabled) {
            selector = NSSelectorFromString(@"advertisingIdentifier");
            _advertiserId = [[adIdentityManager performSelector:selector] UUIDString];
        }
#pragma clang diagnostic pop
#pragma clang diagnostic pop
    }

    return _advertiserId;
}

- (NSString *)architecture {
    if (_architecture) {
        return _architecture;
    }
    
    NSMutableString *cpu = [[NSMutableString alloc] init];
    size_t size;
    cpu_type_t type;
    cpu_subtype_t subtype;
    size = sizeof(type);
    sysctlbyname("hw.cputype", &type, &size, NULL, 0);
    
    size = sizeof(subtype);
    sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);
    
    // values for cputype and cpusubtype defined in mach/machine.h
    if (type == CPU_TYPE_X86) {
        [cpu appendString:@"x86"];
    } else if (type == CPU_TYPE_ARM) {
        [cpu appendString:@"arm"];
        
        switch(subtype) {
            case CPU_SUBTYPE_ARM_V7:
                [cpu appendString:@"v7"];
                break;
                
            case CPU_SUBTYPE_ARM_V7S:
                [cpu appendString:@"v7s"];
                break;
        }
#if !TARGET_IPHONE_SIMULATOR
    } else if (type == CPU_TYPE_ARM64) {
        [cpu appendString:@"arm64"];
#endif
    } else {
        [cpu appendString:@"unknown"];
    }
    
    _architecture = [cpu copy];
    
    return _architecture;
}

- (NSString *)brand {
    return [UIDevice currentDevice].model;
}

- (CTCarrier *)carrier {
    return telephonyNetworkInfo.subscriberCellularProvider;
}

- (NSString *)country {
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

- (NSString *)deviceIdentifier {
    if (_deviceIdentifier) {
        return _deviceIdentifier;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _deviceIdentifier = userDefaults[kMPDeviceIdentifierKey];
    if (!_deviceIdentifier) {
        _deviceIdentifier = [[NSUUID UUID] UUIDString];
        userDefaults[kMPDeviceIdentifierKey] = _deviceIdentifier;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [userDefaults synchronize];
        });
    }
    
    return _deviceIdentifier;
}

- (BOOL)isTablet {
    BOOL isTablet = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
    return isTablet;
}

- (NSString *)language {
    return [[NSLocale preferredLanguages] objectAtIndex:0];
}

- (NSNumber *)limitAdTracking {
    return self.advertiserId == nil ? @YES : @NO;
}

- (NSString *)manufacturer __attribute__((const)) {
    return @"Apple";
}

- (NSString *)model {
    if (_model) {
        return _model;
    }
    
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *name = malloc(size);
    sysctlbyname("hw.machine", name, &size, NULL, 0);
    _model = [NSString stringWithUTF8String:name];
    free(name);
    
    if (!_model) {
        _model = @"Not available.";
    }
    
    return _model;
}

- (NSString *)name {
    return [UIDevice currentDevice].name;
}

- (NSString *)platform __attribute__((const)) {
    return @"iOS";
}

- (NSString *)product {
    return [UIDevice currentDevice].model;
}

- (NSData *)pushNotificationToken {
    return [MPNotificationController deviceToken];
}

- (NSString *)operatingSystem {
    return [UIDevice currentDevice].systemVersion;
}

- (NSString *)timezoneOffset {
    float timeZoneOffset = ([[NSTimeZone systemTimeZone] secondsFromGMT] / 3600.0);
    return [NSString stringWithFormat:floatingPointFormat, timeZoneOffset];
}

- (NSString *)timezoneDescription {
    return [[calendar timeZone] name];
}

- (NSString *)vendorId {
    if (_vendorId) {
        return _vendorId;
    }
    
    _vendorId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    return _vendorId;
}

- (NSString *)radioAccessTechnology {
    if (_radioAccessTechnology) {
        return _radioAccessTechnology;
    }
    
    NSString *radioAccessTechnology = telephonyNetworkInfo.currentRadioAccessTechnology;
    
    if (radioAccessTechnology) {
        NSRange range = [radioAccessTechnology rangeOfString:@"CTRadioAccessTechnology"];
        radioAccessTechnology = [radioAccessTechnology substringFromIndex:NSMaxRange(range)];
    } else {
        radioAccessTechnology = @"None";
    }
    _radioAccessTechnology = radioAccessTechnology;
    
    return _radioAccessTechnology;
}

- (CGSize)screenSize {
    if (!CGSizeEqualToSize(_screenSize, CGSizeZero)) {
        return _screenSize;
    }
    
	CGRect bounds = [[UIScreen mainScreen] bounds];
	CGFloat scale = [[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0;
	_screenSize = CGSizeMake(bounds.size.width * scale, bounds.size.height * scale);
    
    return _screenSize;
}

#pragma mark NSCopying
- (instancetype)copyWithZone:(NSZone *)zone {
    MPDevice *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject->_advertiserId = [_advertiserId copy];
        copyObject->_architecture = [_architecture copy];
        copyObject->_model = [_model copy];
        copyObject->_vendorId = [_vendorId copy];
        copyObject->_radioAccessTechnology = [_radioAccessTechnology copy];
        copyObject->_screenSize = _screenSize;
    }
    
    return copyObject;
}

#pragma mark Public class methods
+ (NSDictionary *)jailbrokenInfo {
    if (jailbrokenInfo) {
        return jailbrokenInfo;
    }
    
    BOOL jailbroken = NO;
    
#if !TARGET_IPHONE_SIMULATOR
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath;
    NSString *signerIdentityKey = nil;
    NSDictionary *bundleInfoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSEnumerator *infoEnumerator = [bundleInfoDictionary keyEnumerator];
    NSString *key;
    
    while ((key = [infoEnumerator nextObject])) {
        if ([[key lowercaseString] isEqualToString:signerIdentityString]) {
            signerIdentityKey = [key copy];
            break;
        }
    }
    
    jailbroken = signerIdentityKey != nil;
    
    if (!jailbroken) {
        NSArray *filePaths = @[@"/usr/sbin/sshd",
                               @"/Library/MobileSubstrate/MobileSubstrate.dylib",
                               @"/bin/bash",
                               @"/usr/libexec/sftp-server",
                               @"/Applications/Cydia.app",
                               @"/Applications/blackra1n.app",
                               @"/Applications/FakeCarrier.app",
                               @"/Applications/Icy.app",
                               @"/Applications/IntelliScreen.app",
                               @"/Applications/MxTube.app",
                               @"/Applications/RockApp.app",
                               @"/Applications/SBSettings.app",
                               @"/Applications/WinterBoard.app",
                               @"/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
                               @"/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
                               @"/private/var/lib/apt",
                               @"/private/var/lib/cydia",
                               @"/private/var/mobile/Library/SBSettings/Themes",
                               @"/private/var/stash",
                               @"/private/var/tmp/cydia.log",
                               @"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
                               @"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist"];
        
        for (filePath in filePaths) {
            jailbroken = [fileManager fileExistsAtPath:filePath];
            
            if (jailbroken) {
                break;
            }
        }
    }
    
    if (!jailbroken) {
        // Valid test only if running as root on a jailbroken device
        NSData *jailbrokenTestData = [@"Jailbroken filesystem test." dataUsingEncoding:NSUTF8StringEncoding];
        filePath = @"/private/mpjailbrokentest.txt";
        jailbroken = [jailbrokenTestData writeToFile:filePath atomically:NO];
        
        if (jailbroken) {
            [fileManager removeItemAtPath:filePath error:nil];
        }
    }
#endif

    jailbrokenInfo = @{kMPDeviceCydiaJailbrokenKey:@(jailbroken)};
    
    return jailbrokenInfo;
}

#pragma mark Public instance methods
- (NSDictionary *)dictionaryRepresentation {
    if (deviceInfo) {
        return deviceInfo;
    }
    
    NSMutableDictionary *deviceDictionary = [@{kMPDeviceBrandKey:self.model,
                                               kMPDeviceNameKey:self.name,
                                               kMPDeviceProductKey:self.model,
                                               kMPDeviceOSKey:self.operatingSystem,
                                               kMPDeviceModelKey:self.model,
                                               kMPDeviceArchitectureKey:self.architecture,
                                               kMPScreenWidthKey:[NSString stringWithFormat:floatingPointFormat, self.screenSize.width],
                                               kMPScreenHeightKey:[NSString stringWithFormat:floatingPointFormat, self.screenSize.height],
                                               kMPDevicePlatformKey:self.platform,
                                               kMPDeviceManufacturerKey:self.manufacturer,
                                               kMPTimezoneOffsetKey:self.timezoneOffset,
                                               kMPTimezoneDescriptionKey:self.timezoneDescription,
                                               kMPDeviceRadioKey:self.radioAccessTechnology,
                                               kMPDeviceJailbrokenKey:[MPDevice jailbrokenInfo],
                                               kMPDeviceIsTabletKey:@(self.tablet)}
                                             mutableCopy];
    
    NSData *pushNotificationToken = self.pushNotificationToken;
    if (pushNotificationToken) {
        deviceDictionary[kMPDeviceTokenKey] = [NSString stringWithFormat:@"%@", pushNotificationToken];
    }

    NSString *auxString;
    auxString = self.language;
    if (auxString) {
        deviceDictionary[kMPDeviceLocaleLanguageKey] = auxString;
    }
    
    auxString = self.country;
    if (auxString) {
        deviceDictionary[kMPDeviceLocaleCountryKey] = auxString;
    }
    
    auxString = self.advertiserId;
    if (auxString) {
        deviceDictionary[kMPDeviceAdvertiserIdKey] = auxString;
    }
    
    auxString = self.vendorId;
    if (auxString) {
        deviceDictionary[kMPDeviceAppVendorIdKey] = auxString;
    }
    
    NSNumber *limitAdTracking = self.limitAdTracking;
    if (limitAdTracking) {
        deviceDictionary[kMPDeviceLimitAdTrackingKey] = limitAdTracking;
    }
    
    CTCarrier *carrier = self.carrier;
    if (carrier) {
        auxString = carrier.carrierName;
        if (auxString) {
            deviceDictionary[kMPNetworkCarrierKey] = auxString;
        }
        
        auxString = carrier.isoCountryCode;
        if (auxString) {
            deviceDictionary[kMPNetworkCountryKey] = auxString;
        }
        
        auxString = carrier.mobileNetworkCode;
        if (auxString) {
            deviceDictionary[kMPMobileNetworkCodeKey] = auxString;
        }
        
        auxString = carrier.mobileCountryCode;
        if (auxString) {
            deviceDictionary[kMPMobileCountryCodeKey] = auxString;
        }
    }
    
    if ([MPStateMachine sharedInstance].deviceTokenType.length > 0) {
        deviceDictionary[kMPDeviceTokenTypeKey] = [MPStateMachine sharedInstance].deviceTokenType;
    }
    
    BOOL cacheDeviceInfo = (auxString != nil) && (limitAdTracking != nil);
    if (cacheDeviceInfo) {
        deviceInfo = (NSDictionary *)deviceDictionary;
        
        return deviceInfo;
    } else {
        return (NSDictionary *)deviceDictionary;
    }
}

@end
