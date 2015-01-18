//
//  DetailViewController.h
//  Trax
//
//  Created by alex on 1/17/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

