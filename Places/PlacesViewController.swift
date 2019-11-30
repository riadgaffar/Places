//
//  ViewController.swift
//  Places
//
//  Created by Riad Gaffar on 11/17/19.
//  Copyright © 2019 rgi. All rights reserved.
//

import UIKit
import MapKit

class PlacesViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDelegate, UISearchBarDelegate, UITableViewDataSource {
    
    @IBOutlet var mapView:MKMapView?
    @IBOutlet var tableView:UITableView?
    @IBOutlet var searchBar:UISearchBar?
        
    let locationManager = LocationManager()
    let DELAY:Double = 1.0
    
    var currentLocation: CLLocation?
    var searchPlaceString: String = ""
       
    var places = [[String: Any]]()
    
    var timer:Timer?
    
//    private let timerQueue = DispatchQueue(label: "com.timer.queue", attributes: [])
//    var start: CFTimeInterval?
//    var totalElapsed: CFTimeInterval?
//    var timer: DispatchSourceTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        mapView?.delegate = self
        tableView?.delegate = self
        tableView?.dataSource = self
        searchBar?.delegate = self
        
        self.locationManager.start { location in
            self.currentLocation = location
            self.centerMapView(on: location)
        }
    }
    
    @objc func doRequest()
    {
        self.queryFoursquare(with: self.currentLocation!, searchText: self.searchPlaceString)
    }
    
    @IBAction func onClick(_ sender: UIButton, forEvent event: UIEvent){
        self.centerMapView(on: self.currentLocation!)
    }
    
    func centerMapView(on location: CLLocation)
    {
        guard mapView != nil else {
            return
        }

        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
        let adjustedRegion = mapView!.regionThatFits(region)

        mapView!.setRegion(adjustedRegion, animated: true)
    }
    
    func queryFoursquare(with location: CLLocation, searchText:String)
    {
        FoursquareAPI.shared.query(location: location, searchText: searchText, completionHandler: { places in
            self.places = places
            self.updatePlaces()
            self.tableView?.reloadData()
        })
    }
    
    func updatePlaces()
    {
        guard mapView != nil else {
            return
        }
        
        mapView!.removeAnnotations(mapView!.annotations)
        
        for place in places
        {
            if  let name      = place["name"] as? String,
                let latitude  = place["latitude"] as? CLLocationDegrees,
                let longitude = place["longitude"] as? CLLocationDegrees
            {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                annotation.title = name

                mapView!.addAnnotation(annotation)
            }

        }

    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: "annotationView")
        
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotationView")
            view!.canShowCallout = true
        } else {
            view!.annotation = annotation
        }
        
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier")
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellIdentifier")
        }
        cell!.textLabel?.text = places[indexPath.row]["name"] as? String
        cell!.detailTextLabel?.text = places[indexPath.row]["address"] as? String
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard mapView != nil else {
            return
        }
        
        guard let tappedName = places[indexPath.row]["name"] as? String else {
            return
        }
        
        for annotation in mapView!.annotations
        {
            mapView!.deselectAnnotation(annotation, animated: false)
            
            if tappedName == annotation.title {
                mapView!.selectAnnotation(annotation, animated: true)
                mapView!.setCenter(annotation.coordinate, animated: true)
            }

        }
    }
        
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (!searchText.isEmpty) {
            searchPlaceString = searchText
//            if (start == nil) {
//                restartTimer()
//            }
            timer?.invalidate()
            timer = nil
            timer = Timer.scheduledTimer(timeInterval: DELAY, target: self, selector: #selector(doRequest), userInfo: nil, repeats: false)

        } else {
            centerMapView(on: self.currentLocation!)
            places.removeAll()
            tableView?.reloadData()
            mapView?.removeAnnotations(mapView!.annotations)
//            pauseTimer()
            if(timer != nil) {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
//    func startTimer() {
//        timer = DispatchSource.makeTimerSource(queue: timerQueue)
//        timer?.schedule(deadline: .now(), repeating: 1.0)
//
//        timer?.setEventHandler { [weak self] in
//            guard let start = self?.start else { return }
//            let elapsed = Int((self?.totalElapsed ?? 0) + CACurrentMediaTime() - start)
//
//            print(">>>", elapsed)
//
//            if (elapsed >= self!.DELAY) {
//                self?.queryFoursquare(with: self!.currentLocation!, searchText: self!.searchPlaceString)
//                self?.pauseTimer()
//            }
//        }
//    }
//
//    private func restartTimer() {
//        start = CACurrentMediaTime()
//        timer?.resume()
//    }
//
//    private func pauseTimer() {
//        timer?.suspend()
//        totalElapsed = 0.0
//        start = nil
//    }
//
//    func cancelTimer() {
//            guard let timer = timer else { return }
//            timer.cancel()
//    //        self.timer = nil
//        }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: DELAY, target: self, selector: #selector(doRequest), userInfo: nil, repeats: false)
    }
    func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }

}

