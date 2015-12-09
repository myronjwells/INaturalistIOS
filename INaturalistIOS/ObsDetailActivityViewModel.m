//
//  ObsDetailActivityViewModel.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ObsDetailActivityViewModel.h"
#import "Observation.h"
#import "Comment.h"
#import "Identification.h"
#import "DisclosureCell.h"
#import "User.h"
#import "Activity.h"
#import "Taxon.h"
#import "ImageStore.h"
#import "TaxonPhoto.h"
#import "ObsDetailActivityMoreCell.h"
#import "UIColor+INaturalist.h"

@implementation ObsDetailActivityViewModel

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 4;
    } else if (section == self.observation.sortedActivity.count + 1) {
        return 1;
    } else {
        if (self.observation.sortedActivity == 0) {
            // if activity hasn't been loaded from the server yet
            return 0;
        }
        Activity *activity = [self activityForSection:section];
        if ([activity isKindOfClass:[Comment class]]) {
            return 2;
        } else if ([activity isKindOfClass:[Identification class]]) {
            Identification *identification = (Identification *)activity;
            if (identification.body && identification.body.length > 0) {
                return 4;
            } else {
                return 3;
            }
        } else {
            // impossibru
            return 0;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2 + self.observation.sortedActivity.count;
}

- (Activity *)activityForSection:(NSInteger)section {
    // 1st section is observation metadata
    return self.observation.sortedActivity[section - 1];
}

- (ObsDetailSection)sectionType {
    return ObsDetailSectionActivity;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section < 2) {
        return CGFLOAT_MIN;
    } else {
        return 15;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    } else if (indexPath.section == self.observation.sortedActivity.count + 1) {
        return 44;
    } else {
        Activity *activity = [self activityForSection:indexPath.section];
        if ([activity isKindOfClass:[Comment class]]) {
            if (indexPath.item == 0) {
                // size for user/date
                return 44;
            } else {
                // body row
                return [self heightForRowInTableView:tableView withBodyText:activity.body];
            }
        } else {
            // identification
            if ([self tableView:tableView numberOfRowsInSection:indexPath.section] == 4) {
                // contains body
                if (indexPath.item == 2) {
                    // body row
                    return [self heightForRowInTableView:tableView withBodyText:activity.body];
                } else {
                    // user/date, taxon, agree/action
                    return 44;
                }
            } else {
                // no body row, everything else 44
                return 44;
            }
        }
    }
}

- (CGFloat)heightForRowInTableView:(UITableView *)tableView withBodyText:(NSString *)text {
    CGFloat usableWidth = tableView.bounds.size.width - 16;
    CGSize maxSize = CGSizeMake(usableWidth, CGFLOAT_MAX);
    UIFont *font = [UIFont systemFontOfSize:12.0f];
    
    CGRect textRect = [text boundingRectWithSize:maxSize
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{ NSFontAttributeName: font }
                                         context:nil];
    
    return MAX(44, textRect.size.height);
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section < 2) {
        return [UITableViewHeaderFooterView new];
    } else if (section == self.observation.sortedActivity.count + 1) {
        return [UITableViewHeaderFooterView new];
    } else {
        UITableViewHeaderFooterView *view = [UITableViewHeaderFooterView new];
        view.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.3f];
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleRightMargin;
        view.frame = CGRectMake(0, 0, tableView.bounds.size.width, 15);
        [view addSubview:({
            UIView *thread = [UIView new];
            thread.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleRightMargin;
            thread.frame = CGRectMake(15 + 27 / 2.0 - 5, 0, 10, 15);
            thread.backgroundColor = [UIColor grayColor];
            thread;
        })];
        return view;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    } else {
        if (indexPath.section == self.observation.sortedActivity.count + 1) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"subtitle"];
            
            cell.textLabel.text = nil;
            cell.detailTextLabel.text = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UIButton *addComment = [UIButton buttonWithType:UIButtonTypeSystem];
            [addComment setTitle:NSLocalizedString(@"Comment", nil) forState:UIControlStateNormal];
            [addComment setBackgroundColor:[UIColor inatTint]];
            [addComment setTintColor:[UIColor whiteColor]];
            addComment.layer.cornerRadius = 17.0f;
            [addComment setFrame:CGRectMake(10, 5, (cell.bounds.size.width / 2) - 15, 34)];
            [addComment addTarget:self action:@selector(addComment) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:addComment];
            
            UIButton *addID = [UIButton buttonWithType:UIButtonTypeSystem];
            [addID setTitle:NSLocalizedString(@"Suggest ID", nil) forState:UIControlStateNormal];
            [addID setBackgroundColor:[UIColor inatTint]];
            [addID setTintColor:[UIColor whiteColor]];
            addID.layer.cornerRadius = 17.0f;
            [addID setFrame:CGRectMake((cell.bounds.size.width / 2) + 5, 5, (cell.bounds.size.width / 2) - 15, 34)];
            [addID addTarget:self action:@selector(addIdentification) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:addID];
            
            return cell;
        }
        if (indexPath.item == 0) {
            DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
            
            Activity *activity = [self activityForSection:indexPath.section];
            if (activity) {
                NSURL *userIconUrl = [NSURL URLWithString:activity.user.userIconURL];
                if (userIconUrl) {
                    [cell.cellImageView sd_setImageWithURL:userIconUrl];
                    cell.cellImageView.layer.cornerRadius = 27.0 / 2;
                    cell.cellImageView.clipsToBounds = YES;
                } else {
                    cell.cellImageView.image = nil;
                }
                NSDateFormatter *dateFormatter = [NSDateFormatter new];
                dateFormatter.dateStyle = NSDateFormatterShortStyle;
                dateFormatter.timeStyle = NSDateFormatterNoStyle;
                dateFormatter.doesRelativeDateFormatting = YES;

                cell.titleLabel.text = activity.user.login;
                cell.secondaryLabel.text = [dateFormatter stringFromDate:activity.createdAt];
            }

            return cell;
        } else if (indexPath.item == 1) {
            Activity *activity = [self activityForSection:indexPath.section];
            if ([activity isKindOfClass:[Comment class]]) {
                // body
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"subtitle"];
                
                UITextView *tv = [[UITextView alloc] initWithFrame:CGRectZero];
                tv.font = [UIFont systemFontOfSize:12.0f];
                tv.translatesAutoresizingMaskIntoConstraints = NO;
                tv.text = activity.body;
                tv.dataDetectorTypes = UIDataDetectorTypeLink;
                tv.editable = NO;
                tv.scrollEnabled = NO;
                [cell.contentView addSubview:tv];
                
                NSDictionary *views = @{ @"tv": tv };
                
                [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[tv]-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];
                
                [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tv]-0-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];

                
                NSError *err;
                tv.attributedText = [[NSAttributedString alloc] initWithData:[activity.body dataUsingEncoding:NSUTF8StringEncoding]
                                                                     options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                          documentAttributes:nil
                                                                       error:&err];

                return cell;
            } else if ([activity isKindOfClass:[Identification class]]) {
                Identification *i = (Identification *)activity;
                // taxon
                DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
                
                Taxon *taxon = i.taxon;
                
                if (taxon) {
                    
                    cell.titleLabel.textColor = i.isCurrent ? [UIColor blackColor] : [UIColor lightGrayColor];

                    cell.titleLabel.text = taxon.defaultName;
                    
                    cell.cellImageView.layer.borderWidth = 0.5f;
                    cell.cellImageView.layer.borderColor = [UIColor colorWithHexString:@"#777777"].CGColor;
                    cell.cellImageView.layer.cornerRadius = 3.0f;
                    
                    if ([taxon.isIconic boolValue]) {
                        cell.cellImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
                    } else if (taxon.taxonPhotos.count > 0) {
                        TaxonPhoto *tp = taxon.taxonPhotos.firstObject;
                        [cell.cellImageView sd_setImageWithURL:[NSURL URLWithString:tp.thumbURL]];
                    } else {
                        cell.cellImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
                    }
                    
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
                
                return cell;
            }
        } else if (indexPath.item == 2) {
            // must be identification
            Identification *i = (Identification *)[self activityForSection:indexPath.section];
            if (i.body && i.body.length > 0) {
                // body
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"subtitle"];
                
                UITextView *tv = [[UITextView alloc] initWithFrame:CGRectZero];
                tv.translatesAutoresizingMaskIntoConstraints = NO;
                tv.font = [UIFont systemFontOfSize:12.0f];
                tv.text = i.body;
                tv.dataDetectorTypes = UIDataDetectorTypeLink;
                tv.editable = NO;
                tv.scrollEnabled = NO;
                [cell.contentView addSubview:tv];
                
                NSDictionary *views = @{ @"tv": tv };
                
                [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[tv]-|"
                                                                           options:0
                                                                           metrics:0
                                                                              views:views]];
                
                [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tv]-0-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];

                NSError *err;
                tv.attributedText = [[NSAttributedString alloc] initWithData:[i.body dataUsingEncoding:NSUTF8StringEncoding]
                                                                     options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                          documentAttributes:nil
                                                                       error:&err];
                
                return cell;
            } else {
                ObsDetailActivityMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:@"activityMore"];
                return cell;
            }
        } else if (indexPath.item == 3) {
            ObsDetailActivityMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:@"activityMore"];
            return cell;
        } else {
            // impossibru!
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetail"];
            
            return cell;
        }
    }
}

#pragma mark - uibutton targets

- (void)addComment {
    [self.delegate inat_performSegueWithIdentifier:@"addComment"];
}

- (void)addIdentification {
    [self.delegate inat_performSegueWithIdentifier:@"addIdentification"];
}



@end