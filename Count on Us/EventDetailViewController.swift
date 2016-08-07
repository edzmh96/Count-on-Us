//
//  EventDetailViewController.swift
//  WESST
//
//  Created by Nathan Tannar on 2016-06-12.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Former
import Parse

class EventDetailViewController: FormViewController {
    
    // MARK: Public
    
    var event: PFObject?
    var business: PFObject?
    var confirmedUsernames = [String]()
    var maybeUsernames = [String]()
    var currentUserStatus = 2
    var confirmedUsers = [PFUser]()
    var maybeUsers = [PFUser]()
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(event)
        
        // Configure UI
        title = "Invitation Details"
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 30
        self.navigationController?.navigationBarHidden = false;
        
        confirmedUsers = event?.objectForKey("confirmed") as! [PFUser]
        maybeUsers = event?.objectForKey("maybe") as! [PFUser]
        
        for confirmed in confirmedUsers {
            let userQuery = PFUser.query()
            userQuery?.whereKey("objectId", equalTo: confirmed.objectId!)
            do {
                let userFound = try userQuery?.findObjects().first
                confirmedUsernames.append((userFound?.valueForKey("fullname") as? String)!)
                
            } catch _ {
                print("Error in finding User")
            }
            
        }
        
        for maybe in maybeUsers {
            let userQuery = PFUser.query()
            userQuery?.whereKey("objectId", equalTo: maybe.objectId!)
            do {
                let userFound = try userQuery?.findObjects().first
                maybeUsernames.append((userFound?.valueForKey("fullname") as? String)!)
                
            } catch _ {
                print("Error in finding User")
            }
            
        }
        if confirmedUsernames.contains((PFUser.currentUser()?.valueForKey("fullname") as? String)!) {
            currentUserStatus = 0
        }
        else if maybeUsernames.contains((PFUser.currentUser()?.valueForKey("fullname") as? String)!) {
            currentUserStatus = 1
        }
        
        configure()
    }
    
    // MARK: Private
    
    
    
    
    
    private lazy var zeroRow: LabelRowFormer<ImageCell> = {
        LabelRowFormer<ImageCell>(instantiateType: .Nib(nibName: "ImageCell")) {_ in
            }.configure {
                $0.rowHeight = 0
        }
    }()
    
    private lazy var eventRow: CustomRowFormer<EventFeedCell> = {
        CustomRowFormer<EventFeedCell> (instantiateType: .Nib(nibName: "EventFeedCell")) {
        var organizer = self.event!["organizer"] as! PFUser
        $0.title.text = self.event!["title"] as? String
        $0.location.text = self.event!["location"] as? String
        let startDate = self.event!["start"] as? NSDate
        let endDate = self.event!["end"] as? NSDate
        let interval = endDate!.timeIntervalSinceDate(startDate!)
        
        $0.timeDay.text = "\(startDate!.shortTimeString) on \(startDate!.longDateString) for \((Int(interval) + 1)/60) minutes"
        $0.organizer.text = "Organized By: \(organizer.valueForKey("fullname") as! String)"
        $0.attendence.text = "\(self.confirmedUsernames.count) Confirmed, \(self.maybeUsernames.count) Maybe"
        }.configure {
            $0.rowHeight = UITableViewAutomaticDimension
        }.onSelected { [weak self] _ in
            self?.former.deselect(true)

        }
    }()
    
    private lazy var newRow: LabelRowFormer<ProfileImageCell> = {
        LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
        $0.iconView.backgroundColor = SAP_COLOR
        $0.titleLabel.textColor = UIColor.blackColor()
        }.configure {
            $0.text = PFUser.currentUser()?.valueForKey("fullname") as? String
            $0.rowHeight = 60
        }.onSelected { [weak self] _ in
            self?.former.deselect(true)
            let profileVC = PublicProfileViewController()
            profileVC.user = PFUser.currentUser()!
            self?.navigationController?.pushViewController(profileVC, animated: true)
        }
    }()
    
    
    private func configure() {
        
        let dividerRow = CustomRowFormer<DividerCell>(instantiateType: .Nib(nibName: "DividerCell")) {
            $0.divider.backgroundColor = SAP_COLOR
            }.configure {
                $0.rowHeight = 8
        }
        
        var confirmedRows = [LabelRowFormer<ProfileImageCell>]()
        var maybeRows = [LabelRowFormer<ProfileImageCell>]()
        
        let currentFullName = PFUser.currentUser()?.valueForKey("fullname") as? String
        var index = 0
        for currentUser in confirmedUsernames {
            if currentUser != currentFullName {
                confirmedRows.append(LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
                    $0.iconView.backgroundColor = SAP_COLOR
                    $0.titleLabel.textColor = UIColor.blackColor()
                    }.configure {
                        $0.text = currentUser
                        $0.rowHeight = 60
                    }.onSelected { [weak self] _ in
                        self?.former.deselect(true)
                        let profileVC = PublicProfileViewController()
                        profileVC.user = self!.confirmedUsers[index]
                        self?.navigationController?.pushViewController(profileVC, animated: true)
                    })
            }
            index += 1
        }
        
        index = 0
        for currentUser in maybeUsernames {
            if currentUser != currentFullName {
                maybeRows.append(LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) {
                    $0.iconView.backgroundColor = SAP_COLOR
                    $0.titleLabel.textColor = UIColor.blackColor()
                    }.configure {
                        $0.text = currentUser
                        $0.rowHeight = 60
                    }.onSelected { [weak self] _ in
                        self?.former.deselect(true)
                        let profileVC = PublicProfileViewController()
                        profileVC.user = self!.maybeUsers[index]
                        self?.navigationController?.pushViewController(profileVC, animated: true)
                    })
            }
            index += 1
        }

        
        let choiceRow = SegmentedRowFormer<FormSegmentedCell>() {
            $0.titleLabel.text = "Attend this event?"
            $0.formSegmented().tintColor = SAP_COLOR
            $0.formSegmented().selectedSegmentIndex = self.currentUserStatus
            }.configure {
                $0.segmentTitles = ["Yes", "Maybe", "No"]
                $0.selectedIndex = currentUserStatus
            }.onSegmentSelected { (index, choice) in
                if self.currentUserStatus != index {
                    
                    self.former.remove(rowFormer: self.newRow)
                    self.former.reload(sections: NSIndexSet(indexesInRange: NSRange(location: 1, length: 3)))
                    
                    if index == 0 {
                        // User wants to go to the event
                        // Is there a stats change from 'Maybe'
                        if self.currentUserStatus == 1 {
                            let indexToRemove = self.maybeUsernames.indexOf((PFUser.currentUser()?.valueForKey("fullname") as? String)!)
                            self.maybeUsers.removeAtIndex(indexToRemove!)
                            self.maybeUsernames.removeAtIndex(indexToRemove!)
                            self.event!["maybe"] = self.maybeUsers
                        }
                        self.confirmedUsers.append(PFUser.currentUser()!)
                        self.confirmedUsernames.append((PFUser.currentUser()?.valueForKey("fullname") as? String)!)
                        self.event!["confirmed"] = self.confirmedUsers
                        self.event!.saveInBackground()
                        
                        self.former.insertUpdate(rowFormer: self.newRow, toIndexPath: NSIndexPath(forRow: 0, inSection: 2), rowAnimation: .Fade)
                    }
                    if index == 1 {
                        // User might go to the event event
                        // Is there a stats change from 'Yes'
                        if self.currentUserStatus == 0 {
                            let indexToRemove = self.confirmedUsernames.indexOf((PFUser.currentUser()?.valueForKey("fullname") as? String)!)
                            self.confirmedUsers.removeAtIndex(indexToRemove!)
                            self.confirmedUsernames.removeAtIndex(indexToRemove!)
                            self.event!["confirmed"] = self.confirmedUsers
                            
                            self.former.remove(rowFormer: self.newRow)
                        }
                        self.maybeUsers.append(PFUser.currentUser()!)
                        self.maybeUsernames.append((PFUser.currentUser()?.valueForKey("fullname") as? String)!)

                        self.event!["maybe"] = self.maybeUsers
                        self.event!.saveInBackground()
                        
                        self.former.insertUpdate(rowFormer: self.newRow, toIndexPath: NSIndexPath(forRow: 0, inSection: 3), rowAnimation: .Fade)
                    }
                    if index == 2 {
                        // User does not want to go
                        if self.currentUserStatus == 0 {
                            let indexToRemove = self.confirmedUsernames.indexOf((PFUser.currentUser()?.valueForKey("fullname") as? String)!)
                            self.confirmedUsers.removeAtIndex(indexToRemove!)
                            self.confirmedUsernames.removeAtIndex(indexToRemove!)
                            self.event!["confirmed"] = self.confirmedUsers
                        }
                        else if self.currentUserStatus == 1 {
                            let indexToRemove = self.maybeUsernames.indexOf((PFUser.currentUser()?.valueForKey("fullname") as? String)!)
                            self.maybeUsers.removeAtIndex(indexToRemove!)
                            self.maybeUsernames.removeAtIndex(indexToRemove!)
                            self.event!["maybe"] = self.maybeUsers
                        }
                        self.event!.saveInBackground()
                    }
                }
                
                self.currentUserStatus = index
                self.eventRow.cellUpdate({
                    $0.attendence.text = "\(self.confirmedUsernames.count) Confirmed, \(self.maybeUsernames.count) Maybe"
                })
        }
        
        self.former.append(sectionFormer: SectionFormer(rowFormer: eventRow, dividerRow))
        self.former.append(sectionFormer: SectionFormer(rowFormer: choiceRow))
        self.former.append(sectionFormer: SectionFormer(rowFormers: confirmedRows).set(headerViewFormer: Utilities.createHeader("Confirmed")))
        self.former.append(sectionFormer: SectionFormer(rowFormers: maybeRows).set(headerViewFormer: Utilities.createHeader("Maybe")))
        
        self.former.reload()
        
        if currentUserStatus == 0 {
            self.former.insertUpdate(rowFormer: self.newRow, toIndexPath: NSIndexPath(forRow: 0, inSection: 2), rowAnimation: .Fade)
        }
        else if currentUserStatus == 1 {
            self.former.insertUpdate(rowFormer: self.newRow, toIndexPath: NSIndexPath(forRow: 0, inSection: 3), rowAnimation: .Fade)
        }
        self.former.reload()

    }
    
}
