//
//  TimetableViewController.swift
//  FerryServices_2
//
//  Created by Stefan Church on 30/08/14.
//  Copyright (c) 2014 Stefan Church. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

struct DeparturesSection: SectionModelType {
    enum Row {
        case header(from: String, to: String)
        case time(departureTime: String, arrivalTime: String)
    }
    
    var items: [Row]
    
    init(depatures: [Departure]) {
        let from = depatures.first?.from ?? ""
        let to = depatures.first?.to ?? ""
        
        let header = Row.header(from: from, to: to)
        let times = depatures.map { Row.time(departureTime: $0.depatureTime, arrivalTime: $0.arrivalTime(withDate: Date())) }
        
        items = [header] + times
    }
    
    init(original: DeparturesSection, items: [Row]) {
        self = original
        self.items = items
    }
}

class TimetableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dataSource = RxTableViewSectionedReloadDataSource<DeparturesSection>()
        dataSource.configureCell = configureCell
        
        let depatures = Departures().fetchDepartures(date: Date(), from: "9300BRB", to: "9300ARD")
        Observable.just([DeparturesSection(depatures: depatures)])
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    private func configureCell(dataSource: TableViewSectionedDataSource<DeparturesSection>, tableView: UITableView, indexPath: IndexPath, item: DeparturesSection.Row) -> UITableViewCell {
        switch item {
        case let .header(from, to):
            let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath) as! TimetableHeaderViewCell
            cell.imageViewTransportType.image = #imageLiteral(resourceName: "ferry_icon")
            cell.labelHeader.text = "\(from) to \(to)"
            
            return cell
            
        case let .time(depatureTime, arrivalTime):
            let cell = tableView.dequeueReusableCell(withIdentifier: "timeCell", for: indexPath) as! TimetableTimeTableViewCell
            cell.labelTime.text = depatureTime
            cell.labelTimeCounterpart.text = "arriving at \(arrivalTime)"
            
            return cell
            
        }
    }
    
}
