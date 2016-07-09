//
//  TimetableViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 30/08/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class TimetableViewController: UIViewController {
    
    private struct MainStoryboard {
        struct TableViewCellIdentifiers {
            static let headerCell = "headerCell"
            static let dateCell = "dateCell"
            static let timeCell = "timeCell"
            static let datePickerCell = "datePickerCell"
        }
        struct Constants {
            static let datePickerTag = 99
            static let dateRow = 0
            static let pickerAnimationDuration = 0.4
        }
    }
    
    @IBOutlet var tableView: UITableView!
    
    // MARK: - constants
    private let dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE dd MMM yy"
        return dateFormatter
    }()
    
    var serviceId: Int!
    
    // MARK: - private
    private var journeys: [[Journey]]!
    private var date: NSDate!
    private var datePickerIndexPath: NSIndexPath?
    private var pickerCellRowHeight: Int!

    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Departures"
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if let pickerCell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.datePickerCell) {
            pickerCellRowHeight = Int(pickerCell.frame.size.height)
        }
        
        date = NSDate.stripTimeComponentsFromDate(NSDate())
        updateTrips()
    }
    
    // MARK: - UI Actions
    @IBAction func dateAction(sender: UIDatePicker) {
        if hasInlineDatePicker() {
            date = NSDate.stripTimeComponentsFromDate(sender.date)
            updateTrips()
        }
    }
    
    // MARK: - Utility methods
    func updateTrips() {
        Database.defaultDatabase().fetchJourneys(serviceId: serviceId, date: date)
            .map { journeys in
                let groups = journeys.categorise { $0.from }
                
                return groups.reduce([]) { array, entry in
                    let (_, journeys) = entry
                    return array + [journeys]
                }
            }
            .next { (groupedJourneys: [[Journey]]) in
                self.journeys = groupedJourneys
                self.tableView.reloadData()
            }
    }

    
    // MARK: - Inline date picker methods
    func hasInlineDatePicker() -> Bool {
        return datePickerIndexPath != nil
    }
    
    func hasDatePickerForIndexPath(indexPath: NSIndexPath) -> Bool {
        var datePicker: UIView?
        
        let indexPathToCheck = NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)
        
        if let datePickerCell = tableView.cellForRowAtIndexPath(indexPathToCheck) {
            datePicker = datePickerCell.viewWithTag(MainStoryboard.Constants.datePickerTag)
        }
        
        return datePicker != nil
    }
    
    func updateDatePicker() {
        if let datePickerIndexPath = datePickerIndexPath {
            let datePickerCell = tableView.cellForRowAtIndexPath(datePickerIndexPath)
            if let datePicker = datePickerCell?.viewWithTag(MainStoryboard.Constants.datePickerTag) as? UIDatePicker {
                datePicker.setDate(date, animated: false)
            }
        }
    }
    
    func isPickerAtIndexPath(indexPath: NSIndexPath) -> Bool {
        if hasInlineDatePicker() {
            return datePickerIndexPath!.section == indexPath.section && datePickerIndexPath!.row == indexPath.row
        }
        
        return false
    }
    
    func toggleDatePickerForSelectedIndexPath(indexPath: NSIndexPath) {
        tableView.beginUpdates()
        
        let pickerIndexPath = NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)
        
        if hasDatePickerForIndexPath(pickerIndexPath) {
            tableView.deleteRowsAtIndexPaths([pickerIndexPath], withRowAnimation: .Fade)
        }
        else {
            tableView.insertRowsAtIndexPaths([pickerIndexPath], withRowAnimation: .Fade)
        }
        
        tableView.endUpdates()
    }
    
    func displayInlineDatePickerForRowAtIndexPath(indexPath: NSIndexPath) {
        tableView.beginUpdates()
        
        var isBefore = false //indicates if the date picker is below "indexPath", help us determine which row to reveal
        var wasSameCellTapped = false
        
        if hasInlineDatePicker() {
            isBefore = datePickerIndexPath!.row - 1 < indexPath.row
            wasSameCellTapped = datePickerIndexPath!.row - 1 == indexPath.row
            
            // remove any date picker that exists
            tableView.deleteRowsAtIndexPaths([datePickerIndexPath!], withRowAnimation: .Fade)
            datePickerIndexPath = nil
        }
        
        if !wasSameCellTapped {
            // hide the old date picker and display new one
            let rowToReveal = isBefore ? indexPath.row - 1 : indexPath.row
            let indexPathToReveal = NSIndexPath(forRow: rowToReveal, inSection: indexPath.section)
            
            toggleDatePickerForSelectedIndexPath(indexPathToReveal)
            datePickerIndexPath = NSIndexPath(forRow: indexPathToReveal.row + 1, inSection: indexPathToReveal.section)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        tableView.endUpdates()
        updateDatePicker()
    }

}

extension TimetableViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.journeys.count + 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return hasInlineDatePicker() ? 2 : 1
        }
        else {
            return journeys[section - 1].count + 1
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                // date header
                let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.dateCell) as! TimetableDateTableViewCell
                cell.labelDeparturesArrivals.text = "Departs on"
                
                let date = dateFormatter.stringFromDate(self.date)
                cell.labelSelectedDate.text = "\(date)"
                
                return cell
            }
            else {
                // date picker
                return tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.datePickerCell)!
            }
        }
        else {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.headerCell, forIndexPath: indexPath) as! TimetableHeaderViewCell
                
                let journey = journeys[indexPath.section - 1].first!
                cell.labelHeader.text = "\(journey.from) to \(journey.to)"
                
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.timeCell, forIndexPath: indexPath) as! TimetableTimeTableViewCell
                
                let journey = journeys[indexPath.section - 1][indexPath.row - 1]
                
                cell.labelTime.text = journey.departureTime
                cell.labelTimeCounterpart.text = "arriving at \(journey.arrivalTime)"
                
                return cell
            }
        }
    }
    
}

extension TimetableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return isPickerAtIndexPath(indexPath) ? CGFloat(pickerCellRowHeight) : tableView.rowHeight
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            if let dateCell = cell as? TimetableDateTableViewCell {
                if let window = UIApplication.sharedApplication().delegate?.window {
                    dateCell.labelSelectedDate.textColor = window!.tintColor
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            if cell.reuseIdentifier == MainStoryboard.TableViewCellIdentifiers.dateCell {
                displayInlineDatePickerForRowAtIndexPath(indexPath)
            }
            else {
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
    }
    
}
