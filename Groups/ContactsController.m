//
//  ContactsController.m
//  Groups
//
//  Created by Michael Helvey on 6/18/16.
//  Copyright © 2016 Michael Helvey. All rights reserved.
//

@import Contacts;
#import "ContactsController.h"

@interface ContactsController ()

@property CNContactStore *store;

@property NSMutableArray *_datasource;

@property NSMutableArray *_groups;

@property NSArray *_fullArray;

@property CNContactFetchRequest *request;

@end

@implementation ContactsController

-(instancetype)init {
    self = [super init];
    
    if (self) {
        self._datasource = [NSMutableArray array];
        self.store = [[CNContactStore alloc]init];
        
        //fetch list of groups
        self._groups = [NSMutableArray arrayWithArray:[self.store groupsMatchingPredicate:nil error:nil]];
        
        //fetch list of contacts
        if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized) {
            [self fetchWithCompletion:^(BOOL results, NSError *error) {
                
            }];
        }
    }
    return self;
}

-(NSArray<CNContact *>*)contacts {
    return [self._datasource copy];
}

-(NSArray<CNGroup *>*)groups {
    return [self._groups copy];
}


-(void)fetchWithCompletion:(void (^)(BOOL success, NSError *error))completion {
    [self._datasource removeAllObjects];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactIdentifierKey, CNContainerNameKey, [CNContactFormatter descriptorForRequiredKeysForStyle:CNContactFormatterStyleFullName]]];
        NSError *error;
        BOOL success = [self.store enumerateContactsWithFetchRequest:request error:&error usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            [self._datasource addObject:contact];
        }];
        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        self._fullArray = [NSArray arrayWithArray:self._datasource];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(YES, nil);
        });
        
    });
}

-(void)fetchContactsForGroups:(NSArray<CNGroup *> *)groups withCompletion:(void (^)(BOOL, NSError *))completion {
    if (!groups.count) {
        return [self fetchWithCompletion:completion];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self._datasource removeAllObjects];
        NSMutableArray *results = [NSMutableArray array];
        for (CNGroup *group in groups) {
            CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactIdentifierKey, CNContainerNameKey, [CNContactFormatter descriptorForRequiredKeysForStyle:CNContactFormatterStyleFullName]]];
            request.predicate = [CNContact predicateForContactsInGroupWithIdentifier:group.identifier];
            NSError *error;
            BOOL success = [self.store enumerateContactsWithFetchRequest:request error:&error usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
                BOOL okToAdd = YES;
                for (CNContact *g in results) {
                    if ([g.identifier isEqualToString:contact.identifier]) {
                        okToAdd = NO;
                    }
                }
                if (okToAdd) {
                     [results addObject:contact];
                }
            }];
            if (!success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, error);
                    return;
                });
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self._datasource = [NSMutableArray arrayWithArray:results];
            completion(YES, nil);
        });
        
    });
}

-(void)requestPermissionsWithCompletion:(void (^)(BOOL, NSError *))completion {
    [self.store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        completion(granted, error);
    }];
}

-(void)searchForText:(NSString *)name withCompletion:(void (^)(BOOL results, NSError *error))completion {
    if (name.length == 0) {
        self._datasource = [NSMutableArray arrayWithArray:self._fullArray];
        completion(YES, nil);
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self._datasource removeAllObjects];
        self.request = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactIdentifierKey, CNContainerNameKey, [CNContactFormatter descriptorForRequiredKeysForStyle:CNContactFormatterStyleFullName]]];
        NSPredicate *pred = [CNContact predicateForContactsMatchingName:name];
        self.request.predicate = pred;
        NSError *error;
        BOOL success = [self.store enumerateContactsWithFetchRequest:self.request error:&error usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            [self._datasource addObject:contact];
        }];
        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(YES, nil);
        });
    });
}

-(void)deleteContact:(CNContact *)contact withCompletion:(void (^)(BOOL, NSError *))completion {
    [self._datasource removeObject:contact];
    CNSaveRequest *saveRequest = [[CNSaveRequest alloc] init];
    NSError *error;
    CNMutableContact *finalContact = [self.store unifiedContactWithIdentifier:contact.identifier keysToFetch:@[] error:&error].mutableCopy;
    [saveRequest deleteContact:finalContact];
    [self.store executeSaveRequest:saveRequest error:&error];
    if (error) {
        completion(NO, error);
    } else {
        completion(YES, nil);
    }
}

-(void)addGroupWithName:(NSString *)name {
    CNMutableGroup *group = [[CNMutableGroup alloc]init];
    group.name = name;
    CNSaveRequest *request = [CNSaveRequest new];
    [request addGroup:group toContainerWithIdentifier:self.store.defaultContainerIdentifier];
    [self.store executeSaveRequest:request error:nil];
    [self._groups addObject:group];
}

-(void)addContact:(CNContact *)contact toGroup:(CNGroup *)group {
    CNSaveRequest *request = [CNSaveRequest new];
    [request addMember:contact toGroup:group];
    [self.store executeSaveRequest:request error:nil];
}

-(void)removeContact:(CNContact *)contact fromGroup:(CNGroup *)group {
    CNSaveRequest *request = [CNSaveRequest new];
    [request removeMember:contact fromGroup:group];
    [self.store executeSaveRequest:request error:nil];
}

-(void)deleteGroup:(CNGroup *)group {
    CNSaveRequest *request = [CNSaveRequest new];
    [request deleteGroup:group.mutableCopy];
    [self._groups removeObject:group];
    [self.store executeSaveRequest:request error:nil];
}

-(NSArray *)groupsForContact:(CNContact *)contact {
    NSArray *groups = [NSArray arrayWithArray:[self.store groupsMatchingPredicate:nil error:nil]];
    NSMutableArray *results = [NSMutableArray array];
    for (CNGroup *group in groups) {
        NSMutableArray *contacts = [NSMutableArray array];
        CNContactFetchRequest *request = [[CNContactFetchRequest alloc]initWithKeysToFetch:@[CNContactIdentifierKey]];
        request.predicate = [CNContact predicateForContactsInGroupWithIdentifier:group.identifier];
        NSLog(@"%@", group.name);
        [self.store enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            [contacts addObject:contact];
        }];
        for (CNContact *con in contacts) {
            if ([con.identifier isEqualToString:contact.identifier]) {
                [results addObject:group];
            }
        }
    }
    return results;
}

@end
