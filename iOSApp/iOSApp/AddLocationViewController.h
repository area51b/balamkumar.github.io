//
//  AddLocationViewController.h
//  iOSApp
//
//  Created by Madhav Raj Maharjan on 12/7/14.
//  Copyright (c) 2014 NCS Pte Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AddLocationViewController;

@protocol AddLocationDelegate <NSObject>
- (void) addLocation:(AddLocationViewController *) location withDictionary:(NSDictionary *) userInfo;
@end

@interface AddLocationViewController : UITableViewController <UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) id <AddLocationDelegate> delegate;

@end
