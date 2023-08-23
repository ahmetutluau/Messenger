//
//  LocationPickerVC.swift
//  Messenger
//
//  Created by Ahmet Utlu on 8.06.2023.
//

import UIKit
import MapKit
import CoreLocation

final class LocationPickerVC: UIViewController {
    
    var completion: ((CLLocationCoordinate2D) -> Void)?
    var coordinates: CLLocationCoordinate2D?
    private var isPickable = true
    
    private lazy var map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        super.init(nibName: nil, bundle: nil)
        self.coordinates = coordinates
        self.isPickable = coordinates == nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(didTappedSendButton))
            map.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTappedMap(_:)))
            map.addGestureRecognizer(gesture)
        } else {
            // just showing location
            guard let coordinates else { return }
            
            // drop a pin in that location
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }

        view.addSubview(map)

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
    @objc private func didTappedSendButton() {
        guard let coordinates else { return }
        navigationController?.popViewController(animated: true)
        completion?(coordinates)
    }

    @objc private func didTappedMap(_ gesture: UITapGestureRecognizer) {
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        
        for anotation in map.annotations {
            map.removeAnnotation(anotation)
        }
        
        // drop a pin in that location
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
    }
}
