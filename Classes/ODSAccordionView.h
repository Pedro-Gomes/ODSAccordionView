//
//  ODSAccordionView.h
//  
//
//  Created by Johannes Seitz on 17/06/14.
//
//

#import <UIKit/UIKit.h>
#import "ODSAccordionSection.h"
#import "ODSAccordionSectionView.h"
#import "ODSMacros.h"

@class ODSAccordionSectionStyle;


@interface ODSAccordionView : UIScrollView<AccordionSectionDelegate>

-(id)initWithSections:(NSArray *)sections andSectionStyle:(ODSAccordionSectionStyle *)sectionStyle;

@end
