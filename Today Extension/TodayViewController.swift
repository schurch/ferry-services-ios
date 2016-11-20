//
//  TodayViewController.swift
//  Today Extension
//
//  Created by Stefan Church on 15/10/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController {
    
    private let sharedDefaults = UserDefaults(suiteName: "group.stefanchurch.ferryservices")
        
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var mapImage: UIImageView!
    @IBOutlet weak var routeLabel: UILabel!
    @IBOutlet weak var serviceDetailView: UIStackView!
    @IBOutlet weak var statusImageView: UIImageView!
    
    var dataTask: URLSessionDataTask?
    
    var serviceId: Int? {
        if let serviceId = sharedDefaults?.array(forKey: "lastViewedServiceIds")?.first as? Int, serviceId > 0 {
            return serviceId
        }
        
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapImage.layer.masksToBounds = true
        mapImage.layer.cornerRadius = 35
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let serviceId = serviceId else {
            show(message: "Your most recently viewed service will show here")
            return
        }
        
        let service = Service.defaultServices.filter({ $0.serviceId == serviceId }).first!
        configure(withService: service)
        
        fetchService(forServiceId: serviceId)
    }
    
    @IBAction func touchedButtonOpenApp(_ sender: UIButton) {
        guard let serviceId = serviceId else {
            return
        }
        
        extensionContext?.open(URL(string: "scottishferryapp://www.scottishferryapp.com/services/\(serviceId)")!, completionHandler: nil)
    }
    
    //MARK: - View configuration
    private func show(message: String) {
        messageLabel.text = message
        serviceDetailView.isHidden = true
        messageLabel.isHidden = false
    }
    
    private func configure(withService service: Service) {
        areaLabel.text = service.area
        routeLabel.text = service.route
        
        switch service.status {
        case .unknown:
            statusImageView.image = UIImage(named: "grey")
        case .normal:
            statusImageView.image = UIImage(named: "green")
        case .sailingsAffected:
            statusImageView.image = UIImage(named: "amber")
        case .sailingsCancelled:
            statusImageView.image = UIImage(named: "red")
        }
        
        if let mapImageData = sharedDefaults?.data(forKey: "mapImage") {
            mapImage.image = UIImage(data: mapImageData)
            mapImage.isHidden = false
        }
        else {
            mapImage.isHidden = true
        }
        
        messageLabel.isHidden = true
        routeLabel.isHidden = false
        serviceDetailView.isHidden = false
    }
    
    //MARK: - Utility 
    private func fetchService(forServiceId serviceId: Int) {
        let url = URL(string: "http://www.scottishferryapp.com/services/\(serviceId)")!
        
        dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let `self` = self else {
                return
            }
            
            guard error == nil else {
                DispatchQueue.main.async {
                    print("Error fetching service: \(error!.localizedDescription)")
                    self.show(message: "There was a problem with the server response.")
                }
                
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                if let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: AnyObject] {
                    DispatchQueue.main.async {
                        guard let service = Service(json: jsonDictionary) else {
                            self.show(message: "There was a problem with the server response.")
                            return
                        }

                        self.configure(withService: service)
                    }
                }
                
            } catch let error as NSError {
                DispatchQueue.main.async {
                    print("Error parsing json: \(error.localizedDescription)")
                    self.show(message: "There was a problem with the server response.")
                }
            }
        }
        
        dataTask?.resume()
    }
}

extension TodayViewController: NCWidgetProviding {
    
    private func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }
    
}
