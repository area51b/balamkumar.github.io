### POC using Apigee ###

### Calling Weather API: woeid-search ###

**Searching Woeid Code - http://[organization]-[site].apigee.net/woeid/v1/search?q=[LOCATION]&apikey=[API-KEY]**

```
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

```

**Storing User selected location on Backend**

```
		ApigeeDataClient *dataClient = [[Global sharedGlobal] dataClient];
                ApigeeUser *user = [dataClient getLoggedInUser];
                BOOL error = false;
                ApigeeClientResponse *response;

                for (NSMutableDictionary *item in self.locationList)
                {
                    NSString *uuid = [item objectForKey:@"uuid"];
                    if(!([uuid length] > 0))
                    {
                        [item setValue:kWoeidEntity forKey:@"type"]; // 'type' required
                        response = [[Global sharedGlobal] createEntity:item];

                        if (!response.completedSuccessfully)
                        {
                            error = true;
                            //errorText = [response response];
                            break;
                        }
                        ApigeeEntity *entity = [response entities][0];
                        [item setValue:[entity getStringProperty:@"uuid"] forKey:@"uuid"];
                    } 

                    [dataClient connectEntities:@"users" connectorID:[user username] connectionType:@"likes" connecteeType:kWoeidEntity connecteeID:[item objectForKey:@"uuid"]];
                }
```

**Retrieving User selected location from Backend**

```
		ApigeeDataClient *dataClient = [[Global sharedGlobal] dataClient];
        ApigeeUser *user = [dataClient getLoggedInUser];
        ApigeeQuery *query = [[ApigeeQuery alloc] init];

        ApigeeClientResponse *response = [dataClient getEntityConnections:@"users" connectorID:[user username] connectionType:@"likes" query:query];
        if (!response.completedSuccessfully)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [Global alert:[response response] withTitle:@"Failed to get Data" buttonTitle:@"Close"];
            });
        }

        NSArray *entities = [response entities];
        self.locationList = [NSMutableArray arrayWithCapacity:[entities count]];
        for (ApigeeEntity *entity in [response entities])
        {
            NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[entity properties]];
            [self.locationList addObject:item];
        }
```
### Details ###


**Install MBProgressHUD using CocoaPods**

Update content of [Podfile](iOSApp/Podfile) as shown below

```
...
target "iOSApp" do
pod 'ApigeeiOSSDK', '~> 2.0'
pod 'MBProgressHUD', '~> 0.8'
end
...
```

Install Dependencies

```
pod install
```


**Create WeatherViewController**

Create [WeatherViewController](iOSApp/iOSApp/WeatherViewController.h) Definition

```
#import <UIKit/UIKit.h>
#import "AddLocationViewController.h"

@interface WeatherViewController : UITableViewController <AddLocationDelegate>
@end
```

Create [WeatherViewController](iOSApp/iOSApp/WeatherViewController.m) Implementation

```
#import "WeatherViewController.h"
#import "Global.h"
#import "MenuViewController.h"
#import "WoeidTableViewCell.h"
#import "AddLocationViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

static NSString *kSequeAddLocation = @"addLocationSegue";

@interface WeatherViewController ()

@property (strong, nonatomic) NSMutableArray *locationList;

@end

@implementation WeatherViewController

...

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self loadData];
}

- (void) loadData
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        ApigeeDataClient *dataClient = [[Global sharedGlobal] dataClient];
        ApigeeUser *user = [dataClient getLoggedInUser];
        ApigeeQuery *query = [[ApigeeQuery alloc] init];
        
        ApigeeClientResponse *response = [dataClient getEntityConnections:@"users" connectorID:[user username] connectionType:@"likes" query:query];
        if (!response.completedSuccessfully)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [Global alert:[response response] withTitle:@"Failed to get Data" buttonTitle:@"Close"];
            });
        }
        
        NSArray *entities = [response entities];
        self.locationList = [NSMutableArray arrayWithCapacity:[entities count]];
        for (ApigeeEntity *entity in [response entities])
        {
            NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[entity properties]];
            [self.locationList addObject:item];
        }
        
        [self.tableView reloadData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    });
}


-(void)setEditing:(BOOL)editing animated:(BOOL) animated {
    
    if(editing != self.editing ) {
        
        NSArray *indexes = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.locationList count] inSection:0]];
        if (editing == YES ) {
            
            [super setEditing:editing animated:animated];
            [self.tableView setEditing:editing animated:animated];
            [self.tableView insertRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationLeft];
            
        } else {

            //__block NSString *errorText = @"";
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                
                ApigeeDataClient *dataClient = [[Global sharedGlobal] dataClient];
                ApigeeUser *user = [dataClient getLoggedInUser];
                BOOL error = false;
                ApigeeClientResponse *response;

                for (NSMutableDictionary *item in self.locationList)
                {
                    NSString *uuid = [item objectForKey:@"uuid"];
                    if(!([uuid length] > 0))
                    {
                        [item setValue:kWoeidEntity forKey:@"type"]; // 'type' required
                        response = [[Global sharedGlobal] createEntity:item];
                        
                        if (!response.completedSuccessfully)
                        {
                            error = true;
                            //errorText = [response response];
                            break;
                        }
                        ApigeeEntity *entity = [response entities][0];
                        [item setValue:[entity getStringProperty:@"uuid"] forKey:@"uuid"];
                    } 
                    
                    [dataClient connectEntities:@"users" connectorID:[user username] connectionType:@"likes" connecteeType:kWoeidEntity connecteeID:[item objectForKey:@"uuid"]];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error)
                    {
                        NSString *errorText = [[[Global sharedGlobal] getLastResponse] response];
                        [Global alert:errorText withTitle:@"Failed to set Data" buttonTitle:@"Close"];
                    } else {
                        [super setEditing:editing animated:animated];
                        [self.tableView setEditing:editing animated:animated];
                        [self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationLeft];
                    }
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
            });
        }
    }
}

...

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.editing)
    {
        return [self.locationList count] +1;
    } else {
        return [self.locationList count];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        WoeidTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellWoeidIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        if (indexPath.row < [self.locationList count])
        {
            NSDictionary *item = self.locationList[indexPath.row];
            
            NSString *title = [item objectForKey:@"name"];
            NSString *description = [NSString stringWithFormat:@"%@ of %@", [item objectForKey:@"placeType"],[item objectForKey:@"country"]];
            NSString *timezone = [item objectForKey:@"timezone"];
            
            [cell.titleLabel setText:title];
            [cell.descriptionLabel setText:description];
            [cell.timezoneLabel setText:timezone];
            cell.editingAccessoryType = UITableViewCellAccessoryNone;
        } else {
            [cell.titleLabel setText:@"New Location"];
            [cell.descriptionLabel setText:@""];
            [cell.timezoneLabel setText:@""];
            cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSNumber *woeidHeight;
    if(!woeidHeight)
    {
        WoeidTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellWoeidIdentifier];
        woeidHeight = @(cell.bounds.size.height);
    }
    return [woeidHeight floatValue];
}

...

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (indexPath.row < [self.locationList count])
   {
       return UITableViewCellEditingStyleDelete;
   } else {
       return UITableViewCellEditingStyleInsert;
   }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSMutableDictionary *item = [self.locationList objectAtIndex:indexPath.row];
        
        
        ApigeeDataClient *dataClient = [[Global sharedGlobal] dataClient];
        ApigeeUser *user = [dataClient getLoggedInUser];

        [dataClient disconnectEntities:@"users" connectorID:[user uuid] type:@"likes" connecteeID:[item objectForKey:@"uuid"]];
        
        [self.locationList removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing)
    {
        if (indexPath.row == self.locationList.count)
        {
            [self performSegueWithIdentifier:kSequeAddLocation sender: self];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:kSequeAddLocation])
    {
        AddLocationViewController *addLocationViewController = segue.destinationViewController;
        addLocationViewController.delegate = self;
    }
}

#pragma mark - AddLocation delegate

- (void) addLocation:(AddLocationViewController *)location withDictionary:(NSDictionary *)userInfo
{
    [self.locationList addObject:userInfo];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([self.locationList count] - 1) inSection:0];
    
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
@end

```

**Create AddLocationViewController**

Create [AddLocationViewController](iOSApp/iOSApp/AddLocationViewController.h) Definition

```
#import <UIKit/UIKit.h>

@class AddLocationViewController;

@protocol AddLocationDelegate <NSObject>
- (void) addLocation:(AddLocationViewController *) location withDictionary:(NSDictionary *) userInfo;
@end

@interface AddLocationViewController : UITableViewController <UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) id <AddLocationDelegate> delegate;

@end
```

Create [AddLocationViewController](iOSApp/iOSApp/AddLocationViewController.m) Implementation

```
#import "AddLocationViewController.h"
#import "Global.h"
#import "WoeidTableViewCell.h"
#import <ApigeeiOSSDK/ApigeeJsonUtils.h>
#import <MBProgressHUD/MBProgressHUD.h>


@interface AddLocationViewController ()

@property (strong, nonatomic) NSArray *searchResult;

@end

@implementation AddLocationViewController

...

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

```



