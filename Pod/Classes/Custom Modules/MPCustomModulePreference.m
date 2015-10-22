//
//  MPCustomModulePreference.m
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

#import "MPCustomModulePreference.h"
#import "NSUserDefaults+mParticle.h"
#import "MPAppboy.h"
#import "MPStateMachine.h"
#import "MPLogger.h"

@interface MPCustomModulePreference()

@property (nonatomic, strong) NSString *location;

@end


@implementation MPCustomModulePreference

- (instancetype)initWithDictionary:(NSDictionary *)preferenceDictionary location:(NSString *)location moduleId:(NSNumber *)moduleId {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _dataType = [preferenceDictionary[kMPRemoteConfigCustomModuleDataTypeKey] intValue];
    _moduleId = [moduleId copy];

    NSArray *macroPlaceholders = @[@"%gn%", @"%oaid%", @"%dt%", @"%glsb%"];
    NSString *defaultValue = preferenceDictionary[kMPRemoteConfigCustomModuleDefaultKey];
    
    if ([macroPlaceholders containsObject:defaultValue]) {
        _defaultValue = [self defaultValueForMacroPlaceholder:defaultValue];
    } else {
        if (defaultValue) {
            _defaultValue = defaultValue;
        } else {
            switch (_dataType) {
                case MPDataTypeString:
                    _defaultValue = @"";
                    break;
                    
                case MPDataTypeInt:
                case MPDataTypeLong:
                    _defaultValue = @"0";
                    break;
                    
                case MPDataTypeBool:
                    _defaultValue = @"false";
                    break;
                    
                case MPDataTypeFloat:
                    _defaultValue = @"0.0";
                    break;
            }
        }
    }
    
    _location = location;
    _readKey = preferenceDictionary[kMPRemoteConfigCustomModuleReadKey];
    _value = nil;
    _writeKey = preferenceDictionary[kMPRemoteConfigCustomModuleWriteKey];
    
    return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPCustomModulePreference *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject->_defaultValue = [_defaultValue copy];
        copyObject.location = [_location copy];
        copyObject->_readKey = [_readKey copy];
        copyObject.value = [_value copy];
        copyObject->_writeKey = [_writeKey copy];
        copyObject->_dataType = _dataType;
    }
    
    return copyObject;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.defaultValue forKey:@"defaultValue"];
    [coder encodeObject:self.location forKey:@"location"];
    [coder encodeObject:self.readKey forKey:@"readKey"];
    [coder encodeObject:self.value forKey:@"value"];
    [coder encodeObject:self.writeKey forKey:@"writeKey"];
    [coder encodeInteger:self.dataType forKey:@"dataType"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _defaultValue = [coder decodeObjectForKey:@"defaultValue"];
    _location = [coder decodeObjectForKey:@"location"];
    _readKey = [coder decodeObjectForKey:@"readKey"];
    _value = [coder decodeObjectForKey:@"value"];
    _writeKey = [coder decodeObjectForKey:@"writeKey"];
    _dataType = [coder decodeIntegerForKey:@"dataType"];

    return self;
}

#pragma mark Private methods
- (NSString *)appBoyJSONStringFromDictionary:(NSDictionary *)dictionary {
    NSMutableDictionary *jsonDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    if (dictionary[@"deviceIdentifier"]) {
        jsonDictionary[@"deviceIdentifier"] = dictionary[@"deviceIdentifier"];
    }
    
    if (dictionary[@"externalUserId"]) {
        jsonDictionary[@"externalUserId"] = dictionary[@"externalUserId"];
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
    
    NSString *jsonString = nil;
    if (!error) {
        jsonString  = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return jsonString;
}

- (NSString *)defaultValueForMacroPlaceholder:(NSString *)macroPlaceholder {
    NSString *defaultValue = @"";
    
    if ([macroPlaceholder isEqualToString:@"%gn%"]) {
        defaultValue = [self uuidWithNoDashes];
    } else if ([macroPlaceholder isEqualToString:@"%oaid%"]) {
        NSString *uuidString = [self uuidWithNoDashes];
        
        const char *c_uuidString = [uuidString cStringUsingEncoding:NSASCIIStringEncoding];
        char pos0 = c_uuidString[0];
        char pos16 = c_uuidString[16];
        
        if (pos0 >= '8') {
            pos0 = (char)(arc4random_uniform(8) + '0');
        }
        
        if (pos16 >= '4') {
            pos16 = (char)(arc4random_uniform(4) + '0');
        }
        
        defaultValue = [[NSString alloc] initWithFormat:@"%c%@-%c%@", pos0, [uuidString substringWithRange:NSMakeRange(1, 15)], pos16, [uuidString substringWithRange:NSMakeRange(17, 15)]];
    } else if ([macroPlaceholder isEqualToString:@"%dt%"]) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss Z"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

        defaultValue = [dateFormatter stringFromDate:[NSDate date]];
    } else if ([macroPlaceholder isEqualToString:@"%glsb%"]) {
        CFUUIDRef uuidRef;
#ifndef MP_UNIT_TESTING
        uuidRef = CFUUIDCreate(kCFAllocatorDefault);
#else
        int testOption = arc4random_uniform(3);
        switch (testOption) {
            case 0: // 87bab465-f904-4354-938b-e2dd2d532441 returns -7814903288795290559
                uuidRef = CFUUIDCreateFromString(kCFAllocatorDefault, (__bridge CFStringRef)@"87bab465-f904-4354-938b-e2dd2d532441");
                break;
                
            case 1: // d37a5f3c-8a04-4fbe-aaf4-2834cc9ab8f6 returns -6128228985708300042
                uuidRef = CFUUIDCreateFromString(kCFAllocatorDefault, (__bridge CFStringRef)@"d37a5f3c-8a04-4fbe-aaf4-2834cc9ab8f6");
                break;
                
            default: // 3b0915ff-1b6c-44a9-6774-5b69188f581c returns 7454683790146754588
                uuidRef = CFUUIDCreateFromString(kCFAllocatorDefault, (__bridge CFStringRef)@"3b0915ff-1b6c-44a9-6774-5b69188f581c");
                break;
        }
#endif
        
        CFUUIDBytes uuidBytes = CFUUIDGetUUIDBytes(uuidRef);
        
        SInt64 lsbBytes[8] = {uuidBytes.byte8, uuidBytes.byte9, uuidBytes.byte10, uuidBytes.byte11,
                              uuidBytes.byte12, uuidBytes.byte13, uuidBytes.byte14, uuidBytes.byte15};
        
        SInt64 value = 0;
        int i = 8;
        while (i--) {
            value |= lsbBytes[i] << ((7 - i) * 8);
        }

        CFRelease(uuidRef);

        defaultValue = [@(value) stringValue];
    }
    
    return defaultValue;
}

- (NSString *)uuidWithNoDashes {
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    NSMutableString *uuidString = [NSMutableString stringWithString:(__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, UUIDRef)];
    CFRelease(UUIDRef);
    
    NSRange dashRange = [uuidString rangeOfString:@"-"];
    while (dashRange.location != NSNotFound) {
        [uuidString deleteCharactersInRange:dashRange];
        dashRange = [uuidString rangeOfString:@"-"];
    }
    
    return [uuidString copy];
}

#pragma mark Public methods
- (id)value {
    if (_value) {
        return _value;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *deprecatedKey = [NSString stringWithFormat:@"cms::%@", self.writeKey];
    NSString *customModuleKey = [NSString stringWithFormat:@"cms::%@::%@", self.moduleId, self.writeKey];
    
    id valueWithDeprecatedKey = userDefaults[deprecatedKey];
    if (valueWithDeprecatedKey) {
        _value = valueWithDeprecatedKey;
        userDefaults[customModuleKey] = _value;
        [userDefaults removeMPObjectForKey:deprecatedKey];
        return _value;
    }
    
    _value = userDefaults[customModuleKey];
    if (_value) {
        return _value;
    }
    
    NSDictionary *userDefaultsDictionary = [userDefaults dictionaryRepresentation];
    NSArray *keys = [userDefaultsDictionary allKeys];

    if ([keys containsObject:self.readKey]) {
        if ([_moduleId isEqual:@(MPCustomModuleIdAppBoy)]) {
            NSData *appboyData = [userDefaults objectForKey:self.readKey];
            if (appboyData) {
                id appboy = [NSKeyedUnarchiver unarchiveObjectWithData:appboyData];
                
                if ([appboy isKindOfClass:[NSDictionary class]]) {
                    _value = [self appBoyJSONStringFromDictionary:appboy];
                } else {
                    @try {
                        _value = [appboy jsonString];
                    } @catch (NSException *exception) {
                        MPLogError(@"Could not parse Appboy data with exception reason: %@", [exception reason]);
                    }
                }
            }
        } else {
            _value = [userDefaults objectForKey:self.readKey];
        }
        
        if (!_value && self.dataType != MPDataTypeString) {
            switch (self.dataType) {
                case MPDataTypeInt:
                case MPDataTypeLong:
                    _value = @([userDefaults integerForKey:self.readKey]);
                    break;
                    
                case MPDataTypeBool:
                    _value = @([userDefaults boolForKey:self.readKey]);
                    break;
                    
                case MPDataTypeFloat:
                    _value = @([userDefaults floatForKey:self.readKey]);
                    break;
                    
                default:
                    _value = self.defaultValue;
                    break;
            }
        }
    } else {
        switch (self.dataType) {
            case MPDataTypeString:
                _value = self.defaultValue;
                break;
                
            case MPDataTypeInt:
            case MPDataTypeLong:
                _value = @([self.defaultValue integerValue]);
                break;
                
            case MPDataTypeBool:
                _value = [self.defaultValue isEqualToString:@"false"] || [self.defaultValue isEqualToString:@"NO"] || [self.defaultValue isEqualToString:@"0"] ? @NO : @YES;
                break;
                
            case MPDataTypeFloat:
                _value = @([self.defaultValue floatValue]);
                break;
        }
    }

    userDefaults[customModuleKey] = _value;
    
    return _value;
}

@end