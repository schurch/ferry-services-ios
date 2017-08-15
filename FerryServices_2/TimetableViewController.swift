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

struct Section: SectionModelType {
    enum Row {
        case date(date: Date)
        case datePicker(date: Date)
        case header(from: String, to: String)
        case time(departureTime: String, arrivalTime: String)
    }
    
    enum SectionType {
        case dateSelector(date: Date, expanded: Bool)
        case departures(departures: [Departure], date: Date)
        
        func rows() -> [Row] {
            switch self {
            case let .dateSelector(date, expanded):
                return expanded ? [Row.date(date: date), Row.datePicker(date: date)] : [Row.date(date: date)]
            case let .departures(departures, date):
                let from = departures.first?.from ?? ""
                let to = departures.first?.to ?? ""
                
                let header = Row.header(from: from, to: to)
                let times = departures.map {
                    Row.time(departureTime: $0.departureTime, arrivalTime: $0.arrivalTime(withDate: date))
                }
                
                return [header] + times
            }
        }
    }
    
    var section: SectionType {
        didSet {
            items = section.rows()
        }
    }
    
    private(set) var items: [Row]
    
    init(section: SectionType) {
        self.section = section
        items = section.rows()
    }
    
    init(original: Section, items: [Row]) {
        self = original
        self.items = items
    }
}

class TimetableViewController: UIViewController {
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        return dateFormatter
    }()
    
    @IBOutlet weak var tableView: UITableView!
    
    var disposeBag = DisposeBag()
    var expanded = Variable(false)
    var date = Variable(Date())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let dataSource = RxTableViewSectionedReloadDataSource<Section>()
        dataSource.configureCell = configureCell
        
        let departures = date.asObservable().map { date in
            return (values: Departures().fetchDepartures(date: date, from: "9300BRB", to: "9300ARD"), date: date)
        }
        
        let sectionData: Observable<[Section]> = Observable.combineLatest(expanded.asObservable(), departures) {
            (expanded, departures) in
            let dateSelectorSection = Section.SectionType.dateSelector(date: departures.date, expanded: expanded)
            let departuresSection = Section.SectionType.departures(departures: departures.values, date: departures.date)
            
            return [Section(section: dateSelectorSection), Section(section: departuresSection)]
        }
        
        sectionData
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected.subscribe(onNext: { [unowned self] indexPath in
            self.expanded.value =  !self.expanded.value
        }).addDisposableTo(disposeBag)
    }
    
    private func configureCell(dataSource: TableViewSectionedDataSource<Section>, tableView: UITableView, indexPath: IndexPath, item: Section.Row) -> UITableViewCell {
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
        case let .date(date):
            let cell = tableView.dequeueReusableCell(withIdentifier: "dateCell", for: indexPath) as! TimetableDateTableViewCell
            cell.labelDeparturesArrivals.text = "Departures"
            cell.labelSelectedDate.text = TimetableViewController.dateFormatter.string(from: date)
            
            return cell
            
        case let .datePicker(date):
            let cell = tableView.dequeueReusableCell(withIdentifier: "datePickerCell", for: indexPath)
            let datePicker = cell.viewWithTag(99) as! UIDatePicker
            datePicker.date = date
            
            datePicker.addTarget(self, action: #selector(dateChanged(datePicker:)), for: UIControlEvents.valueChanged)
            
            return cell
            
        }
    }
    
    func dateChanged(datePicker: UIDatePicker) {
        date.value = datePicker.date
    }
    
}
