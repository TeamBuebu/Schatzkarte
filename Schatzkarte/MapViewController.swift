import UIKit
import CoreLocation


class MapViewController: UIViewController, CLLocationManagerDelegate, RMMapViewDelegate {
    
    let kAccessToken = "sk.eyJ1IjoidG9uaXN1dGVyIiwiYSI6ImNpZmptbnhxYTAxMGR0ZWx4ZjFhejdkMzEifQ.4HxuC8B4MW_slik23J9NqQ"
    let kMapID = "tonisuter.cife1ku4000gmtaknuv49tvwc"
    let kHsrCoordinate = CLLocationCoordinate2DMake(47.223252, 8.817011)
    let kSavedMarkersKey = "SavedMarkers"
    let kDefaultZoomLevel: Float = 17.0
    
    let locationManager = CLLocationManager()
    var mapView: RMMapView!
    let defaults = NSUserDefaults.standardUserDefaults()
    
    var coords = [Position]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        RMConfiguration.sharedInstance().accessToken = kAccessToken
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let tileSource: RMMapboxSource = RMMapboxSource(mapID: kMapID)
        mapView = RMMapView(frame: view.bounds, andTilesource: tileSource)
        mapView.zoom = kDefaultZoomLevel
        mapView.userTrackingMode = RMUserTrackingModeFollow
        mapView.delegate = self
        mapView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        self.view.addSubview(mapView)
        
        setSavedMarkers()
    }
    
    func setSavedMarkers(){
        
        if let unarchivedObject = defaults.objectForKey(kSavedMarkersKey) as? NSData {
            coords = (NSKeyedUnarchiver.unarchiveObjectWithData(unarchivedObject) as? [Position])!
        } else {
            coords = [Position]()
        }
        
        for var i = 0; i < coords.count; ++i {
            setMarker(coords[i], save: false)
        }
    }
    
    
    @IBAction func pressedSetMarker(sender: AnyObject){
        
        let alertController = UIAlertController(title: "Marker hinzufügen", message: "Bitte hier die Koordinaten eintragen:", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in}
        alertController.addAction(cancelAction)
        
        let submitAction = UIAlertAction(title: "Submit", style: .Default) { (action) in
            
            if let latitude = alertController.textFields![0].text, longitude = alertController.textFields![1].text{
                let lat: Double = (latitude as NSString).doubleValue
                let lon: Double = (longitude as NSString).doubleValue
                let pos = Position(lon: lon, lat: lat)
                self.setMarker(pos, save: true)
            }
        }
        alertController.addAction(submitAction)
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Latitude"
            textField.keyboardType = UIKeyboardType.NumbersAndPunctuation
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Longitude"
            textField.keyboardType = UIKeyboardType.NumbersAndPunctuation
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func setMarker(pos: Position, save: Bool){
        
        let cordination = CLLocationCoordinate2D(latitude: pos.lat, longitude: pos.lon)
        
        if CLLocationCoordinate2DIsValid(cordination){
        
            if save {
                coords.append(pos)
                saveXML()
            }
            
            let annotation: RMPointAnnotation = RMPointAnnotation(mapView: mapView, coordinate: cordination, andTitle: "Posten")
            mapView.addAnnotation(annotation)
            
        } else {
            
            let alertController = UIAlertController(title: "Fehler", message: "Koordinaten sind nicht korrekt! Marker wurde nicht hinzugefügt.", preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: "OK", style: .Cancel) { (action) in}
            alertController.addAction(cancelAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            
            debugPrint("Koordinaten sind nicht korrekt!")
        }
    }
    
    func saveXML(){
        
        let archivedCoords = NSKeyedArchiver.archivedDataWithRootObject(coords as NSArray)
        defaults.setObject(archivedCoords, forKey: kSavedMarkersKey)
        defaults.synchronize()
    }

    @IBAction func pressedLogSolution(sender: AnyObject) {
        
        var json = [String : AnyObject]()
        
        json["task"] = "Schatzkarte"
        let solutionLogger = SolutionLogger(viewController: self)
        
        json["points"] = getJsonArray()
        let solutionStr = solutionLogger.JSONStringify(json)
        
        solutionLogger.logSolution(solutionStr)
    }
    
    func getJsonArray() -> NSArray {
        
        var jsonArray = [[String : Int]]()
        
        for var i = 0; i < coords.count; ++i {
            let jsonPos = ["lat": coords[i].getJsonLat(), "lon": coords[i].getJsonLon()]
            jsonArray.append(jsonPos)
        }
        
        return jsonArray
    }
    
    @IBAction func pressedLocation(sender: AnyObject) {
        
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler:{ (placemarkers, error) -> Void in
            
            if error != nil
            {
                debugPrint("Error")
                return
            }
            
            if placemarkers!.count > 0
            {
                let lat = placemarkers![0].location?.coordinate.latitude
                let lon = placemarkers![0].location?.coordinate.longitude
                let coordination = CLLocationCoordinate2D(latitude: lat!, longitude: lon!)
                self.mapView.zoom = self.kDefaultZoomLevel
                self.mapView.centerCoordinate = coordination;
                
                self.locationManager.stopUpdatingLocation()
            }
            
            
        })
    }
    
    @IBAction func pressedHSRLocation(sender: AnyObject) {
        
        mapView.zoom = kDefaultZoomLevel
        mapView.centerCoordinate = kHsrCoordinate;
    }
 
    @IBAction func pressedDeleteMarkers(sender: AnyObject) {
        
        let alertController = UIAlertController(title: "Alle Marker löschen?", message: "Möchtest du wirklich alle Marker löschen. Dies kann nicht rückgangig gemacht werden.", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in}
        alertController.addAction(cancelAction)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .Default) { (action) in
            
            self.coords.removeAll()
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.saveXML()
        }
        alertController.addAction(deleteAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
