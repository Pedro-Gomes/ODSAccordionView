//
//  ODSAccordionView.m
//  
//
//  Created by Johannes Seitz on 17/06/14.
//
//

#import "ODSAccordionView.h"
#import "ODSAccordionSection.h"
#import "ODSAccordionSectionView.h"
#import "ODSAccordionSectionStyle.h"

#define DIVIDER_HEIGHT ([UIScreen mainScreen].scale == 2.0) ? 0.5 : 1.0
#define SECTION_HEIGHT_GETTER NSStringFromSelector(@selector(height))

@interface ODSAccordionView ()

@property (nonatomic, assign) BOOL animationEnabled;
@property (nonatomic, assign) BOOL firstLayout;

@property (nonatomic, copy) void (^actionBlock)(id sender);
@property (nonatomic, strong) UIButton* actionButton;

@end

@implementation ODSAccordionView {
    NSArray *_sectionViews;
    ODSAccordionSectionStyle *_sectionStyle;
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
            [self.actionButton setImage:image forState:UIControlStateNormal];
            [self.actionButton.imageView setContentMode:UIViewContentModeCenter];
        }
        [self.actionButton addTarget:self action:@selector(actionButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        
        [self setActionBlock:block];
        [self.actionButton setBackgroundColor:_sectionStyle.buttonColor];
         [self addSubview:self.actionButton];

    } else {
        [self.actionButton removeFromSuperview];
        self.actionButton = nil;
    }
}

-(id)initWithSections:(NSArray *)sections andSectionStyle:(ODSAccordionSectionStyle *)sectionStyle {
    self = [super init];
    if (self) {
        _sectionViews = @[];
        _sectionStyle = sectionStyle;
        [self setFirstLayout:YES];
        for (NSUInteger i = 0; i < [sections count]; i++) {
            ODSAccordionSection*currentSection = [sections objectAtIndex:i];
            ODSAccordionSectionView *sectionView =
                    [[ODSAccordionSectionView alloc] initWithTitle:currentSection.title
                                                           andView:currentSection.view
                                                      sectionStyle:sectionStyle];
            
            if ([currentSection.view respondsToSelector:@selector(setSectionView:)]) {
                [currentSection.view performSelector:@selector(setSectionView:) withObject:sectionView];
            }
            sectionView.tag = i + 1 ; //don't use tag 0
            sectionView.delegate = (id<AccordionSectionDelegate>)self;
            sectionView.bodyHeight = currentSection.view.frame.size.height;
            [self addSection:sectionView];
        }
    }
    return self;
}

-(void)addSection:(ODSAccordionSectionView*)newSection {
    [self addSubview:newSection];
    _sectionViews = [_sectionViews arrayByAddingObject:newSection];
    BOOL isFirstSection = [_sectionViews count] == 1;
    if (!isFirstSection){
        [newSection.header addSubview:[self makeDivider:_sectionStyle.dividerColor]];
    }
}

-(void)dealloc {
    for (ODSAccordionSectionView *section in _sectionViews){
        @try {
            [section removeObserver:self forKeyPath:SECTION_HEIGHT_GETTER];
        }
        @catch (NSException * __unused exception) {}
    }
}

-(UIView *)makeDivider:(UIColor *)dividerColour {
    UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, DIVIDER_HEIGHT)];
    if (dividerColour){
        divider.backgroundColor = dividerColour;
    } else {
        divider.backgroundColor = [UIColor blackColor];
    }
    divider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    return divider;
}

#pragma AccordionSectionViewDelegate
-(void)accordionSection:(id)section didChangeStatus:(BOOL)expanded headerHeight:(CGFloat)headerHeight bodyHeight:(CGFloat)bodyHeight {
    ODSAccordionSectionView* sectionView = section;
    int tag = sectionView.tag;
    
    for (ODSAccordionSectionView *view in _sectionViews) {
        if (view.tag != tag) {
            [view collapseSectionAnimated:NO];
        }
    }
    
    CGFloat height;
    
    if (sectionView.expanded) {
        if ([[self superview] isKindOfClass:[ODSAccordionSectionView class]]) {
            height = (self.frame.size.height - bodyHeight) / _sectionViews.count;
            //sectionView.bodyHeight = bodyHeight + height;
            
        } else {
            height = (self.frame.size.height - bodyHeight) / _sectionViews.count;
        }
        
    } else {
        height = self.frame.size.height / _sectionViews.count;
    }
    

    
    [_sectionStyle setHeaderHeight: height];
    [self setAnimationEnabled:YES];
    [self setNeedsLayout];
}

-(void)layoutSubviews {
    if (self.firstLayout) {
        [self setFirstLayout:NO];
        CGFloat height = self.frame.size.height / _sectionViews.count;
        [_sectionStyle setHeaderHeight:height];
    }
    
    if(self.animationEnabled){
        [UIView animateWithDuration:_sectionStyle.animationDuration animations:^{
            [super layoutSubviews];
            [self recalculateSectionPositionsAndHeight];
        }];
    } else {
        [super layoutSubviews];
        [self recalculateSectionPositionsAndHeight];
    }
}

-(void)recalculateSectionPositionsAndHeight {
    CGFloat bottomOfPreviousSection = 0;
    
    for (ODSAccordionSectionView *section in _sectionViews) {
        CGRect newFrame = CGRectMake(0, bottomOfPreviousSection, self.width, section.height);
        if (!CGRectEqualToRect(newFrame, section.frame)){
            section.frame = newFrame;
        }
        bottomOfPreviousSection = bottomOfPreviousSection + section.height;
    }
    [self updateScrollViewContentSize:bottomOfPreviousSection];
}

-(void)updateScrollViewContentSize:(CGFloat)bottomOfLastSection {
    if(bottomOfLastSection > self.frame.size.height){
        self.contentSize = CGSizeMake([self width], bottomOfLastSection);
    }else {
        self.contentSize = CGSizeMake([self width], self.frame.size.height);
    }
}

-(CGFloat)width {
    return self.frame.size.width;
}

/*This array will contain ODSAccordionSectionView objects and can be used to activate the section rightbuttons*/
-(NSArray *)getSections {
    return _sectionViews;
}

@end
