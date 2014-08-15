//
//  SCServiceDetailTableViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 26/07/2014.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import MapKit

class ServiceDetailTableViewController: UITableViewController {
    
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
        
        configureMap()
        fetchLatestData()
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
        
    }
    
    // MARK: - refresh
    private func fetchLatestData() {
        if let serviceId = self.serviceStatus?.serviceId {
            APIClient.sharedInstance.fetchDisruptionDetailsForFerryServiceId(serviceId) { disruptionDetails, routeDetails, error in
                self.disruptionDetails = disruptionDetails
                self.routeDetails = routeDetails
                self.configureDisruptionDetails()
            }
        }
    }
    
    // MARK: - utility methods
    private func disriptionRowHeight() -> CGFloat {
        let drawingOpts: NSStringDrawingOptions = NSStringDrawingOptions.UsesLineFragmentOrigin
        let attributes = [NSFontAttributeName: self.labelDisruptionDetails.font]
        let boundingRect = self.labelDisruptionDetails.text.boundingRectWithSize(CGSize(width: self.labelDisruptionDetails.frame.size.width, height: CGFloat.max), options: drawingOpts, attributes: attributes, context: nil)
        var height = ceil(boundingRect.size.height);
        return height < 40 ? 60 : height + 74; // Height + padding
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
    override func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
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
}
