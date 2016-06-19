//
//  ContactsGroupsVC.h
//  Groups
//
//  Created by Michael Helvey on 6/18/16.
//  Copyright © 2016 Michael Helvey. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CNContact;
@class CNGroup;
@class ContactsGroupsVC;

@protocol ContactsGroupsDelegate <NSObject>

@optional
-(void)contactsGroupSelector:(ContactsGroupsVC *)vc finishedWithGroups:(NSArray <CNGroup *>*)groups;

@end

@interface ContactsGroupsVC : UITableViewController

@property CNContact *contact;

@property id<ContactsGroupsDelegate>delegate;

@property NSArray *currentFilter;

@end
