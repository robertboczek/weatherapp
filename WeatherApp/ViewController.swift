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
import AdSupport
import AppTrackingTransparency

import FBAudienceNetwork
import AWSDynamoDB
import GoogleMobileAds

class ViewController: UIViewController, CLLocationManagerDelegate, GADBannerViewDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchButtonText: UIButton!
    
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var favoritesButton: UIButton!
    @IBOutlet weak var favoritesListButton: UIButton!
    
    @IBOutlet weak var searchCityLabel: UILabel!
    @IBOutlet weak var searchCitiesTableView: UITableView!
    
    @IBOutlet weak var favoritiesView: UITableView!
    
    @IBOutlet var mainView: UIView!
    
    @IBOutlet weak var currentLocationButton: UIButton!
    var selectedItem: JSON? = nil
    
    @IBOutlet weak var locationLabel: UILabel!
    var location: String = ""
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var tomorrowLabel: UILabel!
    @IBOutlet weak var dayAfterTomorrowLabel: UILabel!
    
    @IBOutlet weak var goBack: UIButton!
    
    @IBOutlet weak var time1: UILabel!
    @IBOutlet weak var time2: UILabel!
    @IBOutlet weak var time3: UILabel!
    @IBOutlet weak var time4: UILabel!
    @IBOutlet weak var time5: UILabel!
    
    @IBOutlet weak var twelve: UILabel!
    @IBOutlet weak var twentyFour: UILabel!
    
    @IBOutlet weak var conditionSmall1: UIImageView!
    @IBOutlet weak var conditionSmall2: UIImageView!
    @IBOutlet weak var conditionSmall3: UIImageView!
    @IBOutlet weak var conditionSmall4: UIImageView!
    @IBOutlet weak var conditionSmall5: UIImageView!
    
    
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
    var bannerView: GAMBannerView!
    @IBOutlet weak var nowLabel: UILabel!
    
    @IBOutlet weak var citySearchInputText: UITextField!
    
    var citiesDict = [[String]]()
    var matchingCitiesDict = [[String]]()
    var matchingCities: [String] = Array()
    
    // locations added to favorities
    var favoritiesDict = [[String]]()
    
    var apiUnit: String
    var apiEndpoint: String
    var hourFormat: String
    
    let gradientLayer = CAGradientLayer()
    let selectedGradientLayer = CAGradientLayer()
    
    let selectedItemFont = UIFont(name: "Arial Rounded MT Bold", size: 28)
    let notSelectedItemFont = UIFont(name: "Avenir", size: 20)
    
    let selectedHourItemFont = UIFont(name: "Arial Rounded MT Bold", size: 22)
    let notSelectedHourItemFont = UIFont(name: "Avenir", size: 14)
    
    let apiKey = "d9f9f29395c8b71049a8e921c9e89748"

    let dynamoDBKey = "AKIAZDZDLXPYHLZAKH4M"
    let dynamoDBSecret = "dH90a6XUd/1AKWGEC3jaG8T8Tg1jbsJoM/j76I+Z"
    let dynamoDBFavoritesTableName = "YourWeatherAppFavorites"
    let awsEndpointURL = "https://dynamodb.us-east-1.amazonaws.com"
    var uid = ""

    var lat = -1.0
    var lon = -1.0
    var activityIndicator: NVActivityIndicatorView!
    let locationManager = CLLocationManager()
    
    var time1JSON: JSON?
    var time2JSON: JSON?
    var time3JSON: JSON?
    var time4JSON: JSON?
    var time5JSON: JSON?
    var index = 1
    var totalItems = 1
    
    @IBOutlet weak var additionalInfoLabel1: UILabel!
    @IBOutlet weak var additionalInfoLabel2: UILabel!
    
    var timezone = 0
    
    var shouldCheckLocation = true
    var isErrorState = false
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)   {
        print("init")
        print("Load defaults")
        
        FBAdSettings.setAdvertiserTrackingEnabled(true)
        
        let savedUnit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "imperial"
        print("Loaded default temperature unit: \(savedUnit)")
        apiUnit = savedUnit
        let savedEndpoint = UserDefaults.standard.string(forKey: "endpoint") ?? "weather"
        print("Loaded default endpoint: \(savedEndpoint)")
        apiEndpoint = savedEndpoint
        let savedHourFormat = UserDefaults.standard.string(forKey: "hourFormat") ?? "12"
        hourFormat = savedHourFormat
        print("Loaded default hour format: \(savedHourFormat)")
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.registerAWSConfig()
    }
    
    required init?(coder aDecoder: NSCoder) {
        FBAdSettings.setAdvertiserTrackingEnabled(true)
        
        print("init coder style")
        print("Load defaults")
        let savedUnit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "imperial"
        print("Loaded default temperature unit: \(savedUnit)")
        apiUnit = savedUnit
        let savedEndpoint = UserDefaults.standard.string(forKey: "endpoint") ?? "weather"
        print("Loaded default endpoint: \(savedEndpoint)")
        apiEndpoint = savedEndpoint
        let savedHourFormat = UserDefaults.standard.string(forKey: "hourFormat") ?? "12"
        hourFormat = savedHourFormat
        print("Loaded default hour format: \(savedHourFormat)")
        
        super.init(coder: aDecoder)
        
        self.registerAWSConfig()
    }
    
    func registerAWSConfig() {
        print("Registering AWS Provider")
        let credentialProvider = AWSStaticCredentialsProvider.init(accessKey: self.dynamoDBKey, secretKey: self.dynamoDBSecret)
        let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialProvider)
        AWSDynamoDB.register(with: configuration!, forKey: "USEast1DynamoDB")
        
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    // Authorized
                    self.uid = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    self.loadFavoritiesConfig()
                case .denied,
                     .notDetermined,
                     .restricted:
                    break
                @unknown default:
                    break
                }
            }
        }
        
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        print("IDFA " + idfa)
        if idfa != "00000000-0000-0000-0000-000000000000" {
          self.uid = idfa
        }
        self.loadFavoritiesConfig()
    }
    
    func loadFavoritiesConfig() {
        // load favorities
        let savedLocations = UserDefaults.standard.string(forKey: "favoritiesLocations")
        if (savedLocations == nil) {
            self.loadFavoritiesConfigFromAWS()
            return
        }
        self.updateFavorites(savedLocations: savedLocations!)
    }

    func updateFavorites(savedLocations: String) {
        let savedLocationsArray = savedLocations.components(separatedBy: "|")
        self.favoritiesDict = [[String]]()
        for location in savedLocationsArray {
          if (location != "") {
            let locationDetailsArray = location.components(separatedBy: ";")
            self.favoritiesDict.append([locationDetailsArray[0], locationDetailsArray[1], locationDetailsArray[2]])
          }
        }
    }
    
    func loadFavoritiesConfigFromAWS() {
        let dynamoDb = AWSDynamoDB(forKey: "USEast1DynamoDB")
        let uid = self.getUID()
        print("Querying for uid: " + uid)
        if uid == "" {
            return
        }
        self.favoritiesDict = [[String]]()
        // define your primary hash keys
        let hashAttribute1 = AWSDynamoDBAttributeValue()
        hashAttribute1?.s = uid

        let keys: Array = [["uid": hashAttribute1]]
        let keysAndAttributesMap = AWSDynamoDBKeysAndAttributes()
        keysAndAttributesMap?.keys = keys as? [[String : AWSDynamoDBAttributeValue]]
        keysAndAttributesMap?.consistentRead = true
        let tableMap = [self.dynamoDBFavoritesTableName : keysAndAttributesMap]
        let request = AWSDynamoDBBatchGetItemInput()
        request?.requestItems = tableMap as? [String : AWSDynamoDBKeysAndAttributes]
        request?.returnConsumedCapacity = AWSDynamoDBReturnConsumedCapacity.total
        dynamoDb.batchGetItem(request!) { (output, error) in
          if output != nil {
            print("Batch Query output?.responses?.count:", output!.responses!)
            if (output!.responses![self.dynamoDBFavoritesTableName]?.count == 1) {
                self.updateFavorites(savedLocations: output!.responses![self.dynamoDBFavoritesTableName]!.first!["value"]!.s!)
            }
          }
          if error != nil {
            print("Batch Query error:", error!)
          }
        }
    }
    
    func saveFavoritiesToDB(configValueToSave: String) {
        let dynamoDb = AWSDynamoDB(forKey: "USEast1DynamoDB")
        let uid = self.getUID()
        print("UID: " + uid)
        if uid == "" {
            return
        }
        
        let writeRequest = AWSDynamoDBWriteRequest()
        writeRequest?.putRequest = AWSDynamoDBPutRequest()
        let uidAttribute = AWSDynamoDBAttributeValue()
        uidAttribute?.s = uid
        let valueAttribute = AWSDynamoDBAttributeValue()
        valueAttribute?.s = configValueToSave
        writeRequest?.putRequest?.item = ["uid": uidAttribute!, "value": valueAttribute!]
        let batchWriteItemInput = AWSDynamoDBBatchWriteItemInput()
        batchWriteItemInput?.requestItems = [self.dynamoDBFavoritesTableName: [writeRequest!]]
        dynamoDb.batchWriteItem(batchWriteItemInput!).continueWith { (task: AWSTask<AWSDynamoDBBatchWriteItemOutput>) -> Any? in
            if let error = task.error {
              print("The request failed. Error: \(error)")
              return nil
            }
            print("Successfully updated favorites config to Amazon AWS DynamoDB")
            return nil
        }
    }
    
    func getUID() -> String {
        return uid
    }
    
    func saveFavorities() {
        var configString = ""
        self.favoritiesDict = favoritiesDict.sorted { (first, second) -> Bool in
            return first[0] < second[0]
        }
        for favorities in favoritiesDict {
            configString += favorities[0] + ";" + favorities[1] + ";" + favorities[2] + "|"
        }
        print("Saving config:", configString)
        UserDefaults.standard.set(configString, forKey: "favoritiesLocations")
        self.saveFavoritiesToDB(configValueToSave: configString)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerAWSConfig()
        
        let fileContent = readDataFromFile(file: "worldcities")
        
        //let content = "eddy,chung,loves,swift\nsecond,line,of, text" //string with CSV file content
        let parsedCSV: [[String]] = fileContent!.components(separatedBy: "\n").map{ $0.components(separatedBy: ",") }
        citiesDict = parsedCSV
        
        citySearchInputText.delegate = self
        citySearchInputText.addTarget(self, action: #selector(searchRecords(_ :)), for: .editingChanged)
        
        searchCitiesTableView.delegate = self
        searchCitiesTableView.dataSource = self
        
        favoritiesView.delegate = self
        favoritiesView.dataSource = self
        
        citySearchInputText.isHidden = true
        searchCityLabel.isHidden = true
        currentLocationButton.isHidden = true
        searchCitiesTableView.isHidden = true
        
        goBack.isHidden = true
        
        favoritiesView.isHidden = true
        
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
        
        updateItemsVisibility(isHidden: true)
        
        self.conditionLabel.adjustsFontSizeToFitWidth = true
        self.conditionLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        self.conditionLabel.numberOfLines = 0
        
        let addRemoveFavoriteLocationButtonTap = UITapGestureRecognizer(target: self, action: #selector(self.addRemoveFavoriteLocationTap(_:)))
        self.favoritesButton.isUserInteractionEnabled = true
        self.favoritesButton.addGestureRecognizer(addRemoveFavoriteLocationButtonTap)
        
        let mapButtonTap = UITapGestureRecognizer(target: self, action: #selector(self.mapButtonTapped(_:)))
        self.mapButton.isUserInteractionEnabled = true
        self.mapButton.addGestureRecognizer(mapButtonTap)
        
        let favoriteTap = UITapGestureRecognizer(target: self, action: #selector(self.favoriteTapped(_:)))
        self.favoritesListButton.isUserInteractionEnabled = true
        self.favoritesListButton.addGestureRecognizer(favoriteTap)
        
        let goBackTap = UITapGestureRecognizer(target: self, action: #selector(self.goBackTapped(_:)))
        self.goBack.isUserInteractionEnabled = true
        self.goBack.addGestureRecognizer(goBackTap)
        
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
        
        let dayAfterTomorrowLabelTap = UITapGestureRecognizer(target: self, action: #selector(self.dayAfterTomorrowLabelTapped(_:)))
        self.dayAfterTomorrowLabel.isUserInteractionEnabled = true
        self.dayAfterTomorrowLabel.addGestureRecognizer(dayAfterTomorrowLabelTap)
        
        let twentyFourLabelTap = UITapGestureRecognizer(target: self, action: #selector(self.twentyFourLabelTapped(_:)))
        self.twentyFour.isUserInteractionEnabled = true
        self.twentyFour.addGestureRecognizer(twentyFourLabelTap)
        
        let twelveLabelTap = UITapGestureRecognizer(target: self, action: #selector(self.twelveLabelTapped(_:)))
        self.twelve.isUserInteractionEnabled = true
        self.twelve.addGestureRecognizer(twelveLabelTap)
        
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
        
        let time4LabelT = UITapGestureRecognizer(target: self, action: #selector(self.time4LabelTap(_:)))
        let time4LabelT2 = UITapGestureRecognizer(target: self, action: #selector(self.time4LabelTap(_:)))
        
        self.time4.isUserInteractionEnabled = true
        self.time4.addGestureRecognizer(time4LabelT)
        self.conditionSmall4.isUserInteractionEnabled = true
        self.conditionSmall4.addGestureRecognizer(time4LabelT2)
        
        let time5LabelT = UITapGestureRecognizer(target: self, action: #selector(self.time5LabelTap(_:)))
        let time5LabelT2 = UITapGestureRecognizer(target: self, action: #selector(self.time5LabelTap(_:)))
        
        self.time5.isUserInteractionEnabled = true
        self.time5.addGestureRecognizer(time5LabelT)
        self.conditionSmall5.isUserInteractionEnabled = true
        self.conditionSmall5.addGestureRecognizer(time5LabelT2)
        
        // configure right/left swipe gestures
        let left = UISwipeGestureRecognizer(target : self, action : #selector(self.leftSwipe))
        left.direction = .left
        
        let right = UISwipeGestureRecognizer(target : self, action : #selector(self.rightSwipe))
        right.direction = .right
        self.mainView.addGestureRecognizer(right)
        self.mainView.addGestureRecognizer(left)
        
        let down = UISwipeGestureRecognizer(target : self, action : #selector(self.reloadViewConditonal))
        down.direction = .down
        self.mainView.addGestureRecognizer(down)
        
        let favoritesListLabel = NSLocalizedString("favorites list", comment: "Favorites List")
        self.favoritesListButton.setTitle(favoritesListLabel, for: .normal)
        
        updatePreferredHourFormat()
        
        checkAuthorizationStatus()
        reloadView()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            if self.activityIndicator.isAnimating && self.location == "" {
                self.handleLocationLookupError()
            }
        }
        
        // Make the native ad view container visible.
        self.adView.isHidden = true
        
        loadBannerAd()
    }
    
    func checkAuthorizationStatus() {
        let status = CLLocationManager.authorizationStatus()
        print(status.rawValue)
        switch status {
          // 1
          case .notDetermined:
            if (shouldCheckLocation) {
              locationManager.requestWhenInUseAuthorization()
            }
          break
          // 2
        case .restricted, .denied:
            handleLocationLookupError()
            return
          default:
          break
        }
    }
    
    @objc
    func leftSwipe() {
        resetSmallItems()
        self.index = self.index % self.totalItems + 1
        fillCondition(index: 1, conditionJSON: self.time1JSON, selected: self.index == 1)
        fillCondition(index: 2, conditionJSON: self.time2JSON, selected: self.index == 2)
        fillCondition(index: 3, conditionJSON: self.time3JSON, selected: self.index == 3)
        fillCondition(index: 4, conditionJSON: self.time4JSON, selected: self.index == 4)
        fillCondition(index: 5, conditionJSON: self.time5JSON, selected: self.index == 5)
    }
    
    @objc
    func rightSwipe() {
        resetSmallItems()
        self.index = (self.index - 2) % self.totalItems + 1
        if (self.index == 0) {
            self.index = self.totalItems
        }
        fillCondition(index: 1, conditionJSON: self.time1JSON, selected: self.index == 1)
        fillCondition(index: 2, conditionJSON: self.time2JSON, selected: self.index == 2)
        fillCondition(index: 3, conditionJSON: self.time3JSON, selected: self.index == 3)
        fillCondition(index: 4, conditionJSON: self.time4JSON, selected: self.index == 4)
        fillCondition(index: 5, conditionJSON: self.time5JSON, selected: self.index == 5)
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
        if (tableView == self.favoritiesView) {
            return self.favoritiesDict.count
        }
        
        return matchingCities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (tableView == self.favoritiesView) {
            var cell = tableView.dequeueReusableCell(withIdentifier: "City")
            if cell == nil {
                cell = UITableViewCell(style: .default, reuseIdentifier: "City")
            }
            
            let location = self.favoritiesDict[indexPath.row]
            
            cell?.textLabel?.text = location[0]
            return cell!
        }
        var cell = tableView.dequeueReusableCell(withIdentifier: "City")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "City")
        }
        cell?.textLabel?.text = matchingCities[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        goBack.isHidden = true
        if (tableView == self.favoritiesView) {
            updateItemsVisibility(isHidden: true)
            
            currentLocationButton.isHidden = true
            self.favoritiesView.isHidden = true
            
            let location = self.favoritiesDict[indexPath.row]
            self.location = location[0]
            updateLocationLabel()
            self.lat = Double(location[1])!
            self.lon = Double(location[2])!
            
            self.shouldCheckLocation = false
            updateWeather(location: nil)
            return
        }
        
        print("Selected Row: \(indexPath.row)")
        
        citySearchInputText.isHidden = true
        searchCitiesTableView.isHidden = true
        searchCityLabel.isHidden = true
        currentLocationButton.isHidden = true
        updateItemsVisibility(isHidden: false)
        
        let selectedRow = matchingCitiesDict[indexPath.row]
        
        self.lat = Double.init(String(selectedRow[2]))!
        self.lon = Double.init(String(selectedRow[3]))!
        
        shouldCheckLocation = false
        self.location = selectedRow[1]
        updateLocationLabel()
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
    
    @objc
    func reloadViewConditonal() {
        // reload weather view only if main view is visible
        if (self.conditionImageView.isHidden == false) {
          reloadView()
        }
    }
    
    @objc
    func reloadView() {
        print("Reload the view.")
        
        updateSearchScreenItemsVisibility(isHidden: true)
        updateFavoritesScreenItemsVisibility(isHidden: true)
        
        updateItemsVisibility(isHidden: true)
        self.goBack.isHidden = true
        self.dayLabel.isHidden = true
        
        reloadWeatherDetails()
    }
    
    func reloadWeatherDetails() {
        if (!shouldCheckLocation) {
          self.activityIndicator.startAnimating()
          updateWeather(location: nil)
        } else if (shouldCheckLocation && CLLocationManager.locationServicesEnabled()) {
            print("Requesting location!")
            let status = CLLocationManager.authorizationStatus()
            if status == .denied || status == .restricted {
              handleLocationLookupError()
            } else {
              self.activityIndicator.startAnimating()
              locationManager.delegate = self
              locationManager.desiredAccuracy = kCLLocationAccuracyBest
            
              locationManager.pausesLocationUpdatesAutomatically = false
              locationManager.startUpdatingLocation()
            }
        }
    }
    
    func updateMainScreenItemsVisibility(isHidden: Bool) {
        self.conditionImageView.isHidden = isHidden
        self.nowLabel.isHidden = isHidden
        self.dayLabel.isHidden = isHidden
        self.tomorrowLabel.isHidden = isHidden
        self.dayAfterTomorrowLabel.isHidden = isHidden
        self.temperatureLabel.isHidden = isHidden
        self.locationLabel.isHidden = isHidden
        self.conditionLabel.isHidden = isHidden
        self.temperatureLabel.isHidden = isHidden
        self.metricLabel.isHidden = isHidden
        self.imperialLabel.isHidden = isHidden
        self.searchButton.isHidden = isHidden
        self.searchButtonText.isHidden = isHidden
        self.favoritesButton.isHidden = isHidden
        self.mapButton.isHidden = isHidden
        
        self.windLabel.isHidden = isHidden
        self.pressureLabel.isHidden = isHidden
        self.humidityLabel.isHidden = isHidden
        self.additionalInfoLabel1.isHidden = isHidden
        self.additionalInfoLabel2.isHidden = isHidden
        
        self.time1.isHidden = isHidden
        self.time2.isHidden = isHidden
        self.time3.isHidden = isHidden
        self.time4.isHidden = isHidden
        self.time5.isHidden = isHidden
        
        self.conditionSmall1.isHidden = isHidden
        self.conditionSmall2.isHidden = isHidden
        self.conditionSmall3.isHidden = isHidden
        self.conditionSmall4.isHidden = isHidden
        self.conditionSmall5.isHidden = isHidden
        
        self.sunriseLabel.isHidden = isHidden
        self.sunsetLabel.isHidden = isHidden
        //updateConditionComponents(isHidden: isHidden)
        
        self.twelve.isHidden = isHidden
        self.twentyFour.isHidden = isHidden
    }
    
    func updateSearchScreenItemsVisibility(isHidden: Bool) {
        let status = CLLocationManager.authorizationStatus()
        self.citySearchInputText.isHidden = isHidden
        self.searchCityLabel.isHidden = isHidden
        self.searchCitiesTableView.isHidden = isHidden
        self.goBack.isHidden = isHidden || location == "" || self.isErrorState
        self.currentLocationButton.isHidden = isHidden || status == .denied
    }
    
    func updateFavoritesScreenItemsVisibility(isHidden: Bool) {
        let status = CLLocationManager.authorizationStatus()
        self.favoritiesView.isHidden = isHidden
        self.goBack.isHidden = isHidden || location == "" || self.isErrorState
        self.currentLocationButton.isHidden = isHidden || status == .denied
    }
    
    func updateItemsVisibility(isHidden: Bool) {
        updateMainScreenItemsVisibility(isHidden: isHidden)
        
        self.favoritesListButton.isHidden = isHidden || (self.favoritiesDict.count == 0)
        // hide keyboard if was typing before
        citySearchInputText.endEditing(true)
    }
    
    func updateConditionComponents(isHidden: Bool) {
        self.time1.isHidden = isHidden
        self.conditionSmall1.isHidden = isHidden
        self.time2.isHidden = isHidden
        self.conditionSmall2.isHidden = isHidden
        self.time3.isHidden = isHidden
        self.conditionSmall3.isHidden = isHidden
        self.time4.isHidden = isHidden
        self.conditionSmall4.isHidden = isHidden
        self.time5.isHidden = isHidden
        self.conditionSmall5.isHidden = isHidden
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      print("location update");
      if let location = locations.first {
        lat = location.coordinate.latitude
        lon = location.coordinate.longitude
        updateWeather(location: location)
      }
      self.activityIndicator.stopAnimating()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.authorizedAlways) || (status == CLAuthorizationStatus.authorizedWhenInUse) {
            locationManager.startUpdatingLocation()
        } else {
            self.handleLocationLookupError()
        }
    }
    
    func handleLocationLookupError() {
        self.activityIndicator.stopAnimating()
        if (favoritiesDict.count == 0) {
          // if can't check for location, open search view by default
          searchButtonTapped(UITapGestureRecognizer())
        } else {
          favoriteTapped(UITapGestureRecognizer())
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: NSError) {
        self.locationManager.stopUpdatingLocation()
        self.activityIndicator.stopAnimating()
        let errorFormatString = NSLocalizedString("location lookup failure", comment: "Error")
        self.locationLabel.text = errorFormatString
        
        let seconds = 5.0
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.handleLocationLookupError()
        }
    }
    
    func updateLocationLabel() {
        var location = self.location
        if (location.count > 13) {
            location = location.prefix(12) + ".."
        }
        self.locationLabel.text = location
    }
    
    func updateWeather(location: CLLocation?) {
        let endpoint = "forecast" //always query forecast endpoint
        
        let geocoder = CLGeocoder()
        
        if (location != nil) {
          // Look up the location and pass it to the completion handler
          geocoder.reverseGeocodeLocation(location!,
                    completionHandler: { (placemarks, error) in
            if error == nil && placemarks != nil {
                self.location = placemarks?[0].locality ?? ""
                print("Got location: " + self.location)
                self.updateLocationLabel()
                self.updateStarImage()
                self.isErrorState = false
                self.updateFavoritesScreenItemsVisibility(isHidden: true)
                self.updateSearchScreenItemsVisibility(isHidden: true)
            } else {
                print("Failed to get location placemarks")
                let errorFormatString = NSLocalizedString("location lookup failure", comment: "Error")
                self.updateItemsVisibility(isHidden: true)
                self.updateFavoritesScreenItemsVisibility(isHidden: true)
                self.updateSearchScreenItemsVisibility(isHidden: true)
                self.locationLabel.isHidden = false
                self.searchButton.isHidden = false
                self.searchButtonText.isHidden = false
                self.locationLabel.text = errorFormatString
                self.resetSmallItems()
                self.isErrorState = true
            }
            self.locationLabel.isHidden = false
        })
        }
        let s = "http://api.openweathermap.org/data/2.5/\(endpoint)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=\(apiUnit)";
        print("Request: " + s)
        
        Alamofire.request("http://api.openweathermap.org/data/2.5/\(endpoint)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=\(apiUnit)").responseJSON {
          response in
          switch response.result {
            case .failure(let _):
              print("Lookup weather failure")
              let errorFormatString = NSLocalizedString("api error msg", comment: "Error")
              self.updateItemsVisibility(isHidden: true)
              self.updateFavoritesScreenItemsVisibility(isHidden: true)
              self.updateSearchScreenItemsVisibility(isHidden: true)
              self.locationLabel.isHidden = false
              self.searchButton.isHidden = false
              self.searchButtonText.isHidden = false
              self.locationManager.stopUpdatingLocation()
              self.activityIndicator.stopAnimating()
              self.time2.text = errorFormatString
              self.time2.isHidden = false
              self.time2.font = self.selectedHourItemFont
              self.resetSmallItems()
              self.isErrorState = true
            default:
              print("Success result from Weather API")
                self.isErrorState = false
          }
          if let responseStr = response.result.value {
            print("Updating weather service")
            let jsonResponse = JSON(responseStr)
            self.timezone = jsonResponse["city"]["timezone"].int!
            self.updateWeather(json: jsonResponse)
          }
        }
    }
    
    func updateWeather(json: JSON) {
        // update weather only if in the meantime user did not open other views
        if (
            self.favoritiesView.isHidden == false ||
                self.searchCitiesTableView.isHidden == false ||
                (self.lat == -1.0 && self.lon == -1.0)
        ) {
            return
        }
        let jsonResponse = json

        let dateFormatter = DateFormatter()
        var todayDate = Date()
        let timezoneOffset =  TimeZone.current.secondsFromGMT()
        let currentTime = Int(todayDate.timeIntervalSince1970)
        
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = self.hourFormat == "12" ? "hh:mm a" : "HH:mm"
        
        let sunsetFormatString = NSLocalizedString("sunset", comment: "Sunset")
        self.sunsetLabel.text = sunsetFormatString + dayTimePeriodFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(json["city"]["sunset"].intValue + self.timezone - timezoneOffset)) as Date)
        let sunriseFormatString = NSLocalizedString("sunrise", comment: "Sunrise")
        self.sunriseLabel.text = sunriseFormatString + dayTimePeriodFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(json["city"]["sunrise"].intValue + self.timezone - timezoneOffset)) as Date)
        
        updateItemsVisibility(isHidden: false)
        updateConditionComponents(isHidden: true)
        
        self.time1JSON = nil
        self.time2JSON = nil
        self.time3JSON = nil
        self.time4JSON = nil
        self.time5JSON = nil
        
        print("UPDATE WEATHER!")
        
        var dt : JSON!
        dateFormatter.dateFormat = "HH"
        var i = 0
        
        var rowsForToday = 0
        
        todayDate = Date(timeIntervalSince1970: TimeInterval(currentTime))
        var tomorrowDayOfMonth = 0;
        for weatherInstance in jsonResponse["list"].array! {
          dt = weatherInstance["dt"]
          
          let t1 = dt.intValue + Int(self.timezone) - Int(timezoneOffset)
          let date = NSDate(timeIntervalSince1970: TimeInterval(t1))

          dayTimePeriodFormatter.dateFormat = "dd"
            
          if (dayTimePeriodFormatter.string(from: date as Date) == dayTimePeriodFormatter.string(from: todayDate as Date)) {
            rowsForToday += 1
          }
        }
        print("rowsForToday", rowsForToday)

        var selectedFound = false
        
        resetSmallItems()
        
        self.totalItems = 0
        
        for weatherInstance in jsonResponse["list"].array! {
            dt = weatherInstance["dt"]
            
            let t1 = dt.intValue + Int(self.timezone) - Int(timezoneOffset)
            let date = Date(timeIntervalSince1970: TimeInterval(t1))
            
            let dayTimePeriodFormatter = DateFormatter()
            dayTimePeriodFormatter.dateFormat = "dd"
            
            //print("X", Int(dayTimePeriodFormatter.string(from: date))!)
            if (self.apiEndpoint == "forecast" && ((Int(dayTimePeriodFormatter.string(from: date as Date))! - 1 == Int(dayTimePeriodFormatter.string(from: todayDate))!) || (Int(dayTimePeriodFormatter.string(from: date as Date))! == 1 && date.timeIntervalSince1970 - todayDate.timeIntervalSince1970 < (86400 * 2) && Int(dayTimePeriodFormatter.string(from: todayDate))! != 1))) {
                // we allow max 5 items
                if (i % 2 == 0 && (i / 2) + 1 <= 5) {
                  fillCondition(index: (i / 2) + 1, conditionJSON: weatherInstance, selected: Int(dateFormatter.string(from: date))! >= 10 && !selectedFound)
                  if (Int(dateFormatter.string(from: date))! >= 10) {
                    selectedFound = true
                  }
                }
                if (tomorrowDayOfMonth == 0) {
                  tomorrowDayOfMonth = Int(dayTimePeriodFormatter.string(from: date as Date))!
                }
                i = i + 1
            } else if (self.apiEndpoint == "forecast2" && ((Int(dayTimePeriodFormatter.string(from: date as Date))! - 2 == Int(dayTimePeriodFormatter.string(from: todayDate))!) || (Int(dayTimePeriodFormatter.string(from: date as Date))! == 2 && tomorrowDayOfMonth == 1) || (Int(dayTimePeriodFormatter.string(from: date as Date))! == 1 && tomorrowDayOfMonth >= 28))) {
                // we allow max 5 items
                if (i % 2 == 0 && (i / 2) + 1 <= 5) {
                  fillCondition(index: (i / 2) + 1, conditionJSON: weatherInstance, selected: Int(dateFormatter.string(from: date))! >= 10 && !selectedFound)
                  if (Int(dateFormatter.string(from: date))! >= 10) {
                    selectedFound = true
                  }
                }
                i = i + 1
            } else if (self.apiEndpoint == "weather" &&  Int(dayTimePeriodFormatter.string(from: date as Date)) == Int(dayTimePeriodFormatter.string(from: todayDate))! &&
                rowsForToday > 1
            ) {
                if (i < 5) {
                  // we allow max 5 items
                  fillCondition(index: i + 1, conditionJSON: weatherInstance, selected: (i == 0))
                  i = i + 1
                }
            } else if (
                self.apiEndpoint == "weather" &&
                i < 3 &&
                rowsForToday == 1
            ) {
                // we allow max 5 items
                fillCondition(index: i + 1, conditionJSON: weatherInstance, selected: (i == 0))
                i = i + 1
            } else if (self.apiEndpoint == "weather" && rowsForToday < 1) {
                dayLabel.isHidden = (rowsForToday < 1)
                tomorrowLabelTapped(UITapGestureRecognizer.init())
                break
            }
        }
        
        if (self.time5JSON != nil) {
            self.totalItems = 5
        } else if (self.time4JSON != nil) {
            self.totalItems = 4
        } else if (self.time3JSON != nil) {
            self.totalItems = 3
        } else if (self.time2JSON != nil) {
            self.totalItems = 2
        } else {
            self.totalItems = 1
        }
        dayLabel.isHidden = (rowsForToday < 1)

        locationManager.stopUpdatingLocation()
        self.activityIndicator.stopAnimating()
        updateStarImage()
    }
    
    func setBlueGradientBackground() {
        let topColor = UIColor.init(red: 95.0/255.0, green: 145.0/255.0, blue: 1.0/255.0, alpha: 1.0).cgColor
        let bottomColor = UIColor.init(red: 72.0/255.0, green: 114.0/255.0, blue: 214.0/255.0, alpha: 1.0).cgColor
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [topColor, bottomColor]
    }
    
    func setSelectedBackground(imageView: UIImageView) {
        let topColor = UIColor.init(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.15)
        imageView.layer.cornerRadius = 20
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
        // In this case, we instantiate the banner with desired ad size.
        //let adSize = GADAdSizeFromCGSize(CGSize(width: 300, height: 100))
        self.bannerView = GAMBannerView(adSize: kGADAdSizeLargeBanner)
        // ca-app-pub-2839380108501012/5277274657
        self.bannerView.adUnitID = "/6499/example/banner"
        self.bannerView.rootViewController = self
        self.bannerView.translatesAutoresizingMaskIntoConstraints = false
        self.bannerView.delegate = self
        self.bannerView.load(GAMRequest())
        
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        self.adView.addSubview(self.bannerView)
        self.adView.addConstraints(
            [
             NSLayoutConstraint(item: self.bannerView,
                                  attribute: .centerX,
                                  relatedBy: .equal,
                                  toItem: self.adView,
                                  attribute: .centerX,
                                  multiplier: 1,
                                  constant: 0)
              ])
        self.adView.isHidden = true
    }
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        self.adView.isHidden = false
    }
    
    func updateUserDefaults() {
        UserDefaults.standard.set(self.apiUnit, forKey: "temperatureUnit")
        UserDefaults.standard.set(self.apiEndpoint, forKey: "endpoint")
        UserDefaults.standard.set(self.hourFormat, forKey: "hourFormat")
    }
    
    @objc func applicationDidBecomeActive(notification: NSNotification) {
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
      

      self.dayLabel.font = (self.apiEndpoint == "weather") ? self.selectedItemFont : self.notSelectedItemFont
      self.tomorrowLabel.font = (self.apiEndpoint == "forecast") ? self.selectedItemFont : self.notSelectedItemFont
      self.dayAfterTomorrowLabel.font = (self.apiEndpoint == "forecast2") ? self.selectedItemFont : self.notSelectedItemFont
    
      self.dayLabel.backgroundColor = nil
      self.dayLabel.layer.cornerRadius = 0
      self.dayLabel.clipsToBounds = false
    
      self.tomorrowLabel.backgroundColor = nil
      self.tomorrowLabel.layer.cornerRadius = 0
      self.tomorrowLabel.clipsToBounds = false
        
      self.dayAfterTomorrowLabel.backgroundColor = nil
      self.dayAfterTomorrowLabel.layer.cornerRadius = 0
      self.dayAfterTomorrowLabel.clipsToBounds = false

      var selectedLabel = self.dayAfterTomorrowLabel
      if (self.apiEndpoint == "forecast") {
        selectedLabel = self.tomorrowLabel
      } else if (self.apiEndpoint == "weather") {
        selectedLabel = self.dayLabel
      }
      selectedLabel!.layer.cornerRadius = 10
      selectedLabel!.backgroundColor = topColor
      selectedLabel!.clipsToBounds = true
    }
    
    func updateHourFonts(index: Int) {
        self.time1.font = (index == 1) ? self.selectedHourItemFont : self.notSelectedHourItemFont
        self.time2.font = (index == 2) ? self.selectedHourItemFont : self.notSelectedHourItemFont
        self.time3.font = (index == 3) ? self.selectedHourItemFont : self.notSelectedHourItemFont
        self.time4.font = (index == 4) ? self.selectedHourItemFont : self.notSelectedHourItemFont
        self.time5.font = (index == 5) ? self.selectedHourItemFont : self.notSelectedHourItemFont
    }
    
    func updatePreferredHourFormat() {
        self.twelve.layer.cornerRadius = 0
        self.twelve.backgroundColor = nil
        self.twelve.clipsToBounds = false
        
        self.twentyFour.layer.cornerRadius = 0
        self.twentyFour.backgroundColor = nil
        self.twentyFour.clipsToBounds = false
        
        self.twelve.font = (self.hourFormat == "12") ? self.selectedItemFont : self.notSelectedItemFont
        self.twentyFour.font = (self.hourFormat == "24") ? self.selectedItemFont : self.notSelectedItemFont
        
        let topColor = UIColor.init(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.15)
        let hourLabel = (self.hourFormat == "12") ? self.twelve : self.twentyFour
        hourLabel!.layer.cornerRadius = 10
        hourLabel!.backgroundColor = topColor
        hourLabel!.clipsToBounds = true
        
        updateUserDefaults()
        reloadView()
    }
    
    @objc func favoriteTapped(_ sender: UITapGestureRecognizer) {
        self.shouldCheckLocation = false
        self.favoritiesView.reloadData()
        
        self.updateItemsVisibility(isHidden: true)
        self.updateSearchScreenItemsVisibility(isHidden: true)
        
        self.updateFavoritesScreenItemsVisibility(isHidden: false)
        self.searchButton.isHidden = false
        self.searchButtonText.isHidden = false
        
        loadBannerAd()
    }
    
    @objc func goBackTapped(_ sender: UITapGestureRecognizer) {
        self.updateSearchScreenItemsVisibility(isHidden: true)
        self.updateFavoritesScreenItemsVisibility(isHidden: true)
        
        self.updateItemsVisibility(isHidden: true)
        
        reloadWeatherDetails()
        updateStarImage()
    }
    
    @objc func mapButtonTapped(_ sender: UITapGestureRecognizer) {
        let latLon = String(self.lat)+","+String(self.lon)
        let urlString = "https://maps.google.com/?ll="+latLon+"&q="+latLon+"&z=8"
        print(urlString)
        let url = URL(string: urlString)!
        UIApplication.shared.open(url, options: [:])
    }
    
    @objc func addRemoveFavoriteLocationTap(_ sender: UITapGestureRecognizer) {
        var locationFavorited = false
        var index = 0
        var i = 0
        for loc in self.favoritiesDict {
            if (loc[0] == location) {
              locationFavorited = true
              index = i
            }
            i += 1
        }
        if locationFavorited {
          self.favoritiesDict.remove(at: index)
          saveFavorities()
        } else if location != "" {
          self.favoritiesDict.append([location, String(self.lat), String(self.lon)])
          saveFavorities()
        }
        updateStarImage()
    }
    
    @objc func updateStarImage() {
        let location = self.location
        var locationFavorited = false
        var i = 0
        
        print("Update favorites!!", location)
        for loc in self.favoritiesDict {
            if (loc[0] == location) {
              locationFavorited = true
            }
            i += 1
        }
        if (locationFavorited) {
          self.favoritesButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        } else {
          self.favoritesButton.setImage(UIImage(systemName: "star"), for: .normal)
        }
        
        self.favoritesListButton.isHidden = (self.favoritiesDict.count == 0)
    }
    
    @objc func metricLabelTapped(_ sender: UITapGestureRecognizer) {
        if (self.activityIndicator.isAnimating) {
            // ignore until previous action is not completed
            return
        }
        self.apiUnit = "metric"
        updateDayFonts()
        
        updateUserDefaults()
        
        reloadView()
    }
    
    @objc func twelveLabelTapped(_ sender: UITapGestureRecognizer) {
        self.hourFormat = "12"
        updatePreferredHourFormat()
    }
    
    @objc func twentyFourLabelTapped(_ sender: UITapGestureRecognizer) {
        self.hourFormat = "24"
        updatePreferredHourFormat()
    }
    
    @objc func imperialLabelTapped(_ sender: UITapGestureRecognizer) {
        if (self.activityIndicator.isAnimating) {
            // ignore until previous action is not completed
            return
        }
        self.apiUnit = "imperial"
        updateDayFonts()
        
        updateUserDefaults()
        
        reloadView()
    }
    
    func resetSmallItems() {
        self.time1.layer.cornerRadius = 0
        self.time1.backgroundColor = nil
        self.time1.clipsToBounds = false
        
        self.time2.layer.cornerRadius = 0
        self.time2.backgroundColor = nil
        self.time2.clipsToBounds = false
        
        self.time3.layer.cornerRadius = 0
        self.time3.backgroundColor = nil
        self.time3.clipsToBounds = false
        
        self.time4.layer.cornerRadius = 0
        self.time4.backgroundColor = nil
        self.time4.clipsToBounds = false
        
        self.time5.layer.cornerRadius = 0
        self.time5.backgroundColor = nil
        self.time5.clipsToBounds = false
    }
    
    func conditionSmallTapped(index: Int) {
        resetSmallItems()
        fillCondition(index: 1, conditionJSON: self.time1JSON, selected: index == 1)
        fillCondition(index: 2, conditionJSON: self.time2JSON, selected: index == 2)
        fillCondition(index: 3, conditionJSON: self.time3JSON, selected: index == 3)
        fillCondition(index: 4, conditionJSON: self.time4JSON, selected: index == 4)
        fillCondition(index: 5, conditionJSON: self.time5JSON, selected: index == 5)
    }
    
    @objc func time1LabelTap(_ sender: UITapGestureRecognizer) {
        conditionSmallTapped(index: 1)
    }
    
    @objc func time2LabelTap(_ sender: UITapGestureRecognizer) {
        // time2 label is also used for showing error message, then ignore tapping
        if !self.isErrorState {
            conditionSmallTapped(index: 2)
        }
    }
    
    @objc func time3LabelTap(_ sender: UITapGestureRecognizer) {
        conditionSmallTapped(index: 3)
    }
    
    @objc func time4LabelTap(_ sender: UITapGestureRecognizer) {
        conditionSmallTapped(index: 4)
    }
    
    @objc func time5LabelTap(_ sender: UITapGestureRecognizer) {
        conditionSmallTapped(index: 5)
    }
    
    @objc func todayLabelTapped(_ sender: UITapGestureRecognizer) {
        if (self.activityIndicator.isAnimating) {
            // ignore until previous action is not completed
            return
        }
        self.apiEndpoint = "weather"
        updateDayFonts()
        
        updateUserDefaults()
        
        loadBannerAd()
        
        reloadView()
    }
    
    @objc func tomorrowLabelTapped(_ sender: UITapGestureRecognizer) {
        if (self.activityIndicator.isAnimating) {
            // ignore until previous action is not completed
            return
        }
        self.apiEndpoint = "forecast"
        updateDayFonts()
        
        updateUserDefaults()
        
        loadBannerAd()
        
        reloadView()
    }
    
    @objc func dayAfterTomorrowLabelTapped(_ sender: UITapGestureRecognizer) {
        if (self.activityIndicator.isAnimating) {
            // ignore until previous action is not completed
            return
        }
        self.apiEndpoint = "forecast2"
        updateDayFonts()
        
        updateUserDefaults()
        
        loadBannerAd()
        
        reloadView()
    }
    
    @objc func searchButtonTapped(_ sender: UITapGestureRecognizer) {
        selectedItem = nil
        self.updateItemsVisibility(isHidden: true)
        self.updateFavoritesScreenItemsVisibility(isHidden: true)
        
        self.updateSearchScreenItemsVisibility(isHidden: false)
        
        citySearchInputText.text = ""
        searchRecords(citySearchInputText)
        
        loadBannerAd()
    }
    
    @objc func currentLocationButtonTapped(_ sender: UITapGestureRecognizer) {
        selectedItem = nil
        
        citySearchInputText.isHidden = true
        searchCityLabel.isHidden = true
        searchCitiesTableView.isHidden = true
        currentLocationButton.isHidden = true
        goBack.isHidden = true
        favoritiesView.isHidden = true
        citySearchInputText.endEditing(true)
        updateItemsVisibility(isHidden: false)
        citySearchInputText.endEditing(true)
        
        shouldCheckLocation = true
        checkAuthorizationStatus()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
          if self.activityIndicator.isAnimating && self.location == "" {
              self.handleLocationLookupError()
          }
        }
        
        reloadView()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        return true
    }
    
    func fillCondition(index: Int, conditionJSON: JSON?, selected: Bool) {
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
        } else if (index == 4) {
            self.time4JSON = conditionJSON
            imgView = self.conditionSmall4
            label = self.time4
        } else if (index == 5) {
            self.time5JSON = conditionJSON
            imgView = self.conditionSmall5
            label = self.time5
        } else {
            return
        }
        
        imgView.isHidden = conditionJSON == nil
        label.isHidden = conditionJSON == nil
        
        if (conditionJSON == nil) {
            return
        }
        
        let dateFormatter = DateFormatter()
        let todayDate = Date()
        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: todayDate)!
        let dayAfterTomorrowDate = Calendar.current.date(byAdding: .day, value: 2, to: todayDate)!
        
        dateFormatter.dateFormat = "HH"
        //print(conditionJSON)
        
        let jsonWeather = conditionJSON!["weather"].array![0]
        let jsonTemp = conditionJSON!["main"]
        var iconName = jsonWeather["icon"].stringValue
            
        //print(conditionJSON["name"].stringValue);
        let tmp = "\(Int(round(jsonTemp["temp"].doubleValue)))"
        //print("Temperature: ")
        //print(tmp)
            
        if (selected) {
            self.index = index
            self.additionalInfoLabel1.text = ""
            self.additionalInfoLabel2.text = ""
            self.temperatureLabel.text = tmp
            let windFormatString = NSLocalizedString("wind", comment: "Wind")
            self.windLabel.text = windFormatString + String(format: "%.2f", conditionJSON!["wind"]["speed"].doubleValue) + ((self.apiUnit == "imperial") ? "mph" : "m/s")
            
            let humidityFormatString = NSLocalizedString("humidity", comment: "Humidity")
            self.humidityLabel.text = humidityFormatString + jsonTemp["humidity"].stringValue  + "%"
            
            let pressureFormatString = NSLocalizedString("pressure", comment: "Pressure")
            self.pressureLabel.text = pressureFormatString + jsonTemp["pressure"].stringValue + "hPa"
            
            let clouds = conditionJSON!["clouds"]["all"].intValue
            let rain = conditionJSON!["rain"]["3h"].doubleValue
            let snow = conditionJSON!["snow"]["3h"].doubleValue
            
            let precipitationFormatString = NSLocalizedString("precipitation", comment: "Precipitation")
            let precipitation = conditionJSON!["pop"].doubleValue
            //print("Clouds")
            //print(clouds)
            //print(rain)
            let cloudsFormatString = NSLocalizedString("clouds", comment: "Clouds")
            let rainFormatString = NSLocalizedString("rain", comment: "Rain")
            let snowFormatString = NSLocalizedString("snow", comment: "Snow")
            let hourFormatString = NSLocalizedString("hour", comment: "Hour")
            
            let percentFormatter            = NumberFormatter()
            percentFormatter.numberStyle    = .percent
            percentFormatter.multiplier     = 100.00;
            
            if (clouds > 0) {
                self.additionalInfoLabel1.text = cloudsFormatString + String(clouds) + "%"
                if (rain > 0.0) {
                    self.additionalInfoLabel1.text = precipitationFormatString + (percentFormatter.string(from: NSNumber(value: precipitation)) ?? "0")
                    self.additionalInfoLabel2.text = rainFormatString + "(3" + hourFormatString + "): " + String(rain) + " mm"
                } else if (snow > 0.0) {
                    self.additionalInfoLabel1.text = precipitationFormatString + (percentFormatter.string(from: NSNumber(value: precipitation)) ?? "0")
                    self.additionalInfoLabel2.text = snowFormatString + "(3" + hourFormatString + "): " + String(snow) + " mm"
                }
            } else {
                if (rain > 0) {
                    self.additionalInfoLabel2.text = rainFormatString + "(3" + hourFormatString + "): " + String(rain) + " mm"
                } else if (snow > 0.0) {
                    self.additionalInfoLabel2.text = snowFormatString + "(3" + hourFormatString + "): " + String(snow) + " mm"
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
        
        var time_dt = conditionJSON!["dt"].int!
        //print("DT Time")
        //print(self.timezone)
        //print(time_dt)
        time_dt += self.timezone - timezoneOffset
        
        //self.time1.text = String(self.time1.text!.prefix(5))
        let date = NSDate(timeIntervalSince1970: TimeInterval(time_dt))
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = self.hourFormat == "12" ? "hh a" : "HH:mm"
        
        let dateString = dayTimePeriodFormatter.string(from: date as Date)
        label.text = dateString
        
        dayTimePeriodFormatter.dateFormat = "hh"
        let timeString = dayTimePeriodFormatter.string(from: date as Date)
        let timeInt = Int(timeString)!
        
        dayTimePeriodFormatter.dateFormat = "a"
        let timeOfTheDayString = dayTimePeriodFormatter.string(from: date as Date)
        
        self.tomorrowLabel.text = dateFormatter.string(from: tomorrowDate)
        self.dayAfterTomorrowLabel.text = dateFormatter.string(from: dayAfterTomorrowDate)

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
          let conditionEnum = jsonWeather["description"].stringValue;
          self.conditionLabel.text = NSLocalizedString(conditionEnum, comment: "Condition")
          if (self.conditionLabel.text!.count > 14) {
            self.conditionLabel.font = UILabel().font.withSize(20)
          } else {
            self.conditionLabel.font = UILabel().font.withSize(28)
          }
          updateHourFonts(index: index)
        }
        iconName = "s_" + iconName
        //print("Icon Name: " + iconName)
        imgView.image = UIImage(named: iconName)
    }
}

