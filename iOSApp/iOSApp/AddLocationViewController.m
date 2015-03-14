//
//  AddLocationViewController.m
//  iOSApp
//
//  Created by Madhav Raj Maharjan on 12/7/14.
//  Copyright (c) 2014 NCS Pte Ltd. All rights reserved.
//

#import "AddLocationViewController.h"
#import "Global.h"
#import "WoeidTableViewCell.h"
#import <ApigeeiOSSDK/ApigeeJsonUtils.h>
#import <MBProgressHUD/MBProgressHUD.h>


@interface AddLocationViewController ()

@property (strong, nonatomic) NSArray *searchResult;

@end

@implementation AddLocationViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.searchResult count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WoeidTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellWoeidIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary *item = self.searchResult[indexPath.row];
    
    NSString *title = [item objectForKey:@"name"];
    NSString *description = [NSString stringWithFormat:@"%@ of %@", [item objectForKey:@"placeType"],[item objectForKey:@"country"]];
    NSString *timezone = [item objectForKey:@"timezone"];
    
    [cell.titleLabel setText:title];
    [cell.descriptionLabel setText:description];
    [cell.timezoneLabel setText:timezone];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSNumber *height;
    if(!height)
    {
        WoeidTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellWoeidIdentifier];
        height = @(cell.bounds.size.height);
    }
    return [height floatValue];
}


#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = self.searchResult[indexPath.row];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(addLocation:withDictionary:)])
    {
        [self.delegate addLocation:self withDictionary:item];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma  mark - SearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"User searched for %@", searchBar.text);
    [searchBar resignFirstResponder];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        // search
        ApigeeDataClient *dataClient = [[Global sharedGlobal] dataClient];
        NSString *search = [searchBar.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *woeidURL = [NSString stringWithFormat:kWoeidURL, search, kWoeidApiKey];
        ApigeeClientResponse *response = [dataClient apiRequest:woeidURL operation:@"GET" data:nil];
        
        if (!response.completedSuccessfully)
        {
            [Global alert:[response response] withTitle:@"Search Failed" buttonTitle:@"Close"];
            return;
        }
        
        NSError *error;
        NSDictionary *userInfo = [ApigeeJsonUtils decode:[response rawResponse] error:&error];
        
        NSDictionary *err = [userInfo objectForKey:@"fault"];
        if (err)
        {
            [Global alert:[err objectForKey:@"faultstring"] withTitle:@"Search Failed" buttonTitle:@"Close"];
            return;
        }
        
        self.searchResult = [[userInfo objectForKey:@"places"] copy];
        [self.tableView reloadData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    });
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"User canceled search for %@", searchBar.text);
    [searchBar resignFirstResponder];
    
    self.searchResult = @[];
    [self.tableView reloadData];
}

@end
