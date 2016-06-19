//
//  ContactsGroupsVC.m
//  Groups
//
//  Created by Michael Helvey on 6/18/16.
//  Copyright © 2016 Michael Helvey. All rights reserved.
//

#import "ContactsGroupsVC.h"
#import "ContactsController.h"
@import Contacts;

@interface ContactsGroupsVC ()

@property ContactsController *controller;

@property NSMutableArray *selectedGroups;

@end

@implementation ContactsGroupsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.selectedGroups = [NSMutableArray array];
    for (CNGroup *group in self.currentFilter) {
        [self.selectedGroups addObject:group];
    }
    
    self.controller = [ContactsController new];
    if (!self.contact) {
        self.navigationItem.title = @"Filter By Groups";
        self.navigationItem.leftBarButtonItem = nil;
    } else {
        self.navigationItem.title = @"Manage Groups";
        CNContactFormatter *formatter = [[CNContactFormatter alloc] init];
        NSString *name = [formatter stringFromContact:self.contact];
        self.navigationItem.prompt = [NSString stringWithFormat:@"You are managing groups for %@.", name];
        self.tableView.allowsMultipleSelectionDuringEditing = NO;
    }
}
- (IBAction)doneButton:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.delegate contactsGroupSelector:self finishedWithGroups:self.selectedGroups];
}
- (IBAction)addGroup:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add A Group" message:@"What is the name of the new group?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Group";
    }];
    UIAlertAction *add = [UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //add group
        [self.controller addGroupWithName:alert.textFields[0].text];
        [self.tableView reloadData];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:add];
    [alert addAction: cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.contact) {
        return 1;
    } else {
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && !self.contact) {
        return 1;
    }
    return self.controller.groups.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0 && !self.contact) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupsCell" forIndexPath:indexPath];
        cell.textLabel.textColor = self.view.tintColor;
        if (self.selectedGroups.count == self.controller.groups.count) {
            cell.textLabel.text = @"Deselect All Groups";
        } else {
            cell.textLabel.text = @"Select All Groups";
        }
        return cell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupsCell" forIndexPath:indexPath];
    
    CNGroup *group = [self.controller.groups objectAtIndex:indexPath.row];
    
    cell.textLabel.text = group.name;
    
    BOOL containsGroup = NO;
    
    for (CNGroup *gr in self.selectedGroups) {
        if ([gr.identifier isEqualToString:group.identifier]) {
            containsGroup = YES;
        }
    }
    
    if (containsGroup) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if (self.contact) {
                return @"Groups";
            } else {
                return @"";
            }
            break;
        case 1:
            return @"Groups";
            break;
        default:
            return @"";
            break;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && !self.contact) {
        //we have a button
        if (self.selectedGroups.count == self.controller.groups.count) {
            [self.selectedGroups removeAllObjects];
            [self.tableView reloadData];
        } else {
            [self.selectedGroups removeAllObjects];
            [self.selectedGroups addObjectsFromArray:self.controller.groups];
            [self.tableView reloadData];
        }
    } else {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        CNGroup *group = [self.controller.groups objectAtIndex:indexPath.row];
        
        BOOL containsGroup = NO;
        
        for (CNGroup *gr in self.selectedGroups) {
            if ([gr.identifier isEqualToString:group.identifier]) {
                containsGroup = YES;
            }
        }
        
        if (containsGroup) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            [self.selectedGroups removeObject:group];
            if (self.contact) {
                [self.controller removeContact:self.contact fromGroup:group];
            }
        } else {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [self.selectedGroups addObject:group];
            if (self.contact) {
                [self.controller addContact:self.contact toGroup:group];
            }
        }
        [self.tableView reloadData];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// Override to support conditional editing of the table view.
// This only needs to be implemented if you are going to be returning NO
// for some items. By default, all items are editable.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    if (self.contact) {
         return YES;
    } else {
        return NO;
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    CNGroup *group = [self.controller.groups objectAtIndex:indexPath.row];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete" message:[NSString stringWithFormat:@"Are you sure you want to delete the group '%@'?  This will not delete the contacts in the group.  You cannot undo this action.", group.name] preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *yes = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self.controller deleteGroup:group];
            [self.tableView reloadData];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            //
        }];
        [alert addAction:yes];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
