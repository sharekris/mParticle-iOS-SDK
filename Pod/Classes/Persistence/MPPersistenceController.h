//
//  MPPersistenceController.h
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

#import "MParticleUserNotification.h"

@class MPSegment;
@class MPCommand;
@class MPMessage;
@class MPProductBag;
@class MPSession;
@class MPUpload;
@class MPStandaloneCommand;
@class MPStandaloneMessage;
@class MPStandaloneUpload;
@class MPCookie;
@class MPConsumerInfo;
@class MPForwardRecord;
@class MPBreadcrumb;

typedef NS_ENUM(NSUInteger, MPPersistenceOperation) {
    MPPersistenceOperationDelete = 0,
    MPPersistenceOperationFlag
};

@interface MPPersistenceController : NSObject

@property (nonatomic, readonly, getter = isDatabaseOpen) BOOL databaseOpen;

+ (nonnull instancetype)sharedInstance;
- (void)archiveSession:(nonnull MPSession *)session completionHandler:(void (^ _Nullable)(MPSession * _Nullable archivedSession))completionHandler;
- (BOOL)closeDatabase;
- (NSUInteger)countMesssagesForUploadInSession:(nonnull MPSession *)session;
- (NSUInteger)countStandaloneMessages;
- (void)deleteCommand:(nonnull MPCommand *)command;
- (void)deleteConsumerInfo;
- (void)deleteCookie:(nonnull MPCookie *)cookie;
- (void)deleteExpiredUserNotifications;
- (void)deleteForwardRecodsIds:(nonnull NSArray<NSNumber *> *)forwardRecordsIds;
- (void)deleteMessagesWithNoSession;
- (void)deleteNetworkPerformanceMessages;
- (void)deletePreviousSession;
- (void)deleteProductBag:(nonnull MPProductBag *)productBag;
- (void)deleteAllProductBags;
- (void)deleteRecordsOlderThan:(NSTimeInterval)timestamp;
- (void)deleteSegments;
- (void)deleteSession:(nonnull MPSession *)session;
- (void)deleteUpload:(nonnull MPUpload *)upload;
- (void)deleteUploadId:(int64_t)uploadId;
- (void)deleteUserNotification:(nonnull MParticleUserNotification *)userNotification;
- (void)deleteStandaloneCommand:(nonnull MPStandaloneCommand *)standaloneCommand;
- (void)deleteStandaloneMessage:(nonnull MPStandaloneMessage *)standaloneMessage;
- (void)deleteStandaloneMessageIds:(nonnull NSArray<NSNumber *> *)standaloneMessageIds;
- (void)deleteStandaloneUpload:(nonnull MPStandaloneUpload *)standaloneUpload;
- (void)deleteStandaloneUploadId:(int64_t)standaloneUploadId;
- (nullable NSArray<MPBreadcrumb *> *)fetchBreadcrumbs;
- (void)fetchCommandsInSession:(nonnull MPSession *)session completionHandler:(void (^ _Nonnull)(NSArray<MPCommand *> * _Nullable commands))completionHandler;
- (nullable MPConsumerInfo *)fetchConsumerInfo;
- (void)fetchConsumerInfo:(void (^ _Nonnull)(MPConsumerInfo * _Nullable consumerInfo))completionHandler;
- (nullable NSArray<MPCookie *> *)fetchCookies;
- (nullable NSArray<MParticleUserNotification *> *)fetchDisplayedLocalUserNotifications;
- (nullable NSArray<MParticleUserNotification *> *)fetchDisplayedRemoteUserNotifications;
- (nullable NSArray<MParticleUserNotification *> *)fetchDisplayedLocalUserNotificationsSince:(NSTimeInterval)referenceDate;
- (nullable NSArray<MParticleUserNotification *> *)fetchDisplayedRemoteUserNotificationsSince:(NSTimeInterval)referenceDate;
- (nullable NSArray<MPForwardRecord *> *)fetchForwardRecords;
- (nullable NSArray<MPMessage *> *)fetchMessagesInSession:(nonnull MPSession *)session;
- (void)fetchMessagesForUploadingInSession:(nonnull MPSession *)session completionHandler:(void (^ _Nonnull)(NSArray<MPMessage *> * _Nullable messages))completionHandler;
- (nullable NSArray<MPSession *> *)fetchPossibleSessionsFromCrash;
- (void)fetchPreviousSession:(void (^ _Nonnull)(MPSession * _Nullable previousSession))completionHandler;
- (nullable MPProductBag *)fetchProductBag:(nonnull NSString *)bagName;
- (nullable NSArray<MPProductBag *> *)fetchProductBags;
- (nullable NSArray<MPSegment *> *)fetchSegments;
- (nullable MPMessage *)fetchSessionEndMessageInSession:(nonnull MPSession *)session;
- (nullable MPSession *)fetchSessionFromCrash;
- (void)fetchSessions:(void (^ _Nonnull)(NSMutableArray<MPSession *> * _Nullable sessions))completionHandler;
- (void)fetchUploadedMessagesInSession:(nonnull MPSession *)session excludeNetworkPerformanceMessages:(BOOL)excludeNetworkPerformance completionHandler:(void (^ _Nonnull)(NSArray<MPMessage *> * _Nullable messages))completionHandler;
- (void)fetchUploadsInSession:(nonnull MPSession *)session completionHandler:(void (^ _Nonnull)(NSArray<MPUpload *> * _Nullable uploads))completionHandler;
- (void)fetchUserNotificationCampaignHistory:(void (^ _Nonnull)(NSArray<MParticleUserNotification *> * _Nullable userNotificationCampaignHistory))completionHandler;
- (nullable NSArray<MParticleUserNotification *> *)fetchUserNotifications;
- (nullable NSArray<MPStandaloneCommand *> *)fetchStandaloneCommands;
- (nullable NSArray<MPStandaloneMessage *> *)fetchStandaloneMessages;
- (nullable NSArray<MPStandaloneMessage *> *)fetchStandaloneMessagesForUploading;
- (nullable NSArray<MPStandaloneUpload *> *)fetchStandaloneUploads;
- (void)purgeMemory;
- (BOOL)openDatabase;
- (void)saveBreadcrumb:(nonnull MPMessage *)message session:(nonnull MPSession *)session;
- (void)saveCommand:(nonnull MPCommand *)command;
- (void)saveConsumerInfo:(nonnull MPConsumerInfo *)consumerInfo;
- (void)saveForwardRecord:(nonnull MPForwardRecord *)forwardRecord;
- (void)saveMessage:(nonnull MPMessage *)message;
- (void)saveProductBag:(nonnull MPProductBag *)productBag;
- (void)saveSegment:(nonnull MPSegment *)segment;
- (void)saveSession:(nonnull MPSession *)session;
- (void)saveUpload:(nonnull MPUpload *)upload messageIds:(nonnull NSArray<NSNumber *> *)messageIds operation:(MPPersistenceOperation)operation;
- (void)saveUserNotification:(nonnull MParticleUserNotification *)userNotification;
- (void)saveStandaloneCommand:(nonnull MPStandaloneCommand *)standaloneCommand;
- (void)saveStandaloneMessage:(nonnull MPStandaloneMessage *)standaloneMessage;
- (void)saveStandaloneUpload:(nonnull MPStandaloneUpload *)standaloneUpload;
- (void)updateConsumerInfo:(nonnull MPConsumerInfo *)consumerInfo;
- (void)updateSession:(nonnull MPSession *)session;
- (void)updateUserNotification:(nonnull MParticleUserNotification *)userNotification;

@end
