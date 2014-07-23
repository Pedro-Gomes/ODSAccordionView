//
//  ODSSectionView.m
//  ODSAccordionView
//
//  Created by Johannes Seitz on 17/06/14.
//  Copyright (c) 2014 Johannes W. Seitz. All rights reserved.
//

#import "ODSAccordionSectionView.h"
#import "ODSAccordionSectionStyle.h"
#import "ODSArrowIcon.h"


#define BOUNDS_KEY_PATH NSStringFromSelector(@selector(bounds))
#define MARGIN 8

@interface ODSAccordionSectionView ()

@property (nonatomic, copy) void (^actionBlock)(id sender);
@property (nonatomic, strong) UIButton* actionButton;

@end

@implementation ODSAccordionSectionView {
    ODSAccordionSectionStyle *_sectionStyle;
    CGFloat _sectionViewAlpha;
    ODSArrowIcon *_arrowIcon;
}

-(void)shouldPresentButton:(BOOL)presentButton
                  withIcon:(UIImage *)image
                     title:(NSString*)title
                    action:(void (^)(id sender))block {
    if(presentButton){
        if(!self.actionButton){
            self.actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
        }
        
        if (image) {
            [self.actionButton setImage:[UIImage imageNamed:@"icon-reset-arrow"] forState:UIControlStateNormal];
            [self.actionButton.imageView setContentMode:UIViewContentModeCenter];
        }
        [self.actionButton addTarget:self action:@selector(actionButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        
        [self setActionBlock:block];
        [self.actionButton setBackgroundColor:_sectionStyle.buttonColor];
        if (![self.actionButton isDescendantOfView:self]){
            [self addSubview:self.actionButton];
        }
    } else {
        [self.actionButton removeFromSuperview];
        self.actionButton = nil;
    }
}

-(IBAction)actionButtonPress:(id)sender {
    if(self.actionBlock != nil) {
        self.actionBlock(self.actionButton);
    }
}




-(instancetype)initWithTitle:(NSString *)sectionTitle
                     andView:(UIView *)sectionView
                sectionStyle:(ODSAccordionSectionStyle *)sectionStyle {
    self = [super init];
    if (self) {
        _sectionStyle = sectionStyle;
        _sectionView = sectionView;
        self.backgroundColor = _sectionStyle.backgroundColor;
        [self setClipsToBounds:YES];
        
        [self makeHeader:sectionTitle];
        [self addArrowIcon];
        
        [self addSubview: sectionView];
        [sectionView addObserver:self forKeyPath:BOUNDS_KEY_PATH options:0 context:nil];
        
        [self layoutIfNeeded];
        [self collapseSectionAnimated:NO];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:BOUNDS_KEY_PATH] && self.expanded){
        self.height = [self expandedHeight];
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

-(void)makeHeader:(NSString *)sectionTitle {
    _header = [UIButton buttonWithType:UIButtonTypeCustom];
    [_header setTitle:sectionTitle forState:UIControlStateNormal];
    [_header setTitleColor:_sectionStyle.headerTitleLabelTextColor forState:UIControlStateNormal];
    _header.backgroundColor = _sectionStyle.headerBackgroundColor;
    _header.titleLabel.font = _sectionStyle.headerTitleLabelFont;
    [_header addTarget:self action:@selector(toggleButtonPressed:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:_header];
}

-(void)addArrowIcon {
    _arrowIcon = [[ODSArrowIcon alloc] initWithFrame:CGRectMake(0, 0, 30, 5)];
    [_arrowIcon setHidden:!_sectionStyle.arrowVisible];
    _arrowIcon.color = _sectionStyle.arrowColor;
    [self.header addSubview:_arrowIcon];
}

-(void)collapseSectionAnimated:(BOOL)animated {
    _expanded = NO;
    self.height = self.collapsedHeight;
    _sectionViewAlpha = 0.0;
    [self sectionViewAlphaChanged:animated];
    [_arrowIcon pointDownAnimated:animated];
}

-(void)expandSectionAnimated:(BOOL)animated {
    _expanded = YES;
    self.height = self.expandedHeight;
    _sectionViewAlpha = 1.0;
    [self sectionViewAlphaChanged:animated];
    [_arrowIcon pointUpAnimated:animated];
}

-(void)statusChanged:(BOOL)status {
    [self.delegate accordionSection:self
                    didChangeStatus:status
                       headerHeight:self.headerHeight
                         bodyHeight:[self expandedHeight] - self.headerHeight];
}

-(void)sectionViewAlphaChanged:(BOOL)animated {
    if (animated){
        [UIView animateWithDuration:0.5 animations:^{ _sectionView.alpha = _sectionViewAlpha; }];
    } else {
        _sectionView.alpha = _sectionViewAlpha;
    }
}

-(void)toggleButtonPressed:(id)sectionPressed {
    if (_expanded){
        [self collapseSectionAnimated:YES];
        [self statusChanged:NO];
    } else {
        [self expandSectionAnimated:YES];
        [self statusChanged:YES];
    }
    [self setNeedsLayout];
}

-(CGFloat)headerHeight {
    return _sectionStyle.headerHeight;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    [self layoutHeader];
    [self layoutSection];
}

-(void)layoutHeader {
    _header.frame = CGRectMake(_header.frame.origin.x, _header.frame.origin.y, self.width, self.headerHeight);
    CGSize arrowSize = _arrowIcon.frame.size;
    if (_sectionStyle.headerStyle == ODSAccordionHeaderStyleLabelLeft){
        [_header setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [_header setTitleEdgeInsets:UIEdgeInsetsMake(0, MARGIN, 0, 0)];
        _arrowIcon.frame = CGRectMake(self.width - MARGIN - arrowSize.width, self.headerHeight / 2 - arrowSize.height / 2 ,
                                      arrowSize.width, arrowSize.height);
    } else if (_sectionStyle.headerStyle == ODSAccordionHeaderStyleLabelRight){
        [_header setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [_header setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, MARGIN)];
        _arrowIcon.frame = CGRectMake(MARGIN, self.headerHeight / 2 - arrowSize.height / 2,
                                      arrowSize.width, arrowSize.height);
    } else if (_sectionStyle.headerStyle == ODSAccordionHeaderStyleLabelCentered) {
        [_header setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [_header setTitleEdgeInsets:UIEdgeInsetsZero];
        _arrowIcon.frame = CGRectMake(_header.center.x - (_arrowIcon.frame.size.width / 2),
                                      _header.frame.size.height - _arrowIcon.frame.size.height - MARGIN,
                                      _arrowIcon.frame.size.width, _arrowIcon.frame.size.height);
    }
    
    if (self.actionButton != nil) {
        CGRect frame = CGRectMake(_header.frame.origin.x + self.width - _sectionStyle.buttonWidth, _header.frame.origin.y, _sectionStyle.buttonWidth, self.headerHeight);
        
        if(self.actionButton.frame.origin.x != 0){
            [UIView animateWithDuration:_sectionStyle.animationDuration
                             animations:^{
                                 self.actionButton.frame = frame;
                             }];
        } else {
            self.actionButton.frame = frame;
        }
    }
}

-(void)dealloc {
    @try {
        [_sectionView removeObserver:self forKeyPath:BOUNDS_KEY_PATH];
    }
    @catch (NSException * __unused exception) {}
}

-(void)layoutSection {
    CGSize fittingSize = _sectionView.bounds.size;
    _sectionView.frame = CGRectMake(0, self.headerHeight, self.width, fittingSize.height);
}

-(CGFloat)expandedHeight {
    return self.bodyHeight  + self.headerHeight;
}

-(CGFloat)collapsedHeight {
    return self.headerHeight;
}

-(CGFloat)height {
    return (self.isExpanded) ? [self expandedHeight] : [self collapsedHeight];
}

-(CGFloat)width {
    return self.frame.size.width;
}

@end
