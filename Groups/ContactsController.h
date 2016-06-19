//
//  ContactsController.h
//  Groups
//
//  Created by Michael Helvey on 6/18/16.
//  Copyright © 2016 Michael Helvey. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CNContact;
@class CNGroup;

@protocol ContactsControllerDelegate <NSObject>

-(void)delegateReloadData;

@end

@interface ContactsController : NSObject

@property id<ContactsControllerDelegate>delegate;

-(NSArray<CNContact *>*)contacts;

-(NSArray<CNGroup *>*)groups;

-(void)requestPermissionsWithCompletion:(void (^)(BOOL success, NSError *error))completion;

-(void)fetchWithCompletion:(void (^)(BOOL results, NSError *error))completion;

-(void)fetchContactsForGroups:(NSArray<CNGroup*>*)groups withCompletion:(void (^)(BOOL results, NSError *error))completion;

-(void)searchForText:(NSString *)name withCompletion:(void (^)(BOOL results, NSError *error))completion;

-(void)deleteContact:(CNContact *)contact withCompletion:(void (^)(BOOL results, NSError *error))completion;

-(void)addGroupWithName:(NSString *)name;

-(void)addContact:(CNContact *)contact toGroup:(CNGroup *)group;

-(void)removeContact:(CNContact *)contact fromGroup:(CNGroup *)group;

-(void)deleteGroup:(CNGroup *)group;

-(NSArray *)groupsForContact:(CNContact *)contact;

@end
