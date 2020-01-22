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

class ViewController: UIViewController, CLLocationManagerDelegate, FBAdViewDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchButtonText: UIButton!
    
    @IBOutlet weak var searchCityLabel: UILabel!
    @IBOutlet weak var searchCitiesTableView: UITableView!
    
    @IBOutlet weak var currentLocationButton: UIButton!
    var selectedItem: JSON? = nil
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var tomorrowLabel: UILabel!
    
    @IBOutlet weak var time1: UILabel!
    @IBOutlet weak var time2: UILabel!
    @IBOutlet weak var time3: UILabel!
    
    @IBOutlet weak var conditionSmall1: UIImageView!
    @IBOutlet weak var conditionSmall2: UIImageView!
    @IBOutlet weak var conditionSmall3: UIImageView!
    
    
    @IBOutlet weak var sunriseLabel: UILabel!
    @IBOutlet weak var sunsetLabel: UILabel!
    
    @IBOutlet weak var windLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var pressureLabel: UILabel!
    
    
    @IBOutlet weak var conditionImageView: UIImageView!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var metricLabel: UILabel!
    @IBOutlet weak var imperialLabel: UILabel!
    
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var nowLabel: UILabel!
    
    @IBOutlet weak var citySearchInputText: UITextField!
    
    var citiesDict = [[String]]()
    var matchingCitiesDict = [[String]]()
    var matchingCities: [String] = Array()
    //var possibleMatches: [JSON] = []
    
    var apiUnit: String
    var apiEndpoint: String
    var bannerAdView: FBAdView!
    
    let gradientLayer = CAGradientLayer()
    let selectedGradientLayer = CAGradientLayer()
    
    let selectedItemFont = UIFont(name: "Arial Rounded MT Bold", size: 28)
    let notSelectedItemFont = UIFont(name: "Avenir", size: 20)
    
    let apiKey = "d9f9f29395c8b71049a8e921c9e89748"
    var lat = 50.049683
    var lon = 19.944544
    var activityIndicator: NVActivityIndicatorView!
    let locationManager = CLLocationManager()
    
    /*var cachedForecastC : JSON? = nil
    var lastForecastCallTimestampC = 0
    var cachedForecastF : JSON? = nil
    var lastForecastCallTimestampF = 0
    var cachedWeatherC : JSON? = nil
    var lastWeatherCallTimestampC = 0
    var cachedWeatherF : JSON? = nil
    var lastWeatherCallTimestampF = 0*/
    
    var time1JSON: JSON?
    var time2JSON: JSON?
    var time3JSON: JSON?
    
    
    @IBOutlet weak var additionalInfoLabel1: UILabel!
    @IBOutlet weak var additionalInfoLabel2: UILabel!
    
    var timezone = 0
    
    var shouldCheckLocation = true
    
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
        
        let fileContent = readDataFromFile(file: "worldcities")
        //print(fileContent)
        
        //let content = "eddy,chung,loves,swift\nsecond,line,of, text" //string with CSV file content
        let parsedCSV: [[String]] = fileContent!.components(separatedBy: "\n").map{ $0.components(separatedBy: ",") }

        print(parsedCSV[5][1])
        citiesDict = parsedCSV
        
        citySearchInputText.delegate = self
        citySearchInputText.addTarget(self, action: #selector(searchRecords(_ :)), for: .editingChanged)
        
        searchCitiesTableView.delegate = self
        searchCitiesTableView.dataSource = self
        
        citySearchInputText.isHidden = true
        searchCityLabel.isHidden = true
        currentLocationButton.isHidden = true
        searchCitiesTableView.isHidden = true
        
        updateDayFonts()
        
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
        
        let searchButtonTap = UITapGestureRecognizer(target: self, action: #selector(self.searchButtonTapped(_:)))
        self.searchButton.isUserInteractionEnabled = true
        self.searchButton.addGestureRecognizer(searchButtonTap)
        
        let searchButtonTextTap = UITapGestureRecognizer(target: self, action: #selector(self.searchButtonTapped(_:)))
        self.searchButtonText.isUserInteractionEnabled = true
        self.searchButtonText.addGestureRecognizer(searchButtonTextTap)
        
        let currentLocationButtonTap = UITapGestureRecognizer(target: self, action: #selector(self.currentLocationButtonTapped(_:)))
        self.currentLocationButton.isUserInteractionEnabled = true
        self.currentLocationButton.addGestureRecognizer(currentLocationButtonTap)
        
        // label taps
        let time1LabelT = UITapGestureRecognizer(target: self, action: #selector(self.time1LabelTap(_:)))
        let time1LabelT2 = UITapGestureRecognizer(target: self, action: #selector(self.time1LabelTap(_:)))
        
        self.time1.isUserInteractionEnabled = true
        self.time1.addGestureRecognizer(time1LabelT)
        self.conditionSmall1.isUserInteractionEnabled = true
        self.conditionSmall1.addGestureRecognizer(time1LabelT2)
        
        let time2LabelT = UITapGestureRecognizer(target: self, action: #selector(self.time2LabelTap(_:)))
        let time2LabelT2 = UITapGestureRecognizer(target: self, action: #selector(self.time2LabelTap(_:)))
        
        self.time2.isUserInteractionEnabled = true
        self.time2.addGestureRecognizer(time2LabelT)
        self.conditionSmall2.isUserInteractionEnabled = true
        self.conditionSmall2.addGestureRecognizer(time2LabelT2)
        
        let time3LabelT = UITapGestureRecognizer(target: self, action: #selector(self.time3LabelTap(_:)))
        let time3LabelT2 = UITapGestureRecognizer(target: self, action: #selector(self.time3LabelTap(_:)))
        
        self.time3.isUserInteractionEnabled = true
        self.time3.addGestureRecognizer(time3LabelT)
        self.conditionSmall3.isUserInteractionEnabled = true
        self.conditionSmall3.addGestureRecognizer(time3LabelT2)
        
        reloadView()
        
        // Make the native ad view container visible.
        self.adView.isHidden = true
        
        loadBannerAd()
    }
    
    @objc func searchRecords(_ textField: UITextField) {
        self.matchingCitiesDict.removeAll()
        self.matchingCities.removeAll()
        
        if citySearchInputText.text?.count != 0 {
            for city in citiesDict {
                if let cityToSearch = textField.text {
                    if (city.count > 1) {
                      let location = city[1] + " - " + city[4]
                      let range = location.lowercased().range(of: cityToSearch, options: .caseInsensitive, range: nil, locale: nil)
                      if range != nil {
                        self.matchingCities.append(location)
                        self.matchingCitiesDict.append(city)
                      }
                    }
                }
            }
        } else {
            for city in citiesDict {
                if (city.count > 1) {
                  let location = city[1] + " - " + city[4]
                  self.matchingCities.append(location)
                  self.matchingCitiesDict.append(city)
                }
            }
        }
        
        searchCitiesTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingCities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "City")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "City")
        }
        cell?.textLabel?.text = matchingCities[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        print("Selected Row: \(indexPath.row)")
        
        citySearchInputText.isHidden = true
        searchCitiesTableView.isHidden = true
        searchCityLabel.isHidden = true
        currentLocationButton.isHidden = true
        updateItemsVisibility(isHidden: false)
        clearCache()
        
        let selectedRow = matchingCitiesDict[indexPath.row]
        
        self.lat = Double.init(String(selectedRow[2]))!
        self.lon = Double.init(String(selectedRow[3]))!
        
        shouldCheckLocation = false
        locationLabel.text = selectedRow[1]
        updateWeather(location: nil)
        
        citySearchInputText.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func readDataFromFile(file: String)-> String! {
        // File location
        let fileURLProject = Bundle.main.path(forResource: file, ofType: "csv")
        // Read from the file
        var readStringProject = ""
        do {
            readStringProject = try String(contentsOfFile: fileURLProject!, encoding: String.Encoding.utf8)
        } catch let error as NSError {
             print("Failed reading from URL: \(file), Error: " + error.localizedDescription)
        }
        return readStringProject
    }
    
    func reloadView() {
        print("Reload the view.")
        updateItemsVisibility(isHidden: true)
        updateConditionComponents(isHidden: true)
        self.dayLabel.isHidden = true
        
        self.activityIndicator.startAnimating()
        if (!shouldCheckLocation) {
          updateWeather(location: nil)
        } else if (shouldCheckLocation && CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            
            locationManager.startUpdatingLocation()
        }
    }
    
    func updateItemsVisibility(isHidden: Bool) {
        self.conditionImageView.isHidden = isHidden
        self.tomorrowLabel.isHidden = isHidden
        self.temperatureLabel.isHidden = isHidden
        self.locationLabel.isHidden = isHidden
        self.conditionLabel.isHidden = isHidden
        self.temperatureLabel.isHidden = isHidden
        self.metricLabel.isHidden = isHidden
        self.imperialLabel.isHidden = isHidden
        self.searchButton.isHidden = isHidden
        self.searchButtonText.isHidden = isHidden
        
        self.windLabel.isHidden = isHidden
        self.pressureLabel.isHidden = isHidden
        self.humidityLabel.isHidden = isHidden
        self.additionalInfoLabel1.isHidden = isHidden
        self.additionalInfoLabel2.isHidden = isHidden
        
        self.sunriseLabel.isHidden = isHidden
        self.sunsetLabel.isHidden = isHidden
        //updateConditionComponents(isHidden: isHidden)
    }
    
    func updateConditionComponents(isHidden: Bool) {
        self.time1.isHidden = isHidden
        self.conditionSmall1.isHidden = isHidden
        self.time2.isHidden = isHidden
        self.conditionSmall2.isHidden = isHidden
        self.time3.isHidden = isHidden
        self.conditionSmall3.isHidden = isHidden
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      let location = locations[0]
      lat = location.coordinate.latitude
      lon = location.coordinate.longitude
      print("lat: \(lat)")
      print("lat: \(lon)")
      updateWeather(location: location)
    }
    
    
    func updateWeather(location: CLLocation?) {
        let endpoint = "forecast" //always query forecast endpoint
        var jsonResponse: JSON
        
        let geocoder = CLGeocoder()
        
        if (location != nil) {
        // Look up the location and pass it to the completion handler
        geocoder.reverseGeocodeLocation(location!,
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
        }
        
        //let todayDate = Date()
        //let nowTimestamp = Int(todayDate.timeIntervalSince1970)
        
        /*if (shouldCheckLocation && (self.apiUnit == "imperial" && self.apiEndpoint == "forecast" && cachedForecastF != nil && nowTimestamp - lastForecastCallTimestampF <  3600) ||
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
            
            // disable cache for now!!
            //self.updateWeather(json: jsonResponse)
            //return
        }*/
    Alamofire.request("http://api.openweathermap.org/data/2.5/\(endpoint)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=\(apiUnit)").responseJSON {
          response in
        if let responseStr = response.result.value {
            print("Calling weather service")
            let jsonResponse = JSON(responseStr)
            self.timezone = jsonResponse["city"]["timezone"].int!
            // cache result to reduce number of service calls
            /*if (self.apiEndpoint == "forecast") {
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
            }*/
            
            self.updateWeather(json: jsonResponse)
        }
        }
    }
    
    func updateWeather(json: JSON) {
        let jsonResponse = json
        
        //print(json)
        let dateFormatter = DateFormatter()
        var todayDate = Date()
        let timezoneOffset =  TimeZone.current.secondsFromGMT()
        let currentTime = Int(todayDate.timeIntervalSince1970)
        
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "hh:ss a"
        
        self.sunsetLabel.text = "Sunset: " + dayTimePeriodFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(json["city"]["sunset"].intValue + self.timezone - timezoneOffset)) as Date)
        self.sunriseLabel.text = "Sunrise: " + dayTimePeriodFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(json["city"]["sunrise"].intValue + self.timezone - timezoneOffset)) as Date)
        
        updateItemsVisibility(isHidden: false)
        updateConditionComponents(isHidden: true)
        
        self.time1JSON = nil
        self.time2JSON = nil
        self.time3JSON = nil
        
        print("UPDATE WEATHER!!")
        
        var dt : JSON!
        dateFormatter.dateFormat = "HH"
        var i = 0
        
        var rowsForToday = 0
        //print("today date")
        //print(todayDate.timeIntervalSince1970)
        todayDate = Date(timeIntervalSince1970: TimeInterval(currentTime))
        for weatherInstance in jsonResponse["list"].array! {
          //print("Iterate jsonResponse")
          dt = weatherInstance["dt"]
          /*let t1 = dt.int32Value + Int32(self.timezone) - Int32(timezoneOffset)
          let date = Date(timeIntervalSince1970: TimeInterval(t1))
          let currentDate = Date(timeIntervalSince1970: TimeInterval(todayDate.timeIntervalSince1970 - Double(timezoneOffset)))
          if (Calendar.current.isDate(currentDate, inSameDayAs: date)) {
            rowsForToday += 1
          }*/
          
          let t1 = dt.intValue + Int(self.timezone) - Int(timezoneOffset)
          //print("timezoneOffset")
          //print(timezoneOffset)
          var date = NSDate(timeIntervalSince1970: TimeInterval(t1))
          //print("today's date")
          //print(dayTimePeriodFormatter.string(from: todayDate as Date))
          dayTimePeriodFormatter.dateFormat = "dd"
          //print(t1)
          //print(dayTimePeriodFormatter.string(from: date as Date))
          if (dayTimePeriodFormatter.string(from: date as Date) == dayTimePeriodFormatter.string(from: todayDate as Date)) {
                //print(t1)
                //print(dayTimePeriodFormatter.string(from: date as Date) + " " + dayTimePeriodFormatter.string(from: todayDate as Date))
            rowsForToday += 1
          }
        }
        
        print("Rows For Today")
        print(rowsForToday)
        
        /*let t1 = todayDate.timeIntervalSince1970 + Double(self.timezone) - Double(timezoneOffset)
        todayDate = Date(timeIntervalSince1970: t1)*/

        var selectedFound = false
        
        self.time1.layer.cornerRadius = 0
        self.time1.backgroundColor = nil
        self.time1.clipsToBounds = false
        
        self.time2.layer.cornerRadius = 0
        self.time2.backgroundColor = nil
        self.time2.clipsToBounds = false
        
        self.time3.layer.cornerRadius = 0
        self.time3.backgroundColor = nil
        self.time3.clipsToBounds = false
        
        for weatherInstance in jsonResponse["list"].array! {
            //print("Iterate jsonResponse")
            dt = weatherInstance["dt"]
            //print(weatherInstance)
            
            let t1 = dt.int32Value + Int32(self.timezone)
            let date = Date(timeIntervalSince1970: TimeInterval(t1))
            
            let dayTimePeriodFormatter = DateFormatter()
            dayTimePeriodFormatter.dateFormat = "dd"
            
            //print(Int(dateFormatter.string(from: date))!)
            if (self.apiEndpoint == "forecast" && /*!Calendar.current.isDate(todayDate, inSameDayAs: date)*/ Int(dayTimePeriodFormatter.string(from: date as Date))! > Int(dayTimePeriodFormatter.string(from: todayDate))!) {
                if (i % 2 == 1 && (i / 2) + 1 <= 3) {
                  fillCondition(index: (i / 2) + 1, conditionJSON: weatherInstance, selected: Int(dateFormatter.string(from: date))! >= 10 && !selectedFound)
                  if (Int(dateFormatter.string(from: date))! >= 10) {
                    selectedFound = true
                  }
                }
                i = i + 1
            } else if (self.apiEndpoint == "weather" && /*Calendar.current.isDate(todayDate, inSameDayAs: date)*/ Int(dayTimePeriodFormatter.string(from: date as Date)) == Int(dayTimePeriodFormatter.string(from: todayDate))! &&
                rowsForToday >= 1
            ) {
                //print(i)
                if (rowsForToday > 4) {
                    if (i % 2 == 0) {
                      fillCondition(index: (i / 2) + 1, conditionJSON: weatherInstance, selected: ((i / 2) + 1 == 1))
                    }
                } else if (i < rowsForToday) {
                    fillCondition(index: i + 1, conditionJSON: weatherInstance, selected: (i == 0))
                }
                i = i + 1
            } else if (self.apiEndpoint == "weather" && rowsForToday < 1) {
                dayLabel.isHidden = (rowsForToday < 1)
                tomorrowLabelTapped(UITapGestureRecognizer.init())
                break
            }
        }
        
        dayLabel.isHidden = (rowsForToday < 1)
            
        // update time
        //dateFormatter.dateFormat = "HH:mm"
        //let returnedDate = Date(timeIntervalSince1970: TimeInterval(dt.int32Value))
        //self.nowLabel.text = dateFormatter.string(from: returnedDate)

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
    
    func setSelectedBackground(imageView: UIImageView) {
        let topColor = UIColor.init(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.15)
        imageView.layer.cornerRadius = 30
        imageView.clipsToBounds = true
        imageView.backgroundColor = topColor
    }
    
    func setGrayGraidentBackground() {
        let topColor = UIColor.init(red: 151.0/255.0, green: 151.0/255.0, blue: 151.0/255.0, alpha: 1.0).cgColor
        let bottomColor = UIColor.init(red: 72.0/255.0, green: 72.0/255.0, blue: 72.0/255.0, alpha: 1.0).cgColor
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [topColor, bottomColor]
    }
    
    func loadBannerAd() {
        self.bannerAdView = FBAdView(placementID: "639765523432024_639766196765290", adSize: kFBAdSizeHeight90Banner, rootViewController: self)
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
        //print("Update defaults")
        //print("Updating default temperature unit: \(self.apiUnit)")
        UserDefaults.standard.set(self.apiUnit, forKey: "temperatureUnit")
        UserDefaults.standard.set(self.apiEndpoint, forKey: "endpoint")
    }
    
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        //print("Active")
        
        // default to old view
        citySearchInputText.isHidden = true
        searchCityLabel.isHidden = true
        currentLocationButton.isHidden = true
        
        self.reloadView()
    }
    
    func updateDayFonts() {
      let topColor = UIColor.init(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.15)
      self.imperialLabel.font = (self.apiUnit == "metric") ? self.notSelectedItemFont : self.selectedItemFont
        if (self.apiUnit == "metric") {
            self.imperialLabel.layer.cornerRadius = 0
            self.imperialLabel.backgroundColor = nil
            self.imperialLabel.clipsToBounds = false
            
            self.metricLabel.layer.cornerRadius = 10
            self.metricLabel.backgroundColor = topColor
            self.metricLabel.clipsToBounds = true
        } else {
            self.imperialLabel.layer.cornerRadius = 10
            self.imperialLabel.backgroundColor = topColor
            self.imperialLabel.clipsToBounds = true
            
            self.metricLabel.layer.cornerRadius = 0
            self.metricLabel.backgroundColor = nil
            self.metricLabel.clipsToBounds = false
        }
      self.metricLabel.font = (self.apiUnit == "metric") ? self.selectedItemFont : self.notSelectedItemFont
      

      self.dayLabel.font = (self.apiEndpoint == "forecast") ? self.notSelectedItemFont : self.selectedItemFont
      self.tomorrowLabel.font = (self.apiEndpoint == "forecast") ? self.selectedItemFont : self.notSelectedItemFont
        
      if (self.apiEndpoint == "forecast") {
          self.dayLabel.backgroundColor = nil
          self.dayLabel.layer.cornerRadius = 0
          self.dayLabel.clipsToBounds = false
          
          self.tomorrowLabel.layer.cornerRadius = 10
          self.tomorrowLabel.backgroundColor = topColor
          self.tomorrowLabel.clipsToBounds = true
      } else {
          self.dayLabel.layer.cornerRadius = 10
          self.dayLabel.backgroundColor = topColor
          self.dayLabel.clipsToBounds = true
          
          self.tomorrowLabel.backgroundColor = nil
          self.tomorrowLabel.layer.cornerRadius = 0
          self.tomorrowLabel.clipsToBounds = false
      }
    }
    
    func updateHourFonts(index: Int) {
        self.time1.font = (index == 1) ? self.selectedItemFont : self.notSelectedItemFont
        self.time2.font = (index == 2) ? self.selectedItemFont : self.notSelectedItemFont
        self.time3.font = (index == 3) ? self.selectedItemFont : self.notSelectedItemFont
    }
    
    @objc func metricLabelTapped(_ sender: UITapGestureRecognizer) {
        if (self.activityIndicator.isAnimating) {
            // ignore until previous action is not completed
            return
        }
        //print("metricLabelTapped")
        self.apiUnit = "metric"
        updateDayFonts()
        
        updateUserDefaults()
        
        reloadView()
    }
    
    @objc func imperialLabelTapped(_ sender: UITapGestureRecognizer) {
        if (self.activityIndicator.isAnimating) {
            // ignore until previous action is not completed
            return
        }
        //print("imperialLabelTapped")
        self.apiUnit = "imperial"
        updateDayFonts()
        
        updateUserDefaults()
        
        reloadView()
    }
    
    @objc func time1LabelTap(_ sender: UITapGestureRecognizer) {
        self.time1.layer.cornerRadius = 0
        self.time1.backgroundColor = nil
        self.time1.clipsToBounds = false
        
        self.time2.layer.cornerRadius = 0
        self.time2.backgroundColor = nil
        self.time2.clipsToBounds = false
        
        self.time3.layer.cornerRadius = 0
        self.time3.backgroundColor = nil
        self.time3.clipsToBounds = false
        
        //print("time1 tap")
        if (self.time1JSON != nil) {
          fillCondition(index: 1, conditionJSON: self.time1JSON!, selected: true)
        }
        if (self.time2JSON != nil) {
          fillCondition(index: 2, conditionJSON: self.time2JSON!, selected: false)
        }
        if (self.time3JSON != nil) {
          fillCondition(index: 3, conditionJSON: self.time3JSON!, selected: false)
        }
    }
    
    @objc func time2LabelTap(_ sender: UITapGestureRecognizer) {
        self.time1.layer.cornerRadius = 0
        self.time1.backgroundColor = nil
        self.time1.clipsToBounds = false
        
        self.time2.layer.cornerRadius = 0
        self.time2.backgroundColor = nil
        self.time2.clipsToBounds = false
        
        self.time3.layer.cornerRadius = 0
        self.time3.backgroundColor = nil
        self.time3.clipsToBounds = false
        
        //print("time2 tap")
        if (self.time1JSON != nil) {
          fillCondition(index: 1, conditionJSON: self.time1JSON!, selected: false)
        }
        if (self.time2JSON != nil) {
          fillCondition(index: 2, conditionJSON: self.time2JSON!, selected: true)
        }
        if (self.time3JSON != nil) {
          fillCondition(index: 3, conditionJSON: self.time3JSON!, selected: false)
        }
    }
    
    @objc func time3LabelTap(_ sender: UITapGestureRecognizer) {
        self.time1.layer.cornerRadius = 0
        self.time1.backgroundColor = nil
        self.time1.clipsToBounds = false
        
        self.time2.layer.cornerRadius = 0
        self.time2.backgroundColor = nil
        self.time2.clipsToBounds = false
        
        self.time3.layer.cornerRadius = 0
        self.time3.backgroundColor = nil
        self.time3.clipsToBounds = false
        //print("time3 tap")
        if (self.time1JSON != nil) {
          fillCondition(index: 1, conditionJSON: self.time1JSON!, selected: false)
        }
        if (self.time2JSON != nil) {
          fillCondition(index: 2, conditionJSON: self.time2JSON!, selected: false)
        }
        if (self.time3JSON != nil) {
          fillCondition(index: 3, conditionJSON: self.time3JSON!, selected: true)
        }
    }
    
    @objc func todayLabelTapped(_ sender: UITapGestureRecognizer) {
        if (self.activityIndicator.isAnimating) {
            // ignore until previous action is not completed
            return
        }
        //print("todayLabelTapped")
        self.apiEndpoint = "weather"
        updateDayFonts()
        
        updateUserDefaults()
        
        reloadView()
    }
    
    @objc func tomorrowLabelTapped(_ sender: UITapGestureRecognizer) {
        if (self.activityIndicator.isAnimating) {
            // ignore until previous action is not completed
            return
        }
        //print("tomorrowLabelTapped")
        self.apiEndpoint = "forecast"
        updateDayFonts()
        
        updateUserDefaults()
        
        reloadView()
    }
    
    @objc func searchButtonTapped(_ sender: UITapGestureRecognizer) {
        updateItemsVisibility(isHidden: true)
        updateConditionComponents(isHidden: true)
        self.dayLabel.isHidden = true
        selectedItem = nil
        currentLocationButton.isHidden = false
        citySearchInputText.isHidden = false
        searchCityLabel.isHidden = false
        searchCitiesTableView.isHidden = false
        
        citySearchInputText.text = ""
        searchRecords(citySearchInputText)
    }
    
    @objc func currentLocationButtonTapped(_ sender: UITapGestureRecognizer) {
        selectedItem = nil
        
        citySearchInputText.isHidden = true
        searchCityLabel.isHidden = true
        searchCitiesTableView.isHidden = true
        currentLocationButton.isHidden = true
        citySearchInputText.endEditing(true)
        updateItemsVisibility(isHidden: false)
        citySearchInputText.endEditing(true)
        clearCache()
        
        shouldCheckLocation = true
        reloadView()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        return true
    }
    
    func clearCache() {
        /*cachedForecastC = nil
        cachedForecastF = nil
        cachedWeatherC = nil
        cachedWeatherF = nil*/
    }
    
    func fillCondition(index: Int, conditionJSON: JSON, selected: Bool) {
        var imgView: UIImageView!
        var label: UILabel!
        
        if (index == 1) {
            self.time1JSON = conditionJSON
            imgView = self.conditionSmall1
            label = self.time1
        } else if (index == 2) {
            self.time2JSON = conditionJSON
            imgView = self.conditionSmall2
            label = self.time2
        } else if (index == 3) {
            self.time3JSON = conditionJSON
            imgView = self.conditionSmall3
            label = self.time3
        } else {
            return
        }
        
        imgView.isHidden = false
        label.isHidden = false
        
        let dateFormatter = DateFormatter()
        let todayDate = Date()
        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: todayDate)!
        
        dateFormatter.dateFormat = "HH"
        //print(conditionJSON)
        
        let jsonWeather = conditionJSON["weather"].array![0]
        let jsonTemp = conditionJSON["main"]
        var iconName = jsonWeather["icon"].stringValue
            
        //print(conditionJSON["name"].stringValue);
        let tmp = "\(Int(round(jsonTemp["temp"].doubleValue)))"
        //print("Temperature: ")
        //print(tmp)
            
        if (selected) {
            self.additionalInfoLabel1.text = ""
            self.additionalInfoLabel2.text = ""
            self.temperatureLabel.text = tmp
            self.windLabel.text = "Wind: " + String(format: "%.2f", conditionJSON["wind"]["speed"].doubleValue) + ((self.apiUnit == "imperial") ? " mph" : " m/s")
            self.humidityLabel.text = "Humidity: " + jsonTemp["humidity"].stringValue  + "%"
            self.pressureLabel.text = "Pressure: " + jsonTemp["pressure"].stringValue + " hPa"
            let clouds = conditionJSON["clouds"]["all"].intValue
            let rain = conditionJSON["rain"]["3h"].doubleValue
            let snow = conditionJSON["snow"]["3h"].doubleValue
            //print("Clouds")
            //print(clouds)
            //print(rain)
            if (clouds > 0) {
                self.additionalInfoLabel1.text = "Clouds: " + String(clouds) + "%"
                if (rain > 0.0) {
                    self.additionalInfoLabel2.text = "Rain (3h): " + String(rain) + " mm"
                } else if (snow > 0.0) {
                    self.additionalInfoLabel2.text = "Snow (3h): " + String(snow) + " mm"
                }
            } else {
                if (rain > 0) {
                    self.additionalInfoLabel1.text = "Rain (3h): " + String(rain) + " mm"
                } else if (snow > 0.0) {
                    self.additionalInfoLabel1.text = "Snow (3h): " + String(snow) + " mm"
                }
            }
            setSelectedBackground(imageView: imgView)
            
            let topColor = UIColor.init(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.15)
            label.layer.cornerRadius = 10
            label.backgroundColor = topColor
            label.clipsToBounds = true
        } else {
            imgView.backgroundColor = nil
        }

        dateFormatter.dateFormat = "EEEE"
        self.dayLabel.text = dateFormatter.string(from: todayDate)
        
        let timezoneOffset =  TimeZone.current.secondsFromGMT()
        //print("timezoneOffset")
        //print(timezoneOffset)
        
        var time_dt = conditionJSON["dt"].int!
        //print("DT Time")
        //print(self.timezone)
        //print(time_dt)
        time_dt += self.timezone - timezoneOffset
        
        //self.time1.text = String(self.time1.text!.prefix(5))
        let date = NSDate(timeIntervalSince1970: TimeInterval(time_dt))
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "hh a"
        
        let dateString = dayTimePeriodFormatter.string(from: date as Date)
        label.text = dateString
        
        dayTimePeriodFormatter.dateFormat = "hh"
        let timeString = dayTimePeriodFormatter.string(from: date as Date)
        let timeInt = Int(timeString)!
        
        dayTimePeriodFormatter.dateFormat = "a"
        let timeOfTheDayString = dayTimePeriodFormatter.string(from: date as Date)
        
        self.tomorrowLabel.text = dateFormatter.string(from: tomorrowDate)

        //let suffix = iconName.suffix(1)
        // show night or day background depending on the local time in the place
        var dayOrNight = ""
        if ((timeOfTheDayString == "AM" && timeInt <= 5) || (timeOfTheDayString == "PM" && timeInt >= 9 && timeInt < 12)) {
            dayOrNight = "n"
            if (selected) {
              setGrayGraidentBackground()
            }
        } else {
            dayOrNight = "d"
            if (selected) {
              setBlueGradientBackground()
            }
        }
        
        iconName = iconName.prefix(2) + dayOrNight
        //print("Selected: ")
        //print(selected)
        if (selected) {
          self.conditionImageView.image = UIImage(named: iconName)
          self.conditionLabel.text = jsonWeather["description"].stringValue
          updateHourFonts(index: index)
        }
        iconName = "s_" + iconName
        //print("Icon Name: " + iconName)
        imgView.image = UIImage(named: iconName)
    }
}

