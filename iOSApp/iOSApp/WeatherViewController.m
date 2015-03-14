//
//  WeatherViewController.m
//  iOSApp
//
//  Created by Madhav Raj Maharjan on 9/7/14.
//  Copyright (c) 2014 NCS Pte Ltd. All rights reserved.
//

#import "WeatherViewController.h"
#import "Global.h"
#import "MenuViewController.h"
#import "WoeidTableViewCell.h"
#import "ForecastTableViewCell.h"
#import "AddLocationViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <ApigeeiOSSDK/ApigeeJsonUtils.h>

static NSString *kSequeAddLocation = @"addLocationSegue";

@interface WeatherViewController ()

@property (strong, nonatomic) NSMutableArray *locationList;

@end

@implementation WeatherViewController

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
            //   type = weoid
            //   uuid
            //   woeid
            //   name
            //   placeType
            //   country
            //   timezone;
            NSString *weoid = [item objectForKey:@"woeid"];
            
            NSString *forecastURL = [NSString stringWithFormat:kForecastURL, weoid, @"c",kWoeidApiKey];
            ApigeeClientResponse *response = [dataClient apiRequest:forecastURL operation:@"GET" data:nil];
            
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    [Global alert:[err objectForKey:@"faultstring"] withTitle:@"Failed loading data" buttonTitle:@"Close"];
                });
                return;
            }
            
            NSDictionary *forecast = [[userInfo objectForKey:@"forecast"] copy];
            [item setObject:forecast forKey:@"forecast"];
            // forecast
            //   units (temperatour, distance, pressure, seed)
            //   wind (chill, direction, speed)
            //   atmosphere (nuumidity, visibility, pressure rising)
            //   astronomy (sunrise, sunset)
            //   condition (text, code, image, temp, date)
            //   forcast
            //     [](day, log, high, text, code)
            
            [self.locationList addObject:item];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSRange range = NSMakeRange(0, 1);
            NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];
            [self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationAutomatic];
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
           
            NSRange range = NSMakeRange(0, 1);
            NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];
            [self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationAutomatic];
            
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
                    
                    [dataClient connectEntities:@"users" connectorID:[user uuid] connectionType:@"likes" connecteeType:kWoeidEntity connecteeID:[item objectForKey:@"uuid"]];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    if (error)
                    {
                        NSString *errorText = [[[Global sharedGlobal] getLastResponse] response];
                        [Global alert:errorText withTitle:@"Failed to set Data" buttonTitle:@"Close"];
                    } else {
                        
                        [super setEditing:editing animated:animated];
                        [self.tableView setEditing:editing animated:animated];
                        [self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationNone];
                        
                        [self loadData];
                    }
                });
            });
        }
    }
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
    if (self.editing)
    {
        return [self.locationList count] +1;
    } else {
        return [self.locationList count];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.tableView isEditing])
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
        
    } else {
        ForecastTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellForecastIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        if (indexPath.row < [self.locationList count])
        {
            NSDictionary *item = self.locationList[indexPath.row];
            
            NSString *title = [item objectForKey:@"name"];
            NSString *description = [NSString stringWithFormat:@"%@ of %@",
                                     [item objectForKey:@"placeType"],
                                     [item objectForKey:@"country"]];
            
            NSDictionary *forecast = [item objectForKey:@"forecast"];
            NSDictionary *itemWind =[forecast objectForKey:@"wind"];
            NSDictionary *itemAtmosphere =[forecast objectForKey:@"atmosphere"];
            NSDictionary *itemAstronomy =[forecast objectForKey:@"astronomy"];
            NSDictionary *itemCondition =[forecast objectForKey:@"condition"];
            NSDictionary *itemForecast =[forecast objectForKey:@"forecast"];
            
            NSString *wind = [NSString stringWithFormat:@"%@ \u02DAC, %@ deg, %@ km/h",
                              [itemWind objectForKey:@"chill"],
                              [itemWind objectForKey:@"direction"],
                              [itemWind objectForKey:@"speed"]];
            NSString *atmosphere = [NSString stringWithFormat:@"%@ %%,visibility %@ km, %@ mb",
                                    [itemAtmosphere objectForKey:@"humidity"],
                                    [itemAtmosphere objectForKey:@"visibility"],
                                    [itemAtmosphere objectForKey:@"pressure"]];
            NSString *astronomy = [NSString stringWithFormat:@"sunrise %@, sunset %@",
                                   [itemAstronomy objectForKey:@"sunrise"],
                                   [itemAstronomy objectForKey:@"sunset"]];
            NSString *condition = [NSString stringWithFormat:@"%@ \u02DAC %@",
                                   [itemCondition objectForKey:@"temp"],
                                   [itemCondition objectForKey:@"text"]];
            NSMutableString *forecastText = [NSMutableString string];
            NSURL *imageURL = [NSURL URLWithString:[itemCondition objectForKey:@"image"]];
            
            for (NSDictionary *i in itemForecast)
            {
                NSString *txt = [NSString stringWithFormat:@"%@ %@/%@ %@\n",
                                 [i objectForKey:@"day"],
                                 [i objectForKey:@"low"],
                                 [i objectForKey:@"high"],
                                 [i objectForKey:@"text"]];
                [forecastText appendString:txt];
            }
            
            [cell.titleLabel setText:title];
            [cell.descriptionLabel setText:description];
            
            [cell.windLabel setText:wind];
            [cell.atmosphereLabel setText:atmosphere];
            [cell.astronomyLabel setText:astronomy];
            [cell.conditionLabel setText:condition];
            [cell.forecastLabel setText:forecastText];
            [cell.imageView setImageURL:imageURL];
        }
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.tableView isEditing])
    {
        static NSNumber *woeidHeight;
        if(!woeidHeight)
        {
            WoeidTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellWoeidIdentifier];
            woeidHeight = @(cell.bounds.size.height);
        }
        return [woeidHeight floatValue];
    } else {
        static NSNumber *forecastHeight;
        if(!forecastHeight)
        {
            ForecastTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellForecastIdentifier];
            forecastHeight = @(cell.bounds.size.height);
        }
        return [forecastHeight floatValue];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
 */
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
    if ([tableView isEditing])
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
