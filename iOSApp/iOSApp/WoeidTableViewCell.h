//
//  WoeidTableViewCell.h
//  iOSApp
//
//  Created by Madhav Raj Maharjan on 11/7/14.
//  Copyright (c) 2014 NCS Pte Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *kCellWoeidIdentifier = @"cellWoeid";

@interface WoeidTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *timezoneLabel;

@end
