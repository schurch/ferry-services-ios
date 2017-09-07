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

class TimetableViewController: UIViewController {
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, dd MMM YYYY"
        dateFormatter.timeZone = Departures.timeZone
        return dateFormatter
    }()
    
    @IBOutlet weak var tableView: UITableView!
    
    var serviceId: Int!
    
    private var disposeBag = DisposeBag()
    private var expanded = Variable(false)
    private var date = Variable(Date())
    private var dataSource = RxTableViewSectionedReloadDataSource<Section>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Departures"
        
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        dataSource.configureCell = { [unowned self] dataSource, tableView, indexPath, item in
            
            switch item {
            case let .header(from, to):
                let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath) as! TimetableHeaderViewCell
                cell.imageViewTransportType.image = #imageLiteral(resourceName: "ferry_icon")
                cell.labelHeader.text = "\(from) to \(to)"
                
                return cell
                
            case let .time(depatureTime, arrivalTime, note):
                let cell = tableView.dequeueReusableCell(withIdentifier: "timeCell", for: indexPath) as! TimetableTimeTableViewCell
                cell.labelTime.text = depatureTime
                cell.labelTimeCounterpart.text = "arriving at \(arrivalTime)"
                cell.buttonInfo.isHidden = (note ?? "").isEmpty
                cell.touchedInfoButtonAction = { [unowned self] in
                    let alert = UIAlertController(title: note, message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                
                return cell
            case let .date(date):
                let cell = tableView.dequeueReusableCell(withIdentifier: "dateCell", for: indexPath) as! TimetableDateTableViewCell
                cell.labelDeparturesArrivals.text = "Departures"
                cell.labelSelectedDate.text = TimetableViewController.dateFormatter.string(from: date)
                
                return cell
                
            case let .datePicker(date):
                let cell = tableView.dequeueReusableCell(withIdentifier: "datePickerCell", for: indexPath) as! TimeTableDatePickerCell
                cell.datePicker.date = date
                
                cell.datePicker.rx.controlEvent(.valueChanged).subscribe(onNext: { _ in
                    self.date.value = cell.datePicker.date
                }).disposed(by: cell.disposeBag)
                
                return cell
                
            case .noSailings:
                return tableView.dequeueReusableCell(withIdentifier: "noSailingsCell", for: indexPath)
                
            }
            
        }
        
        let journeyPorts = Observable.just(serviceId).map { return Departures.fetchPorts(serviceId: $0) }

        let departures = Observable.combineLatest(date.asObservable(), journeyPorts) { date, journeyPorts -> (values: [[Departure]], date: (Date)) in
            
            let departures = journeyPorts.map({ journeyPort in
                return Departures.fetchDepartures(date: date, from: journeyPort.from, to: journeyPort.to, serviceId: self.serviceId)
            }).sorted(by: { lhs, rhs in
                guard let orderLhs = lhs.first?.order else { return false }
                guard let orderRhs = rhs.first?.order else { return false }
                return orderLhs < orderRhs
            })
            
            return (values: departures, date: date)
        }
        
        let sectionData: Observable<[Section]> = Observable.combineLatest(expanded.asObservable(), departures) {
            (expanded, departureGroups) in
            let dateSelectorSection = Section.SectionType.dateSelector(date: departureGroups.date, expanded: expanded)
            
            let departureSections = departureGroups.values.flatMap { (departures: [Departure]) -> Section? in
                guard !departures.isEmpty else { return nil }
                
                let sectionType = Section.SectionType.departures(departures: departures, date: departureGroups.date)
                return Section(sectionType: sectionType)
            }
            
            if departureSections.isEmpty {
                return [Section(sectionType: dateSelectorSection)] + [Section(sectionType: .noSailings)]
            }
            else {
                return [Section(sectionType: dateSelectorSection)] + departureSections
            }
        }
        
        sectionData
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected.subscribe(onNext: { [unowned self] indexPath in
            let item = self.dataSource[indexPath]
            if case .date = item {
                self.expanded.value =  !self.expanded.value
            }
        }).addDisposableTo(disposeBag)
    }
    
}

fileprivate struct Section: SectionModelType {
    
    enum Row {
        case date(date: Date)
        case datePicker(date: Date)
        case header(from: String, to: String)
        case time(departureTime: String, arrivalTime: String, note: String?)
        case noSailings
    }
    
    enum SectionType {
        case dateSelector(date: Date, expanded: Bool)
        case departures(departures: [Departure], date: Date)
        case noSailings
        
        func rows() -> [Row] {
            switch self {
            case let .dateSelector(date, expanded):
                return expanded ? [Row.date(date: date), Row.datePicker(date: date)] : [Row.date(date: date)]
            case let .departures(departures, date):
                let from = departures.first?.from ?? ""
                let to = departures.first?.to ?? ""
                
                let header = Row.header(from: from, to: to)
                let times = departures.map {
                    Row.time(departureTime: $0.departureTime, arrivalTime: $0.arrivalTime(withDate: date), note: $0.note)
                }
                
                return [header] + times
            case .noSailings:
                return [Row.noSailings]
            }
        }
    }
    
    private(set) var items: [Row]
    
    init(sectionType: SectionType) {
        items = sectionType.rows()
    }
    
    init(original: Section, items: [Row]) {
        self = original
        self.items = items
    }
    
}
