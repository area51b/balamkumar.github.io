//
//  ForecastTableViewCell.h
//  iOSApp
//
//  Created by Madhav Raj Maharjan on 11/7/14.
//  Copyright (c) 2014 NCS Pte Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AsyncImageView/AsyncImageView.h>

static NSString *kCellForecastIdentifier = @"cellForecast";

@interface ForecastTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UILabel *windLabel;
@property (weak, nonatomic) IBOutlet UILabel *atmosphereLabel;
@property (weak, nonatomic) IBOutlet UILabel *astronomyLabel;
@property (weak, nonatomic) IBOutlet UILabel *conditionLabel;
@property (weak, nonatomic) IBOutlet UILabel *forecastLabel;
@property (weak, nonatomic) IBOutlet AsyncImageView *imageView;

@end
