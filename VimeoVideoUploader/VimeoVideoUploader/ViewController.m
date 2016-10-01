//
//  ViewController.m
//  VimeoVideoUploader
//
//  Created by Mohd Haider on 30/09/16.
//  Copyright © 2016 InstantSystemsInc. All rights reserved.
//

#import "ViewController.h"
#import "VimeoVideoUploader-Swift.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)btnPressed:(id)sender
{
    FirstViewController  *controller = [[FirstViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
