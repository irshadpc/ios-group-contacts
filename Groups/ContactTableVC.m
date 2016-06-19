//
//  ContactTableVC.m
//  Groups
//
//  Created by Michael Helvey on 6/18/16.
//  Copyright © 2016 Michael Helvey. All rights reserved.
//

#import "ContactTableVC.h"
#import "ContactsController.h"
#import "ContactsGroupsVC.h"
@import Contacts;
@import ContactsUI;

@interface ContactTableVC () <UISearchBarDelegate, CNContactViewControllerDelegate, ContactsGroupsDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property ContactsController *controller;

@property UITapGestureRecognizer *singleTap;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *manageButton;

@property NSArray *currentFilter;

@end

@implementation ContactTableVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.controller = [ContactsController new];
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] != CNAuthorizationStatusAuthorized) {
        [self.controller requestPermissionsWithCompletion:^(BOOL success, NSError *error) {
            if (success) {
                [self.controller fetchWithCompletion:^(BOOL results, NSError *error) {
                    if (!error) {
                        [self.tableView reloadData];
                    }
                }];
            }
        }];
        
    }
    
    self.searchBar.delegate = self;
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    [self.tableView addGestureRecognizer:lpgr];
}

#pragma mark Long Press

BOOL handlingPress;

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    if (indexPath == nil) {
        NSLog(@"long press on table view but not on a row");
    } else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (!handlingPress) {
            [self manageGroupForContactAtIndexPath:indexPath];
        }
    }
}

-(void)manageGroupForContactAtIndexPath:(NSIndexPath *)indexPath {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Manage Contact" message:@"To manage the groups this contact is in, select Manage Groups.  To remove this contact from your contacts, click Delete Contact." preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *add = [UIAlertAction actionWithTitle:@"Manage Groups" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //
        handlingPress = NO;
        UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"groupsNavVC"];
        ContactsGroupsVC *contact = [nav.viewControllers objectAtIndex:0];
        contact.contact = [self.controller.contacts objectAtIndex:indexPath.row];
        contact.delegate = self;
        CNContact *con = [self.controller.contacts objectAtIndex:indexPath.row];
        contact.currentFilter = [self.controller groupsForContact:con];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete Contact" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        //
        handlingPress = NO;
        CNContact *contact = [self.controller.contacts objectAtIndex:indexPath.row];
        CNContactFormatter *formatter = [[CNContactFormatter alloc] init];
        NSString *name = [formatter stringFromContact:contact];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Contact" message:[NSString stringWithFormat:@"Are you sure you want to delete %@ from your contacts?", name] preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *yes = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self.controller deleteContact:contact withCompletion:^(BOOL results, NSError *error) {
                if (!error) {
                    [self.tableView reloadData]; // tell table to refresh now
                } else {
                    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"We're sorry, but the delete request failed."] preferredStyle:UIAlertControllerStyleActionSheet];
                    [self presentViewController:errorAlert animated:YES completion:nil];
                }
            }];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            //
        }];
        [alert addAction:yes];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //
        handlingPress = NO;
    }];
    [alert addAction:add];
    [alert addAction:delete];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark IBOutlet

- (IBAction)addContact:(id)sender {
    CNContactStore *store = [CNContactStore new];
    CNContactViewController *view = [CNContactViewController viewControllerForNewContact:nil];
    view.contactStore = store;
    view.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:view];
    [self presentViewController:nav animated:YES completion:nil];
}

- (IBAction)editTable:(id)sender {
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"groupsNavVC"];
    ContactsGroupsVC *groups = [nav.viewControllers objectAtIndex:0];
    groups.delegate = self;
    groups.currentFilter = self.currentFilter;
    [self presentViewController:nav animated:YES completion:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.controller.contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
    
    CNContact *contact = [self.controller.contacts objectAtIndex:indexPath.row];
    
    CNContactFormatter *formatter = [[CNContactFormatter alloc] init];
    NSString *name = [formatter stringFromContact:contact];
    cell.textLabel.text = name;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CNContact *contact = [self.controller.contacts objectAtIndex:indexPath.row];
    CNContactStore *store = [CNContactStore new];
    NSError *error;
    CNContact *finalContact = [store unifiedContactWithIdentifier:contact.identifier keysToFetch:@[[CNContactViewController descriptorForRequiredKeys]] error:&error];
    CNContactViewController *view = [CNContactViewController viewControllerForContact:finalContact];
    view.contactStore = store;
    view.delegate = self;
    [self.navigationController pushViewController:view animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //remove the deleted object from your data source.
        //If your data source is an NSMutableArray, do this
        
        CNContact *contact = [self.controller.contacts objectAtIndex:indexPath.row];
        CNContactFormatter *formatter = [[CNContactFormatter alloc] init];
        NSString *name = [formatter stringFromContact:contact];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Contact" message:[NSString stringWithFormat:@"Are you sure you want to delete %@ from your contacts?", name] preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *yes = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self.controller deleteContact:contact withCompletion:^(BOOL results, NSError *error) {
                if (!error) {
                    [tableView reloadData]; // tell table to refresh now
                } else {
                    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"We're sorry, but the delete request failed."] preferredStyle:UIAlertControllerStyleActionSheet];
                    [self presentViewController:errorAlert animated:YES completion:nil];
                }
            }];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            //
        }];
        [alert addAction:yes];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark Utils

- (UIImage *)imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 100, 100);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark UISearchBarDelegate

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doSingleTap)];
    [self.tableView addGestureRecognizer:self.singleTap];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.controller searchForText:searchText withCompletion:^(BOOL results, NSError *error) {
        if (results) {
            [self.tableView reloadData];
        }
    }];
}

-(void)doSingleTap {
    [self.searchBar resignFirstResponder];
    [self.tableView removeGestureRecognizer:self.singleTap];
    [self.controller searchForText:@"" withCompletion:^(BOOL results, NSError *error) {
        if (!error) {
            [self.tableView reloadData];
        }
    }];
}

#pragma mark ContactViewController Delegate

-(void)contactViewController:(CNContactViewController *)viewController didCompleteWithContact:(CNContact *)contact {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [self.controller fetchWithCompletion:^(BOOL results, NSError *error) {
            if (!error) {
                [self.tableView reloadData];
            }
        }];
    }];
    [self.navigationController popToRootViewControllerAnimated: YES];
}

#pragma mark Contacts Groups Delegate

-(void)contactsGroupSelector:(ContactsGroupsVC *)vc finishedWithGroups:(NSArray<CNGroup *> *)groups {
    if (!vc.contact) {
        [self.controller fetchContactsForGroups:groups withCompletion:^(BOOL results, NSError *error) {
            if (!error) {
                if (groups.count) {
                    self.navigationItem.title = @"Filtered Contacts";
                } else {
                    self.navigationItem.title = @"All Contacts";
                }
                
                self.currentFilter = [NSArray arrayWithArray:groups];
                [self.tableView reloadData];
            } else {
                NSLog(@"%@", error);
            }
        }];
    }
}

@end
