//
//  MPNotificationController.h
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

#import <UIKit/UIKit.h>
#import "MParticleUserNotification.h"

@class MParticleUserNotification;

@protocol MPNotificationControllerDelegate;

@interface MPNotificationController : NSObject

@property (nonatomic, strong, readonly, nullable) NSString *initialRedactedUserNotificationString;
@property (nonatomic, weak) id<MPNotificationControllerDelegate> delegate;
@property (nonatomic, unsafe_unretained) NSTimeInterval influencedOpenTimer;
@property (nonatomic, unsafe_unretained, readonly) BOOL registeredForSilentNotifications;

+ (nullable NSData *)deviceToken;
+ (nullable NSDictionary *)dictionaryFromLocalNotification:(nonnull UILocalNotification *)notification;
+ (void)setDeviceToken:(nullable NSData *)devToken;
- (nonnull instancetype)initWithDelegate:(nonnull id<MPNotificationControllerDelegate>)delegate;
- (nonnull MParticleUserNotification *)newUserNotificationWithDictionary:(nonnull NSDictionary *)notificationDictionary actionIdentifier:(nullable NSString *)actionIdentifier state:(nullable NSString *)state;
- (void)registerForSilentNotifications;
- (void)scheduleNotification:(nonnull MParticleUserNotification *)userNotification;

@end

@protocol MPNotificationControllerDelegate <NSObject>
- (void)receivedUserNotification:(nonnull MParticleUserNotification *)userNotification;
@end