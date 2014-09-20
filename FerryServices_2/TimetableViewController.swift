//
//  TimetableViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 30/08/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit

class TimetableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TimetableTimeTableViewCellDelegate {
    
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
    
    // MARK: - public
    var routeId: Int!
    
    // MARK: - constants
    private let dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE dd MMM yy"
        return dateFormatter
    }()
    
    // MARK: - private
    private var arrayOfRoutes: [Route]?
    private var date: NSDate!
    private var datePickerIndexPath: NSIndexPath?
    private var pickerCellRowHeight: Int!

    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Departures"
        
        let pickerCell = self.tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.datePickerCell) as UITableViewCell
        self.pickerCellRowHeight = Int(pickerCell.frame.size.height)
        
        self.date = self.stripTimeComponentsFromDate(NSDate())
        self.updateTrips()
    }
    
    // MARK: - UI Actions
    @IBAction func dateAction(sender: UIDatePicker) {
        if self.hasInlineDatePicker() {
            self.date = self.stripTimeComponentsFromDate(sender.date)
            self.updateTrips()            
        }
    }
    
    // MARK: - Utility methods
    func updateTrips() {
        if self.routeId != nil && self.date != nil {
            self.arrayOfRoutes = Route.fetchRoutesForServiceId(self.routeId, date: self.date)?.filter { $0.trips?.count > 0 }
        }
        
        self.tableView.reloadData()
    }
    
    func routeForIndexPath(indexPath: NSIndexPath) -> Route? {
        if let routes = self.arrayOfRoutes {
            return routes[indexPath.section - 1]
        }
        
        return nil
    }
    
    func tripForIndexPath(indexPath: NSIndexPath) -> Trip? {
        if let route = self.routeForIndexPath(indexPath) {
            if let trips = route.trips {
                return trips[indexPath.row - 1]
            }
        }
        
        return nil
    }
    
    func stripTimeComponentsFromDate(date: NSDate) -> NSDate {
        let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)
        calendar.timeZone = NSTimeZone(abbreviation: "UTC")
        
        let components = calendar.components(NSCalendarUnit.CalendarUnitYear|NSCalendarUnit.CalendarUnitMonth|NSCalendarUnit.CalendarUnitDay|NSCalendarUnit.CalendarUnitHour|NSCalendarUnit.CalendarUnitMinute|NSCalendarUnit.CalendarUnitSecond, fromDate: date)
        
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        let date = calendar.dateFromComponents(components)
        
        return date!
    }
    
    // MARK: - Inline date picker methods
    func hasInlineDatePicker() -> Bool {
        return self.datePickerIndexPath != nil
    }
    
    func hasDatePickerForIndexPath(indexPath: NSIndexPath) -> Bool {
        var datePicker: UIView?
        
        let indexPathToCheck = NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)
        
        if let datePickerCell = self.tableView.cellForRowAtIndexPath(indexPathToCheck) {
            datePicker = datePickerCell.viewWithTag(MainStoryboard.Constants.datePickerTag)
        }
        
        return datePicker != nil
    }
    
    func updateDatePicker() {
        if let datePickerIndexPath = self.datePickerIndexPath {
            let datePickerCell = self.tableView.cellForRowAtIndexPath(datePickerIndexPath)
            if let datePicker = datePickerCell?.viewWithTag(MainStoryboard.Constants.datePickerTag) as? UIDatePicker {
                datePicker.setDate(self.date, animated: false)
            }
        }
    }
    
    func isPickerAtIndexPath(indexPath: NSIndexPath) -> Bool {
        if self.hasInlineDatePicker() {
            return self.datePickerIndexPath!.section == indexPath.section && self.datePickerIndexPath!.row == indexPath.row
        }
        
        return false
    }
    
    func toggleDatePickerForSelectedIndexPath(indexPath: NSIndexPath) {
        self.tableView.beginUpdates()
        
        let pickerIndexPath = NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)
        
        if self.hasDatePickerForIndexPath(pickerIndexPath) {
            self.tableView.deleteRowsAtIndexPaths([pickerIndexPath], withRowAnimation: .Fade)
        }
        else {
            self.tableView.insertRowsAtIndexPaths([pickerIndexPath], withRowAnimation: .Fade)
        }
        
        self.tableView.endUpdates()
    }
    
    func displayInlineDatePickerForRowAtIndexPath(indexPath: NSIndexPath) {
        self.tableView.beginUpdates()
        
        var isBefore = false //indicates if the date picker is below "indexPath", help us determine which row to reveal
        var wasSameCellTapped = false
        
        if self.hasInlineDatePicker() {
            isBefore = self.datePickerIndexPath!.row - 1 < indexPath.row
            wasSameCellTapped = self.datePickerIndexPath!.row - 1 == indexPath.row
            
            // remove any date picker that exists
            self.tableView.deleteRowsAtIndexPaths([self.datePickerIndexPath!], withRowAnimation: .Fade)
            self.datePickerIndexPath = nil
        }
        
        if !wasSameCellTapped {
            // hide the old date picker and display new one
            let rowToReveal = isBefore ? indexPath.row - 1 : indexPath.row
            let indexPathToReveal = NSIndexPath(forRow: rowToReveal, inSection: indexPath.section)
            
            self.toggleDatePickerForSelectedIndexPath(indexPathToReveal)
            self.datePickerIndexPath = NSIndexPath(forRow: indexPathToReveal.row + 1, inSection: indexPathToReveal.section)
        }
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.tableView.endUpdates()
        self.updateDatePicker()
    }
    
    // MARK: - UITableViewDatasource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var count = 0
        if let routes = self.arrayOfRoutes {
            count = routes.count
        }
        
        return count + 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.hasInlineDatePicker() ? 2 : 1
        }
        else {
            if let route = self.arrayOfRoutes?[section - 1] {
                if let trips = route.trips {
                    let tripCount = trips.count + 1
                    return tripCount
                }
            }
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                // date header
                let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.dateCell) as TimetableDateTableViewCell
                cell.labelDeparturesArrivals.text = "Departs on"
                
                let date = self.dateFormatter.stringFromDate(self.date)
                cell.labelSelectedDate.text = "\(date)"
                
                return cell
            }
            else {
                // date picker
                let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.datePickerCell) as UITableViewCell
                return cell
            }
        }
        else {
            let routeForIndexPath = self.routeForIndexPath(indexPath)
            if indexPath.row == 0 {
                // routes
                let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.headerCell) as TimetableHeaderViewCell
                
                if let route = routeForIndexPath {
                    cell.labelHeader.text = route.routeDescription()
                    
                    if let routeType = route.routeType {
                        var image :UIImage
                        switch routeType {
                        case .Ferry:
                            image = UIImage(named: "ferry_icon")
                        case .Train:
                            image = UIImage(named: "train_icon")
                        }
                        
                        cell.imageViewTransportType.image = image
                    }
                }
                
                return cell
            }
            else {
                // trips
                let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.timeCell) as TimetableTimeTableViewCell
                
                cell.delegate = self
                
                if let trip = self.tripForIndexPath(indexPath) {
                    cell.labelTime.text = trip.deparuteTime
                    cell.labelTimeCounterpart.text = "arriving at \(trip.arrivalTime)"
                    
                    if let notes = trip.notes?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
                        if countElements(notes) > 0 {
                            cell.buttonInfo.hidden = false
                        }
                        else {
                            cell.buttonInfo.hidden = true
                        }
                    }
                }
                
                return cell
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.isPickerAtIndexPath(indexPath) ? CGFloat(self.pickerCellRowHeight) : self.tableView.rowHeight
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            if let dateCell = cell as? TimetableDateTableViewCell {
                if let window = UIApplication.sharedApplication().delegate?.window? {
                    dateCell.labelSelectedDate.textColor = window.tintColor
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
            if cell.reuseIdentifier == MainStoryboard.TableViewCellIdentifiers.dateCell {
                self.displayInlineDatePickerForRowAtIndexPath(indexPath)
            }
            else {
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
    }
    
    // MARK: - TimetableTimeTableViewCellDelegate
    func didTouchTimetableInfoButtonForCell(cell: TimetableTimeTableViewCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            if let trip = self.tripForIndexPath(indexPath) {
                UIAlertView(title: nil, message: trip.notes, delegate: nil, cancelButtonTitle: "OK").show()
            }
        }
    }
}
