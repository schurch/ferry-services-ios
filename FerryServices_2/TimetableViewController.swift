//
//  TimetableViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 30/08/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class TimetableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TimetableTimeTableViewCellDelegate {
    
    fileprivate struct MainStoryboard {
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
    fileprivate let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE dd MMM yy"
        return dateFormatter
    }()
    
    // MARK: - private
    fileprivate var arrayOfRoutes: [Route]?
    fileprivate var date: Date!
    fileprivate var datePickerIndexPath: IndexPath?
    fileprivate var pickerCellRowHeight: Int!

    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Departures"
        
        self.tableView.estimatedRowHeight = 44
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        if let pickerCell = self.tableView.dequeueReusableCell(withIdentifier: MainStoryboard.TableViewCellIdentifiers.datePickerCell) {
            self.pickerCellRowHeight = Int(pickerCell.frame.size.height)
        }
        
        self.date = Date.stripTimeComponentsFromDate(Date())
        self.updateTrips()
    }
    
    // MARK: - UI Actions
    @IBAction func dateAction(_ sender: UIDatePicker) {
        if self.hasInlineDatePicker() {
            self.date = Date.stripTimeComponentsFromDate(sender.date)
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
    
    func routeForIndexPath(_ indexPath: IndexPath) -> Route? {
        if let routes = self.arrayOfRoutes {
            return routes[(indexPath as NSIndexPath).section - 1]
        }
        
        return nil
    }
    
    func tripForIndexPath(_ indexPath: IndexPath) -> Trip? {
        if let route = self.routeForIndexPath(indexPath) {
            if let trips = route.trips {
                return trips[(indexPath as NSIndexPath).row - 1]
            }
        }
        
        return nil
    }
    
    // MARK: - Inline date picker methods
    func hasInlineDatePicker() -> Bool {
        return self.datePickerIndexPath != nil
    }
    
    func hasDatePickerForIndexPath(_ indexPath: IndexPath) -> Bool {
        var datePicker: UIView?
        
        let indexPathToCheck = IndexPath(row: (indexPath as NSIndexPath).row + 1, section: (indexPath as NSIndexPath).section)
        
        if let datePickerCell = self.tableView.cellForRow(at: indexPathToCheck) {
            datePicker = datePickerCell.viewWithTag(MainStoryboard.Constants.datePickerTag)
        }
        
        return datePicker != nil
    }
    
    func updateDatePicker() {
        if let datePickerIndexPath = self.datePickerIndexPath {
            let datePickerCell = self.tableView.cellForRow(at: datePickerIndexPath)
            if let datePicker = datePickerCell?.viewWithTag(MainStoryboard.Constants.datePickerTag) as? UIDatePicker {
                datePicker.setDate(self.date, animated: false)
            }
        }
    }
    
    func isPickerAtIndexPath(_ indexPath: IndexPath) -> Bool {
        if self.hasInlineDatePicker() {
            return (self.datePickerIndexPath! as NSIndexPath).section == (indexPath as NSIndexPath).section && (self.datePickerIndexPath! as NSIndexPath).row == (indexPath as NSIndexPath).row
        }
        
        return false
    }
    
    func toggleDatePickerForSelectedIndexPath(_ indexPath: IndexPath) {
        self.tableView.beginUpdates()
        
        let pickerIndexPath = IndexPath(row: (indexPath as NSIndexPath).row + 1, section: (indexPath as NSIndexPath).section)
        
        if self.hasDatePickerForIndexPath(pickerIndexPath) {
            self.tableView.deleteRows(at: [pickerIndexPath], with: .fade)
        }
        else {
            self.tableView.insertRows(at: [pickerIndexPath], with: .fade)
        }
        
        self.tableView.endUpdates()
    }
    
    func displayInlineDatePickerForRowAtIndexPath(_ indexPath: IndexPath) {
        self.tableView.beginUpdates()
        
        var isBefore = false //indicates if the date picker is below "indexPath", help us determine which row to reveal
        var wasSameCellTapped = false
        
        if self.hasInlineDatePicker() {
            isBefore = (self.datePickerIndexPath! as NSIndexPath).row - 1 < (indexPath as NSIndexPath).row
            wasSameCellTapped = (self.datePickerIndexPath! as NSIndexPath).row - 1 == (indexPath as NSIndexPath).row
            
            // remove any date picker that exists
            self.tableView.deleteRows(at: [self.datePickerIndexPath!], with: .fade)
            self.datePickerIndexPath = nil
        }
        
        if !wasSameCellTapped {
            // hide the old date picker and display new one
            let rowToReveal = isBefore ? (indexPath as NSIndexPath).row - 1 : (indexPath as NSIndexPath).row
            let indexPathToReveal = IndexPath(row: rowToReveal, section: (indexPath as NSIndexPath).section)
            
            self.toggleDatePickerForSelectedIndexPath(indexPathToReveal)
            self.datePickerIndexPath = IndexPath(row: (indexPathToReveal as NSIndexPath).row + 1, section: (indexPathToReveal as NSIndexPath).section)
        }
        
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.tableView.endUpdates()
        self.updateDatePicker()
    }
    
    // MARK: - UITableViewDatasource
    func numberOfSections(in tableView: UITableView) -> Int {
        var count = 0
        if let routes = self.arrayOfRoutes {
            count = routes.count
        }
        
        return count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == 0 {
            if (indexPath as NSIndexPath).row == 0 {
                // date header
                let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.TableViewCellIdentifiers.dateCell) as! TimetableDateTableViewCell
                cell.labelDeparturesArrivals.text = "Departs on"
                
                let date = self.dateFormatter.string(from: self.date)
                cell.labelSelectedDate.text = "\(date)"
                
                return cell
            }
            else {
                // date picker
                return tableView.dequeueReusableCell(withIdentifier: MainStoryboard.TableViewCellIdentifiers.datePickerCell)!
            }
        }
        else {
            let routeForIndexPath = self.routeForIndexPath(indexPath)
            if (indexPath as NSIndexPath).row == 0 {
                // routes
                let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.TableViewCellIdentifiers.headerCell) as! TimetableHeaderViewCell
                
                if let route = routeForIndexPath {
                    cell.labelHeader.text = route.routeDescription()
                    
                    if let routeType = route.routeType {
                        var image :UIImage
                        switch routeType {
                        case .ferry:
                            image = UIImage(named: "ferry_icon")!
                        case .train:
                            image = UIImage(named: "train_icon")!
                        }
                        
                        cell.imageViewTransportType.image = image
                    }
                }
                
                return cell
            }
            else {
                // trips
                let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.TableViewCellIdentifiers.timeCell) as! TimetableTimeTableViewCell
                
                cell.delegate = self
                
                if let trip = self.tripForIndexPath(indexPath) {
                    cell.labelTime.text = trip.deparuteTime
                    cell.labelTimeCounterpart.text = "arriving at \(trip.arrivalTime)"
                    
                    if let notes = trip.notes?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
                        if notes.characters.count > 0 {
                            cell.buttonInfo.isHidden = false
                        }
                        else {
                            cell.buttonInfo.isHidden = true
                        }
                    }
                }
                
                return cell
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.isPickerAtIndexPath(indexPath) ? CGFloat(self.pickerCellRowHeight) : self.tableView.rowHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).row == 0 {
            if let dateCell = cell as? TimetableDateTableViewCell {
                if let window = UIApplication.shared.delegate?.window {
                    dateCell.labelSelectedDate.textColor = window!.tintColor
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) {
            if cell.reuseIdentifier == MainStoryboard.TableViewCellIdentifiers.dateCell {
                self.displayInlineDatePickerForRowAtIndexPath(indexPath)
            }
            else {
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    // MARK: - TimetableTimeTableViewCellDelegate
    func didTouchTimetableInfoButtonForCell(_ cell: TimetableTimeTableViewCell) {
        if let indexPath = self.tableView.indexPath(for: cell) {
            if let trip = self.tripForIndexPath(indexPath) {
                let alertController = UIAlertController(title: nil, message: trip.notes, preferredStyle: .alert)
                
                let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
