//
//  SFViewController.m
//  PopAnimation
//
//  Created by Iman Zarrabian on 19/07/14.
//  Copyright (c) 2014 Iman Zarrabian. All rights reserved.
//

#import "SFViewController.h"

@interface SFViewController ()

//Views
@property (nonatomic, weak) IBOutlet UIImageView *bgImageView;
@property (nonatomic, weak) IBOutlet UIView *interactionView;
@property (nonatomic, weak) IBOutlet UIButton *facebookButton;
@property (nonatomic, weak) IBOutlet UIButton *signupButton;

//Misc
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UISnapBehavior *snapBehaviour;
@end

@implementation SFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initPanGestureAndDynamics];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self toggleTriangleMask];
        [self kickInitialAnimations];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Configuration methods
- (void)initPanGestureAndDynamics {
    //Adding Pan GEsture recognizer
    UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.interactionView addGestureRecognizer:gestureRecognizer];
    
    //Creating the animator and the Snap Behaviour
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.snapBehaviour = [[UISnapBehavior alloc] initWithItem:self.interactionView snapToPoint:CGPointMake(self.view.bounds.size.width/2.0,self.view.bounds.size.height - self.interactionView.bounds.size.height/2.0)];
    self.snapBehaviour.damping = .7;
}


- (void)toggleTriangleMask {
    if (self.interactionView.layer.mask) {
        self.interactionView.layer.mask = nil;
    }
    else {
        CAShapeLayer *mask = [[CAShapeLayer alloc] init];
        mask.frame = self.interactionView.layer.bounds;
        
        CGFloat width = self.interactionView.layer.frame.size.width;
        CGFloat height = self.interactionView.layer.frame.size.height;
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, nil, 0, height);
        CGPathAddLineToPoint(path, nil, width, height);
        CGPathAddLineToPoint(path, nil, width, 0);
        CGPathAddLineToPoint(path, nil, width/2 + 7, 0);
        CGPathAddLineToPoint(path, nil, width/2,  7);
        CGPathAddLineToPoint(path, nil, (width/2) - 7, 0);
        CGPathAddLineToPoint(path, nil, 0, 0);

        CGPathCloseSubpath(path);
        
        mask.path = path;
        CGPathRelease(path);
        self.interactionView.layer.mask = mask;
    }
}

#pragma mark - Animation methods

- (void)kickInitialAnimations {
    //Create animations
    POPSpringAnimation *imageViewBoundsAnimation = [POPSpringAnimation animation];
    POPSpringAnimation *imageViewPositionAnimation = [POPSpringAnimation animation];

    POPSpringAnimation *interactionViewBottomAnimation = [POPSpringAnimation animation];


    //Set the animatable properties
    imageViewBoundsAnimation.property = [POPAnimatableProperty propertyWithName:kPOPLayerBounds];
    imageViewPositionAnimation.property = [POPAnimatableProperty propertyWithName:kPOPLayerPositionY];
    interactionViewBottomAnimation.property = [POPAnimatableProperty propertyWithName:kPOPLayerPositionY];

    
    //set the destination values
    imageViewBoundsAnimation.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    imageViewPositionAnimation.toValue = @(self.view.center.y);
    interactionViewBottomAnimation.toValue = @(self.view.bounds.size.height - self.interactionView.bounds.size.height/2.0);


    //set the animaions configurations values
    imageViewBoundsAnimation.springBounciness = 2;
    imageViewBoundsAnimation.springSpeed = 15;
    interactionViewBottomAnimation.springBounciness = 3;
    interactionViewBottomAnimation.springSpeed = 12;
    imageViewPositionAnimation.springBounciness = 3;
    imageViewPositionAnimation.springSpeed = 12;

    
    //Finally set the animation
    [self.bgImageView pop_addAnimation:imageViewBoundsAnimation forKey:@"bounds"];
    [self.bgImageView pop_addAnimation:imageViewPositionAnimation forKey:@"position"];
    [self.interactionView pop_addAnimation:interactionViewBottomAnimation forKey:@"interactionViewAnimation"];
}

- (void)animateBackToTheRightTopImageSize {
    POPSpringAnimation *sizeAnimation = [POPSpringAnimation animation];
    sizeAnimation.property = [POPAnimatableProperty propertyWithName:kPOPLayerBounds];
    sizeAnimation.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    sizeAnimation.springBounciness = 4;
    sizeAnimation.springSpeed = 20;
    [self.bgImageView pop_addAnimation:sizeAnimation forKey:@"sizeBack"];
}

#pragma mark - Logic methods
- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        // Let's avoid any interference here
       // [self.bgImageView pop_removeAllAnimations];
        [self.animator removeAllBehaviors];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        
        CGPoint newCenter = self.interactionView.center;
        newCenter.y += [gestureRecognizer translationInView:self.view].y/2.5;
        
        //Zooming in or out on the top imageview
        //You can set some max zooming in or out here to avoid too much scaling
        self.bgImageView.bounds = CGRectMake(0, 0, self.bgImageView.bounds.size.width* (newCenter.y/self.interactionView.center.y), self.bgImageView.bounds.size.height* (newCenter.y/self.interactionView.center.y));
        
        //Actually moving the view
        self.interactionView.center = newCenter;
        [gestureRecognizer setTranslation:CGPointZero inView:self.view];
        
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.animator addBehavior:self.snapBehaviour];
        
        UIDynamicItemBehavior *itemBehaviour = [[UIDynamicItemBehavior alloc] initWithItems:@[self.interactionView]];
        itemBehaviour.allowsRotation = NO;
        [self.animator addBehavior:itemBehaviour];
       
        //This will simply set the image view animate back to it's original size
        [self animateBackToTheRightTopImageSize];
    }
}


@end
