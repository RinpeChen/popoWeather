//
//  ViewController.swift
//  SwiftWeather
//
//  Created by RinpeChen on 16/2/2.
//  Copyright © 2016年 Rinpe. All rights reserved.
//

import UIKit
import CoreLocation
import NVActivityIndicatorView

class ViewController: UIViewController, CLLocationManagerDelegate, UIAlertViewDelegate
{
    // 定位管理对象
    let locationManager:CLLocationManager = CLLocationManager()
    // 城市名
    @IBOutlet weak var cityLabel: UILabel!
    // 天气图片
    @IBOutlet weak var weatherView: UIImageView!
    // 温度度数
    @IBOutlet weak var tempLabel: UILabel!
    // 提示
    var indicator:NVActivityIndicatorView!
    // 遮盖
    var cover: UIView!
    
    // MARK: - 系统方法
    
    override func viewDidLoad()
    {
        NSNotificationCenter.defaultCenter() .addObserver(self, selector: "applicationWillEnterForeground", name: "applicationWillEnterForeground", object: nil)
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        // 判断是否开启定位功能
        if !CLLocationManager.locationServicesEnabled() {
            let alertView:UIAlertView = UIAlertView(title: "温馨提示", message: "亲, 没有打开定位功能哦", delegate: self, cancelButtonTitle: "设置")
            alertView.show()
        }
        
        // 设置精确度
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        
        // 请求用户许可
        locationManager.requestAlwaysAuthorization()
        
        // 判断是否已经存在提示, 如果存在, 则不再创建
        if indicator == nil {
            // 加载提示
            indicator = NVActivityIndicatorView(frame: CGRectMake(self.view.center.x, self.view.frame.size.height * 0.95, 0, 0), type: .BallPulse, color: UIColor.blackColor(), size: CGSizeMake(20, 20))
            self.view.addSubview(indicator)
        }
        // 执行动画
        indicator.startAnimation()
        // 加载时不可点
        self.view.userInteractionEnabled = false
        
        // 隐藏界面信息
        UIView.animateWithDuration(2.0, animations: { [unowned self] () -> Void in
            self.cityLabel.alpha = 0
            self.weatherView.alpha = 0
            self.tempLabel.alpha = 0
            self.view.backgroundColor = UIColor.whiteColor()
            }) { [unowned self] (finished) -> Void in
                // 开始定位
                self.locationManager.startUpdatingLocation()
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        super.touchesBegan(touches, withEvent: event)
        
        self.viewWillAppear(true)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        // 获取最后一个定位信息
        if let location:CLLocation = locations.last {
            
            // 停止定位
            manager.stopUpdatingLocation()
            
            // 获取天气信息数据
            updateWeatherInfo(location.coordinate.latitude, longitude:location.coordinate.longitude)
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
    {
        print("定位失败")
    }
    
    // MARK: - UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int)
    {
        let settingURL = NSURL(string: "prefs:root=LOCATION_SERVICES")
        if (UIApplication.sharedApplication().canOpenURL(settingURL!)) {
            UIApplication.sharedApplication().openURL(settingURL!)
        }
    }
    
    // MARK: - 私有方法
    
    func applicationWillEnterForeground()
    {
        self.viewWillAppear(true)
    }
    
    func updateWeatherInfo(latitude: CLLocationDegrees, longitude: CLLocationDegrees)
    {
        let manager:AFHTTPSessionManager = AFHTTPSessionManager()
        let url = "http://api.openweathermap.org/data/2.5/weather"
        let param = ["lat":latitude, "lon":longitude, "cnt":0, "appid":"44db6a862fba0b067b1930da0d769e98"]
        manager.requestSerializer.timeoutInterval = 15;
        manager.GET(url, parameters: param, progress: nil,
            success: { [unowned self] (task, responseObject) in
                // 更新界面
                self.updateUI(responseObject as! NSDictionary)
            },
            failure: { (task, error) -> Void in
                print(error)
        })
    }
    
    // 更新界面
    func updateUI(responseObject: NSDictionary!)
    {
        // 温度
        if let temp = responseObject["main"]?["temp"] as? Double {
            var temperature: Double
            if responseObject["sys"]?["country"] as? String == "US" {   // 美国用的是华氏度
                temperature = round(((temp - 273.115) * 1.8) + 32)
            } else {
                temperature = round(temp - 273.15)      // 其他城市用的是摄氏度
            }
            self.tempLabel.text = Int(temperature).description + "°";
        } else {
            let alertView:UIAlertView = UIAlertView(title: "温馨提示", message: "获取数据失败", delegate: self, cancelButtonTitle: "确定")
            alertView.show()
        }
        
        // 城市名
        if let cityName = responseObject["name"] as? String {
            self.cityLabel.text = cityName
        } else {
            let alertView:UIAlertView = UIAlertView(title: "温馨提示", message: "获取数据失败", delegate: self, cancelButtonTitle: "确定")
            alertView.show()
        }
        
        // 更新天气图标
        // http://bugs.openweathermap.org/projects/api/wiki/Weather_Condition_Codes 图片获取说明
        let icon = (responseObject["weather"] as? NSArray)?.firstObject?["icon"] as? String
        self.weatherView.image = UIImage(named: icon!)
        
        UIView.animateWithDuration(3.0, animations: { [unowned self] () -> Void in
            self.cityLabel.alpha = 1
            self.weatherView.alpha = 1
            self.tempLabel.alpha = 1
            self.view.backgroundColor = UIColor(red: CGFloat(arc4random_uniform(255)) / 255.0, green: CGFloat(arc4random_uniform(255)) / 255.0, blue: CGFloat(arc4random_uniform(255)) / 255.0, alpha: 1.0)
            }) { [unowned self] (finished) -> Void in
                // 隐藏提示
                self.indicator.stopAnimation()
                self.view.userInteractionEnabled = true
        }
    }
}

