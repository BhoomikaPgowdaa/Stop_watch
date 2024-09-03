    //
    //  ViewController.swift
    //  SmartWatchSample
    //
    //  Created by Bhoomika HP on 30/08/24.
    //

    import UIKit
    import UserNotifications

    class ViewController: UIViewController {
        
        @IBOutlet weak var dropDownView: UIView!
        @IBOutlet weak var dropDownButton: UIButton!
        @IBOutlet weak var startPauseButton: UIButton!
        @IBOutlet weak var resetButton: UIButton!
        @IBOutlet weak var displayLabel: UILabel!
        @IBOutlet weak var dropDownStackView: UIStackView!
        @IBOutlet weak var secondButton: UIButton!
        @IBOutlet weak var millisecondButton: UIButton!
        
        
        var timer: Timer?
        var isTimerRunning = false
        var toggleTimer = true
        var startTime: Date?
        var accumulatedTime: TimeInterval = 0.0
        var selectedFormat = "second"
        var backgroundEntryTime: Date?
         
        
        override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
            configureUI()
            configureDropDownButton()
            configureDropDownView()
            configureResetStartButton()
            setupNotification()
            observeAppStateChanges()
        }
        
       
        func configureUI(){
            dropDownButton.setTitle("second ", for: .normal)
            dropDownButton.setImage(UIImage(named: "Down arrow"), for: .normal)
            dropDownButton.semanticContentAttribute = .forceRightToLeft
            dropDownButton.layer.cornerRadius = 20
            dropDownStackView.isHidden = true
            startPauseButton.setTitle("START", for: .normal)
            resetButton.setTitle("RESET", for: .normal)
            secondButton.layer.borderWidth = 1
            millisecondButton.layer.borderWidth = 1
            secondButton.layer.borderColor = UIColor.white.cgColor
            millisecondButton.layer.borderColor = UIColor.white.cgColor
            
        }
        
        func configureDropDownView(){
            dropDownView.layer.cornerRadius = 20
            dropDownView.layer.borderColor = UIColor.gray.cgColor
            dropDownView.layer.borderWidth = 1
        }
        
        func configureDropDownButton(){
            displayLabel.text = "00:00:00"
            displayLabel?.layer.borderWidth = 1
            displayLabel?.layer.borderColor = UIColor.gray.cgColor
            displayLabel?.layer.cornerRadius = 30.0
            displayLabel.layer.masksToBounds = true
            
        }
        
        func configureResetStartButton(){
          
            startPauseButton.layer.cornerRadius = 5
            startPauseButton.layer.borderWidth = 1
            startPauseButton.layer.borderColor = UIColor.black.cgColor
            
            resetButton.layer.cornerRadius = 5
            resetButton.layer.borderWidth = 1
            resetButton.layer.borderColor = UIColor.black.cgColor
        }
        
        @objc func updateTimer() {
               guard let startTime = startTime else { return }
               let currentTime = Date()
               let elapsedTime = accumulatedTime + currentTime.timeIntervalSince(startTime)
               updateTimerLabel(elapsedTime: elapsedTime)
           }
        

           // Update the Timer Label based on the selected format
           func updateTimerLabel(elapsedTime: TimeInterval = 0) {
               let hours = Int(elapsedTime) / 3600
               let minutes = Int(elapsedTime) / 60 % 60
               let seconds = Int(elapsedTime) % 60

               if  selectedFormat == "millisecond" {
                   let milliseconds = Int((elapsedTime - floor(elapsedTime)) * 1000)
                   displayLabel.text = String(format: "%02d:%02d:%02d:%03d", hours, minutes, seconds, milliseconds)
               } else {
                   displayLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
               }
           }

        
        @IBAction func handleTimerType(_ sender: Any) {
            if toggleTimer{
                dropDownStackView.isHidden = false
                dropDownButton.setImage(UIImage(named: "Up arrow"), for: .normal)
                toggleTimer = !toggleTimer
            }else{
                dropDownStackView.isHidden = true
                dropDownButton.setImage(UIImage(named: "Down arrow"), for: .normal)
                toggleTimer = !toggleTimer
            }
            
        }
        
        
        @IBAction func updatedToSeconds(_ sender: Any) {
            dropDownButton.setTitle("second ", for: .normal)
            selectedFormat = "second"
            dropDownStackView.isHidden = true
            toggleTimer = !toggleTimer
            dropDownButton.setImage(UIImage(named: "Down arrow"), for: .normal)
            
        }
        
        
        @IBAction func updateToMilliseconds(_ sender: Any) {
            dropDownButton.setTitle("millisecond ", for: .normal)
            selectedFormat = "millisecond"
            dropDownStackView.isHidden = true
            toggleTimer = !toggleTimer
            dropDownButton.setImage(UIImage(named: "Down arrow"), for: .normal)
        }
       
        
        @IBAction func startPauseTimer(_ sender: UIButton) {
            if isTimerRunning {
                      // Pause Timer
                      accumulatedTime += Date().timeIntervalSince(startTime!)
                      timer?.invalidate()
                      startPauseButton.setTitle("Start", for: .normal)
                   } else {
                     // Start Timer
                     startTime = Date()
                     timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
                       startPauseButton.setTitle("Pause", for: .normal)
                          }
                   isTimerRunning.toggle()
        }
        
        
        
        @IBAction func resetTimer(_ sender: UIButton) {
            timer?.invalidate()
            isTimerRunning = false
            startTime = nil
            accumulatedTime = 0.0
            displayLabel.text = (selectedFormat == "millisecond") ? "00:00:00:000" : "00:00:00"
            startPauseButton.setTitle("Start", for: .normal)
        }
        
        
    }
    extension ViewController :  UNUserNotificationCenterDelegate  {
        
        func observeAppStateChanges() {
                NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
            }

        @objc func appDidEnterBackground() {
                // Save the time when the app enters the background
                backgroundEntryTime = Date()
                UserDefaults.standard.set(backgroundEntryTime, forKey: "backgroundEntryTime")
               triggerLocalNotification()
                // Schedule alert after 10 minutes
                scheduleNotification(after: 10 * 60, identifier: "ALERT_NOTIFICATION", title: "Stopwatch Alert", body: "Stopwatch will reset in 5 minutes.")
                
                // Schedule reset after 15 minutes
               scheduleNotification(after: 15 * 60, identifier: "RESET_NOTIFICATION", title: "Stopwatch Reset", body: "Stopwatch has been reset.")
            }


        
        @objc func appWillEnterForeground() {
               UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
               UNUserNotificationCenter.current().removeAllDeliveredNotifications()
               
               guard let backgroundEntryTime = UserDefaults.standard.value(forKey: "backgroundEntryTime") as? Date else { return }
               
               // Calculate the elapsed time since entering background
               let elapsedBackgroundTime = Date().timeIntervalSince(backgroundEntryTime)
               
               if elapsedBackgroundTime >= 15 * 60 {
                   resetTimer(resetButton)
               }
           }
        
        func showResetAlert() {
                let alert = UIAlertController(title: "Stopwatch Alert", message: "Stopwatch will reset in 5 minutes.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }

        
        // Schedule a local notification
            func scheduleNotification(after timeInterval: TimeInterval, identifier: String, title: String, body: String) {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }


        func setupNotification() {
                UNUserNotificationCenter.current().delegate = self
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("Notification authorization error: \(error.localizedDescription)")
                        return
                    }
                    
                    if granted {
                        print("Notification authorization granted")
                    } else {
                        print("Notification authorization denied")
                        DispatchQueue.main.async {
                            let alertController = UIAlertController(title: "Notifications Disabled", message: "To receive notifications, please enable them in Settings.", preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                }
        }
        
        // Trigger local notification
        func triggerLocalNotification() {
            guard isTimerRunning else { return }

            let content = UNMutableNotificationContent()
            content.title = "Stopwatch Running"
            content.body = "Current Time: \(displayLabel.text ?? "00:00:00")"
            content.categoryIdentifier = "TIMER_CATEGORY"

            // Define actions
            let startPauseAction = UNNotificationAction(identifier: "START_PAUSE_ACTION", title: isTimerRunning ? "Pause" : "Start", options: [])
            let resetAction = UNNotificationAction(identifier: "RESET_ACTION", title: "Reset", options: [.destructive])

            // Define the category
            let category = UNNotificationCategory(identifier: "TIMER_CATEGORY", actions: [startPauseAction, resetAction], intentIdentifiers: [], options: [])

            // Register the category with the notification center
            UNUserNotificationCenter.current().setNotificationCategories([category])

            // Trigger the notification after 1 second
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "TIMER_NOTIFICATION", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }

        
        // MARK: - Notification Response Handling

            func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
                if response.actionIdentifier == "START_PAUSE_ACTION" {
                    startPauseTimer(startPauseButton) // Handle Start/Pause action
                } else if response.actionIdentifier == "RESET_ACTION" {
                    resetTimer(resetButton) // Handle Reset action
                }
                completionHandler()
            }

            // MARK: - Reset Alert Notification

            func showResetAlert(after timeInterval: TimeInterval) {
                let content = UNMutableNotificationContent()
                content.title = "Stopwatch Alert"
                content.body = "Stopwatch will reset in 5 minutes."
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                let request = UNNotificationRequest(identifier: "RESET_ALERT_NOTIFICATION", content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }
        
    }

