//
//  SCServiceDetailTableViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 26/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import MapKit

class ServiceDetailTableViewController: UITableViewController, MKMapViewDelegate {
    
    struct MainStoryBoard {
        struct Constraints {
            static let imageViewTopSpace: CGFloat = 29
            static let imageViewTopSpaceReduced: CGFloat = 17
            static let disruptionDefaultLeadingSpace: CGFloat = 51
            static let disruptonMinusImageLeadingSpace: CGFloat = 13
        }
    }
    
    @IBOutlet var activityViewLoadingDisruptions :UIActivityIndicatorView!
    @IBOutlet var imageViewDisruption :UIImageView!
    @IBOutlet var constraintTopSpaceImageViewDisruption :NSLayoutConstraint!
    @IBOutlet var constraintDisruptionMessageLeadingSpace :NSLayoutConstraint!;
    @IBOutlet var labelDisruptionDetails: UILabel!
    @IBOutlet var labelEndTime: UILabel!
    @IBOutlet var labelEndTimeTitle: UILabel!
    @IBOutlet var labelLastUpdated: UILabel!
    @IBOutlet var labelNoDisruptions: UILabel!
    @IBOutlet var labelReason: UILabel!
    @IBOutlet var labelReasonTitle: UILabel!
    @IBOutlet var mapView :MKMapView!
    
    var serviceStatus: ServiceStatus?;
    var disruptionDetails: DisruptionDetails?;
    var routeDetails: RouteDetails?;
    
    // MARK: - private vars
    private var locations: [Location]?
    
    // MARK: - view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.serviceStatus?.area
        
        self.configureMap()
        self.fetchLatestDisruptionData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow() {
            self.tableView.deselectRowAtIndexPath(selectedIndexPath, animated: true)
        }
    }
    
    // MARK: - refresh
    private func fetchLatestDisruptionData() {
        if let serviceId = self.serviceStatus?.serviceId {
            self.prepareForDisruptionDetailsReload()
            APIClient.sharedInstance.fetchDisruptionDetailsForFerryServiceId(serviceId) { disruptionDetails, routeDetails, error in
                if (error == nil) {
                    self.disruptionDetails = disruptionDetails
                    self.routeDetails = routeDetails
                    self.configureDisruptionDetails()
                }
                else {
                    self.configureDisruptionErrorState()
                }
                
                self.finalizeDisruptionDetailsReload()
            }
        }
    }
    
    // MARK: - configure view
    private func configureMap() {
        if let serviceId = self.serviceStatus?.serviceId {
            self.locations = Location.fetchLocationsForSericeId(serviceId)
            
            let annotations: [MKPointAnnotation]? = self.locations?.map { location in
                let annotation = MKPointAnnotation()
                annotation.title = location.name
                annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude!, longitude: location.longitude!)
                return annotation
            }
            
            if annotations != nil {
                self.mapView.addAnnotations(annotations)
                let mapRect = calculateMapRectForAnnotations(annotations!)
                self.mapView.setVisibleMapRect(mapRect, edgePadding: UIEdgeInsets(top: 40, left: 20, bottom: 5, right: 20), animated: false)
            }
        }
    }
    
    private func configureDisruptionDetails() {
        self.constraintDisruptionMessageLeadingSpace.constant = MainStoryBoard.Constraints.disruptionDefaultLeadingSpace
        
        if let disruptionStatus = self.disruptionDetails?.disruptionStatus {
            switch disruptionStatus {
            case .Normal, .Information:
                self.configureNoDisruptionsState()
            default:
                self.configureDisruptionsState()
            }
        }
    }
    
    private func configureNoDisruptionsState() {
        self.imageViewDisruption.image = UIImage(named: "green")
        self.labelDisruptionDetails.text = "There are currently no disruptions with this service."
        self.constraintTopSpaceImageViewDisruption.constant = MainStoryBoard.Constraints.imageViewTopSpaceReduced
        self.imageViewDisruption.hidden = false
        self.labelNoDisruptions.hidden = false
    }
    
    private func configureDisruptionsState() {
        self.labelDisruptionDetails.text = self.disruptionDetails?.details
        
        if let disruptionStatus = self.disruptionDetails?.disruptionStatus {
            switch disruptionStatus {
            case .SailingsAffected:
                self.imageViewDisruption.image = UIImage(named: "amber")
            case .SailingsCancelled:
                self.imageViewDisruption.image = UIImage(named: "red")
            default:
                self.imageViewDisruption.image = nil
            }
        }
        
        self.labelReason.text = self.disruptionDetails?.reason?.capitalizedString
        
        if let date = self.disruptionDetails?.disruptionEndDate {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "dd MMM yyyy HH:mm"
            self.labelEndTime.text = dateFormatter.stringFromDate(date)
        }
        
        if let updatedDate = self.disruptionDetails?.updatedDate  {
            let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)
            let components = calendar.components(NSCalendarUnit.CalendarUnitDay|NSCalendarUnit.CalendarUnitHour|NSCalendarUnit.CalendarUnitMinute, fromDate: updatedDate, toDate: NSDate(), options: nil)
            
            var updated: String
            
            if components.day > 0 {
                let dayText = components.day == 1 ? "day" : "days"
                updated = "\(components.day) \(dayText) ago"
            }
            else if components.hour > 0 {
                let hourText = components.hour == 1 ? "hour" : "hours"
                updated = "\(components.hour) \(hourText) ago"
            }
            else {
                let minuteText = components.minute == 1 ? "minute" : "minutes"
                updated = "\(components.minute) \(minuteText) ago"
            }
            
            self.labelLastUpdated.text = "Last updated \(updated)"
        }
        else {
            self.labelLastUpdated.text = "Last updated N/A"
        }
        
        self.toggleDisruptionHidden(false)
    }
    
    private func configureDisruptionErrorState() {
        self.imageViewDisruption.image = nil
        self.labelNoDisruptions.text = "Unable to fetch the disruption status for this service."
        self.constraintTopSpaceImageViewDisruption.constant = MainStoryBoard.Constraints.imageViewTopSpaceReduced
        self.constraintDisruptionMessageLeadingSpace.constant = MainStoryBoard.Constraints.disruptonMinusImageLeadingSpace
        self.imageViewDisruption.hidden = true
        self.labelNoDisruptions.hidden = false
    }
    
    // MARK: - utility methods
    private func prepareForDisruptionDetailsReload() {
        self.toggleDisruptionHidden(true)
        self.labelNoDisruptions.hidden = true
        self.labelDisruptionDetails.hidden = true
        
        self.constraintTopSpaceImageViewDisruption.constant = MainStoryBoard.Constraints.imageViewTopSpace
        
        self.tableView.reloadData()
        self.activityViewLoadingDisruptions.startAnimating()
    }
    
    private func finalizeDisruptionDetailsReload() {
        self.activityViewLoadingDisruptions.stopAnimating()
        self.tableView.reloadData()
    }
    
    private func disriptionRowHeight() -> CGFloat {
        let drawingOpts: NSStringDrawingOptions = NSStringDrawingOptions.UsesLineFragmentOrigin
        let attributes = [NSFontAttributeName: self.labelDisruptionDetails.font]
        
        let size = CGSize(width: self.labelDisruptionDetails.frame.size.width, height: CGFloat.max)
        
        if let boundingRect = self.labelDisruptionDetails.text?.boundingRectWithSize(size, options: drawingOpts, attributes: attributes, context: nil) {
            let height = ceil(boundingRect.size.height);
            return height < 40 ? 60 : height + 74; // Height + padding
        }
        
        return 60;
    }
    
    private func calculateMapRectForAnnotations(annotations: [MKPointAnnotation]) -> MKMapRect {
        var mapRect = MKMapRectNull
        for annotation in annotations {
            let point = MKMapPointForCoordinate(annotation.coordinate)
            mapRect = MKMapRectUnion(mapRect, MKMapRect(origin: point, size: MKMapSize(width: 0.1, height: 0.1)))
        }
        return mapRect
    }
    
    private func toggleDisruptionHidden(hidden: Bool) {
        self.imageViewDisruption.hidden = hidden;
        self.labelDisruptionDetails.hidden = hidden;
        self.labelLastUpdated.hidden = hidden;
        self.labelReason.hidden = hidden;
        self.labelReasonTitle.hidden = hidden;
        self.labelEndTime.hidden = hidden;
        self.labelEndTimeTitle.hidden = hidden;
    }
    
    // MARK: - tableview delegate
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 44
        case 1:
            return 130
        case 2:
            return self.disriptionRowHeight()
        default:
            return 0
        }
    }
    
    // MARK: - mapview delegate
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
}
