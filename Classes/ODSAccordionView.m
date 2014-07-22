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

@end

@implementation ODSAccordionView {
    NSArray *_sectionViews;
    ODSAccordionSectionStyle *_sectionStyle;
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
    
    for (ODSAccordionSectionView *section in _sectionViews) {
        if (section.tag != tag) {
            [section collapseSectionAnimated:NO];
        }
    }
    
    CGFloat height;
    
    if (expanded) {
        height = (self.frame.size.height - bodyHeight) / _sectionViews.count;
    } else {
        height = self.frame.size.height / _sectionViews.count;
    }

    [_sectionStyle setHeaderHeight:height];
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
        [UIView animateWithDuration:0.5 animations:^{
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
    self.contentSize = CGSizeMake([self width], self.frame.size.height);
}

-(CGFloat)width {
    return self.frame.size.width;
}

@end
