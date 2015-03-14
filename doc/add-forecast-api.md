### POC using Apigee ###

### Calling Weather API: weather-forcase ###

**Searching Weather Forecast - http://[organization]-[site].apigee.net/weather/v1/forecast?w=12589352&u=c&apikey=[API-KEY]**



### Details ###


**Install AsyncImageView using CocoaPods**

Update content of [Podfile](iOSApp/Podfile) as shown below

```
...
target "iOSApp" do
pod 'ApigeeiOSSDK', '~> 2.0'
pod 'MBProgressHUD', '~> 0.8'
pod 'AsyncImageView', '~> 1.5'
end
...
```

Install Dependencies

```
pod install
```

**Update WeatherViewController**

Update [WeatherViewController](iOSApp/iOSApp/WeatherViewController.m) Implementation

```
...
#import "ForecastTableViewCell.h"
...
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
...

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
...

```
