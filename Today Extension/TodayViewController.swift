//
//  TodayViewController.swift
//  Today Extension
//
//  Created by Stefan Church on 15/10/16.
//  Copyright © 2016 Stefan Church. All rights reserved.
//

import NotificationCenter

class TodayViewController: UIViewController {
    
    private let sharedDefaults = UserDefaults(suiteName: "group.stefanchurch.ferryservices")
        
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var mapImage: UIImageView!
    @IBOutlet weak var routeLabel: UILabel!
    @IBOutlet weak var serviceDetailView: UIStackView!
    @IBOutlet weak var statusImageView: UIImageView!
    
    var serviceId: Int? {
        return sharedDefaults?.array(forKey: "lastViewedServiceIds")?.first as? Int
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
        
        let service = Service.defaultServices.first(where: { $0.serviceId == serviceId})!
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
        case .disrupted:
            statusImageView.image = UIImage(named: "amber")
        case .cancelled:
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
        API.fetchService(serviceID: serviceId) { result in
            switch result {
            case .success(let service):
                self.configure(withService: service)
            case .failure:
                self.show(message: "There was a problem with the server response.")
            }
        }
    }
}

extension TodayViewController: NCWidgetProviding {
    
    private func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }
    
}
