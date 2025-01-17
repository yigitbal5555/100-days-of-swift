//
//  MainViewController.swift
//  Capital Cities
//
//  Created by Brian Sipple on 2/5/19.
//  Copyright © 2019 Brian Sipple. All rights reserved.
//

import UIKit
import MapKit
import SafariServices

class MainViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    lazy var safariControllerConfig: SFSafariViewController.Configuration = {
        let config = SFSafariViewController.Configuration()
        
        config.entersReaderIfAvailable = true
        
        return config
    }()

    let mapStyleChoices = [
        "Standard": MKMapType.standard,
        "Satellite": MKMapType.satellite,
        "Satellite Flyover": MKMapType.satelliteFlyover,
        "Hybrid": MKMapType.hybrid,
        "Hybrid Flyover": MKMapType.hybridFlyover,
        "Muted Standard": MKMapType.mutedStandard,
    ]
}


// MARK: - Lifecycle

extension MainViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadAnnotations()
    }
}


// MARK: - Event handling

extension MainViewController {
    
    @IBAction func selectMapStyle(_ sender: Any) {
        let chooser = UIAlertController(title: "Choose a map style.", message: nil, preferredStyle: .actionSheet)

        for choiceName in mapStyleChoices.keys.sorted() {
            chooser.addAction(UIAlertAction(title: choiceName, style: .default, handler: switchMapStyle))
        }
        
        present(chooser, animated: true)
    }
}


// MARK: - Private Helper Methods

private extension MainViewController {
    
    func loadAnnotations() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let dataURL = Bundle.main.url(forResource: "capital-data", withExtension: "json") {
                do {
                    let decoder = JSONDecoder()
                    let data = try Data(contentsOf: dataURL)
                    
                    let annotations = try decoder.decode([CapitalAnnotation].self, from: data)
                    
                    DispatchQueue.main.async {
                        self?.annotationsDidLoad(annotations)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self?.showError(error, title: "Error while trying to load city data")
                        print(error)
                    }
                }
            } else {
                preconditionFailure("Unable to find capital data")
            }
        }
    }
    
    
    func annotationsDidLoad(_ annotations: [CapitalAnnotation]) {
        mapView.addAnnotations(annotations)
    }
    

    func switchMapStyle(action choiceAction: UIAlertAction) {
        guard let mapType = mapStyleChoices[choiceAction.title ?? ""] else {
            preconditionFailure("Couldn't get MKMapType from choice.")
        }
        
        mapView.mapType = mapType
    }
    
    
    func makeNewCapitalAnnotationView(from capitalAnnotation: CapitalAnnotation) -> MKPinAnnotationView {
        let annotationView = MKPinAnnotationView(annotation: capitalAnnotation, reuseIdentifier: CapitalAnnotation.reuseIdentifier)
        
        annotationView.canShowCallout = true
        annotationView.rightCalloutAccessoryView = UIButton.wikipediaMapCallout
        annotationView.pinTintColor = UIColor(hue: 0.72, saturation: 0.76, brightness: 0.87, alpha: 1.00)
        
        return annotationView
    }
}


// MARK: -  MKMapViewDelegate

extension MainViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let capitalAnnotation = annotation as? CapitalAnnotation else {
            return nil
        }
        
        if let annotationView = mapView.dequeueReusableAnnotationView(
            withIdentifier: CapitalAnnotation.reuseIdentifier
        ) as? MKPinAnnotationView {
            annotationView.annotation = capitalAnnotation

            return annotationView
        } else {
            return makeNewCapitalAnnotationView(from: capitalAnnotation)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let capitalAnnotation = view.annotation as? CapitalAnnotation else { return }
        
        let safariVC = SFSafariViewController(url: capitalAnnotation.wikipediaURL, configuration: safariControllerConfig)
        safariVC.delegate = self
        
        present(safariVC, animated: true)
    }
}


// MARK: - SFSafariViewControllerDelegate

extension MainViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true)
    }
}
