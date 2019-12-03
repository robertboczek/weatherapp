//
//  ViewController.swift
//  WeatherApp
//
//  Created by Robert Boczek on 11/18/19.
//  Copyright © 2019 Robert Boczek. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import NVActivityIndicatorView
import CoreLocation
import Alamofire

import FBAudienceNetwork;

class ViewController: UIViewController, CLLocationManagerDelegate, FBAdViewDelegate {

    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var tomorrowLabel: UILabel!
    
    @IBOutlet weak var conditionImageView: UIImageView!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var metricLabel: UILabel!
    @IBOutlet weak var imperialLabel: UILabel!
    
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var nowLabel: UILabel!
    
    var apiUnit: String
    var apiEndpoint: String
    var bannerAdView: FBAdView!
    
    let gradientLayer = CAGradientLayer()
    
    let selectedItemFont = UIFont(name: "Arial Rounded MT Bold", size: 28)
    let notSelectedItemFont = UIFont(name: "Avenir", size: 20)
    
    let apiKey = "d9f9f29395c8b71049a8e921c9e89748"
    var lat = 50.049683
    var lon = 19.944544
    var activityIndicator: NVActivityIndicatorView!
    let locationManager = CLLocationManager()
    
    var cachedForecastC : JSON? = nil
    var lastForecastCallTimestampC = 0
    var cachedForecastF : JSON? = nil
    var lastForecastCallTimestampF = 0
    var cachedWeatherC : JSON? = nil
    var lastWeatherCallTimestampC = 0
    var cachedWeatherF : JSON? = nil
    var lastWeatherCallTimestampF = 0
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)   {
        print("init")
        print("Load defaults")
        let savedUnit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "imperial"
        print("Loaded default temperature unit: \(savedUnit)")
        apiUnit = savedUnit
        let savedEndpoint = UserDefaults.standard.string(forKey: "endpoint") ?? "weather"
        print("Loaded default endpoint: \(savedEndpoint)")
        apiEndpoint = savedEndpoint
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        print("init coder style")
        print("Load defaults")
        let savedUnit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "imperial"
        print("Loaded default temperature unit: \(savedUnit)")
        apiUnit = savedUnit
        let savedEndpoint = UserDefaults.standard.string(forKey: "endpoint") ?? "weather"
        print("Loaded default endpoint: \(savedEndpoint)")
        apiEndpoint = savedEndpoint
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateFonts()
        
        // set view controller delegate in app delegate
        //let appDelegate: AppDelegate = UIApplication.shared.delegate! as! AppDelegate
        //appDelegate.myViewController = self
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        backgroundView.layer.addSublayer(gradientLayer)
        setBlueGradientBackground()
        
        let indicatorSize: CGFloat = 70
        let indicatorFrame = CGRect(x: (view.frame.width-indicatorSize)/2, y: (view.frame.height-indicatorSize)/2, width: indicatorSize, height: indicatorSize)
        activityIndicator = NVActivityIndicatorView(frame: indicatorFrame, type: .lineScale, color: UIColor.white, padding: 20.0)
        activityIndicator.backgroundColor = UIColor.black
        view.addSubview(activityIndicator)
        
        locationManager.requestWhenInUseAuthorization()
        
        updateItemsVisibility(isHidden: true)
        
        let metricLabelTap = UITapGestureRecognizer(target: self, action: #selector(self.metricLabelTapped(_:)))
        self.metricLabel.isUserInteractionEnabled = true
        self.metricLabel.addGestureRecognizer(metricLabelTap)
        
        let imperialLabelTap = UITapGestureRecognizer(target: self, action: #selector(self.imperialLabelTapped(_:)))
        self.imperialLabel.isUserInteractionEnabled = true
        self.imperialLabel.addGestureRecognizer(imperialLabelTap)
        
        let todayLabelTap = UITapGestureRecognizer(target: self, action: #selector(self.todayLabelTapped(_:)))
        self.dayLabel.isUserInteractionEnabled = true
        self.dayLabel.addGestureRecognizer(todayLabelTap)
        
        let tomorrowLabelTap = UITapGestureRecognizer(target: self, action: #selector(self.tomorrowLabelTapped(_:)))
        self.tomorrowLabel.isUserInteractionEnabled = true
        self.tomorrowLabel.addGestureRecognizer(tomorrowLabelTap)
        
        reloadView()
    }
    
    func reloadView() {
        print("Reload the view.")
        updateItemsVisibility(isHidden: true)
        self.activityIndicator.startAnimating()
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            
            locationManager.startUpdatingLocation()
        }
        // Make the native ad view container visible.
        self.adView.isHidden = true
        
        loadBannerAd()
    }
    
    func updateItemsVisibility(isHidden: Bool) {
        self.conditionImageView.isHidden = isHidden
        self.dayLabel.isHidden = isHidden
        self.tomorrowLabel.isHidden = isHidden
        self.temperatureLabel.isHidden = isHidden
        self.locationLabel.isHidden = isHidden
        self.conditionLabel.isHidden = isHidden
        self.temperatureLabel.isHidden = isHidden
        self.metricLabel.isHidden = isHidden
        self.imperialLabel.isHidden = isHidden
        self.nowLabel.isHidden = isHidden
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        lat = location.coordinate.latitude
        lon = location.coordinate.longitude
        print("lat: \(lat)")
        print("lat: \(lon)")
        
        let endpoint = self.apiEndpoint
        var jsonResponse: JSON
        
        let geocoder = CLGeocoder()
        
        // Look up the location and pass it to the completion handler
        geocoder.reverseGeocodeLocation(location,
                    completionHandler: { (placemarks, error) in
            if error == nil {
                self.locationLabel.text = placemarks?[0].locality
                //self.locationLabel.text = "New York"
            } else {
                print("Failed to get location placemarks")
                self.locationLabel.text = "Failed to get location placemark"
            }
            self.locationLabel.isHidden = false
        })
        
        let todayDate = Date()
        let nowTimestamp = Int(todayDate.timeIntervalSince1970)
        
        if ((self.apiUnit == "imperial" && self.apiEndpoint == "forecast" && cachedForecastF != nil && nowTimestamp - lastForecastCallTimestampF <  3600) ||
            (self.apiUnit == "metric" && self.apiEndpoint == "forecast" && cachedForecastC != nil && nowTimestamp - lastForecastCallTimestampC <  3600) ||
            (self.apiUnit == "imperial" && self.apiEndpoint == "weather" && cachedWeatherF != nil &&
            nowTimestamp - lastWeatherCallTimestampF < 3600) ||
            (self.apiUnit == "metric" && self.apiEndpoint == "weather" && cachedWeatherC != nil &&
                nowTimestamp - lastWeatherCallTimestampC < 3600)) {
            if (self.apiUnit == "imperial") {
                jsonResponse = (self.apiEndpoint == "forecast") ? cachedForecastF! : cachedWeatherF!
            } else {
                jsonResponse = (self.apiEndpoint == "forecast") ? cachedForecastC! : cachedWeatherC!
            }
            print("Using cached value")
            
            self.updateWeather(json: jsonResponse)
            return
        }
    Alamofire.request("http://api.openweathermap.org/data/2.5/\(endpoint)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=\(apiUnit)").responseJSON {
          response in
        if let responseStr = response.result.value {
            print("Calling weather service")
            let jsonResponse = JSON(responseStr)
            // cache result to reduce number of service calls
            if (self.apiEndpoint == "forecast") {
                if (self.apiUnit == "imperial") {
                    self.cachedForecastF = jsonResponse
                    self.lastForecastCallTimestampF = nowTimestamp
                } else {
                    self.cachedForecastC = jsonResponse
                    self.lastForecastCallTimestampC = nowTimestamp
                }
            } else {
                if (self.apiUnit == "imperial") {
                    self.cachedWeatherF = jsonResponse
                    self.lastWeatherCallTimestampF = nowTimestamp
                } else {
                    self.cachedWeatherC = jsonResponse
                    self.lastWeatherCallTimestampC = nowTimestamp
                }
            }
            self.updateWeather(json: jsonResponse)
        }
        }
    }
    
    func updateWeather(json: JSON) {
        var jsonResponse = json
        let dateFormatter = DateFormatter()
        let todayDate = Date()
        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: todayDate)!
        
        var dt : JSON!
        if (self.apiEndpoint == "forecast") {
            dateFormatter.dateFormat = "HH"
            for weatherInstance in jsonResponse["list"].array! {
                //print("Iterate jsonResponse")
                dt = weatherInstance["dt"]
                //print(weatherInstance)
                jsonResponse = weatherInstance
                let date = Date(timeIntervalSince1970: TimeInterval(dt.int32Value))
                print(Int(dateFormatter.string(from: date))!)
                if (!Calendar.current.isDate(todayDate, inSameDayAs: date) && Int(dateFormatter.string(from: date))! >= 12) {
                        break
                }
            }
        } else {
            dt = jsonResponse["dt"]
        }
            
        let jsonWeather = jsonResponse["weather"].array![0]
        let jsonTemp = jsonResponse["main"]
        let iconName = jsonWeather["icon"].stringValue
            
        //print(iconName)
            
        self.conditionImageView.image = UIImage(named: iconName)
        self.conditionLabel.text = jsonWeather["main"].stringValue + " (" + jsonWeather["description"].stringValue + ")"
            
        print(jsonResponse["name"].stringValue);
            
        self.temperatureLabel.text = "\(Int(round(jsonTemp["temp"].doubleValue)))"
        //self.temperatureLabel.text = "18"
        //self.conditionLabel.text = "Snow"
            
        dateFormatter.dateFormat = "EEEE"
            
        self.dayLabel.text = dateFormatter.string(from: todayDate)
        self.tomorrowLabel.text = dateFormatter.string(from: tomorrowDate)
        let suffix = iconName.suffix(1)
        if (suffix == "n") {
            setGrayGraidentBackground()
        } else {
            setBlueGradientBackground()
        }
            
        // update time
        dateFormatter.dateFormat = "HH:mm"
        let returnedDate = Date(timeIntervalSince1970: TimeInterval(dt.int32Value))
        self.nowLabel.text = dateFormatter.string(from: returnedDate)
            
        self.updateItemsVisibility(isHidden: false)
        locationManager.stopUpdatingLocation()
        self.activityIndicator.stopAnimating()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func setBlueGradientBackground() {
        let topColor = UIColor.init(red: 95.0/255.0, green: 145.0/255.0, blue: 1.0/255.0, alpha: 1.0).cgColor
        let bottomColor = UIColor.init(red: 72.0/255.0, green: 114.0/255.0, blue: 214.0/255.0, alpha: 1.0).cgColor
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [topColor, bottomColor]
    }
    
    func setGrayGraidentBackground() {
        let topColor = UIColor.init(red: 151.0/255.0, green: 151.0/255.0, blue: 151.0/255.0, alpha: 1.0).cgColor
        let bottomColor = UIColor.init(red: 72.0/255.0, green: 72.0/255.0, blue: 72.0/255.0, alpha: 1.0).cgColor
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [topColor, bottomColor]
    }
    
    func loadBannerAd() {
        self.bannerAdView = FBAdView(placementID: "238958210103121_434570523875221", adSize: kFBAdSizeHeight90Banner, rootViewController: self)
        self.bannerAdView.frame = CGRect(x: 0, y: adView.bounds.height - bannerAdView.frame.size.height, width: bannerAdView.frame.size.width, height: bannerAdView.frame.size.height)
        self.bannerAdView.delegate = self
        self.adView.addSubview(self.bannerAdView)
        self.bannerAdView.loadAd()
        self.adView.isHidden = true
    }
    
    func adViewDidLoad(_ adView: FBAdView) {
        self.adView.isHidden = false
    }
     
    func nativeAd(_ nativeAd: FBNativeAd, didFailWithError error: Error) {
        print("Failed to load ad")
        print(error)
    }
    
    func nativeAdDidClick(_ nativeAd: FBNativeAd) {
        print("Did tap on the ad")
    }
    
    func updateUserDefaults() {
        print("Update defaults")
        print("Updating default temperature unit: \(self.apiUnit)")
        UserDefaults.standard.set(self.apiUnit, forKey: "temperatureUnit")
        UserDefaults.standard.set(self.apiEndpoint, forKey: "endpoint")
    }
    
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        print("Active")
        self.reloadView()
    }
    
    func updateFonts() {
      self.imperialLabel.font = (self.apiUnit == "metric") ? self.notSelectedItemFont : self.selectedItemFont
      self.metricLabel.font = (self.apiUnit == "metric") ? self.selectedItemFont : self.notSelectedItemFont
      

      self.dayLabel.font = (self.apiEndpoint == "forecast") ? self.notSelectedItemFont : self.selectedItemFont
      self.tomorrowLabel.font = (self.apiEndpoint == "forecast") ? self.selectedItemFont : self.notSelectedItemFont
    }
    
    @objc func metricLabelTapped(_ sender: UITapGestureRecognizer) {
        if (self.activityIndicator.isAnimating) {
            // ignore until previous action is not completed
            return
        }
        print("metricLabelTapped")
        self.apiUnit = "metric"
        updateFonts()
        
        updateUserDefaults()
        
        reloadView()
    }
    
    @objc func imperialLabelTapped(_ sender: UITapGestureRecognizer) {
        if (self.activityIndicator.isAnimating) {
            // ignore until previous action is not completed
            return
        }
        print("imperialLabelTapped")
        self.apiUnit = "imperial"
        updateFonts()
        
        updateUserDefaults()
        
        reloadView()
    }
    
    @objc func todayLabelTapped(_ sender: UITapGestureRecognizer) {
        if (self.activityIndicator.isAnimating) {
            // ignore until previous action is not completed
            return
        }
        print("todayLabelTapped")
        self.apiEndpoint = "weather"
        updateFonts()
        
        updateUserDefaults()
        
        reloadView()
    }
    
    @objc func tomorrowLabelTapped(_ sender: UITapGestureRecognizer) {
        if (self.activityIndicator.isAnimating) {
            // ignore until previous action is not completed
            return
        }
        print("tomorrowLabelTapped")
        self.apiEndpoint = "forecast"
        updateFonts()
        
        updateUserDefaults()
        
        reloadView()
    }
}

