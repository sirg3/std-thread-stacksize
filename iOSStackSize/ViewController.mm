//
//  ViewController.m
//  iOSStackSize
//
//  Created by Joseph Ranieri on 12/7/15.
//  Copyright (c) 2015 Joe Ranieri. All rights reserved.
//

#import "ViewController.h"
#import "EvilThread.hpp"

static void Dummy(std::unique_ptr<int> x)
{
	NSLog(@"%p: %i", x.get(), *x);
}

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

	std::unique_ptr<int> x(new int);
	*x = 1;

	std::thread th = evil::create_thread(0x4000 * 2, Dummy, std::move(x));
	th.join();
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
