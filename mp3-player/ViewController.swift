//
//  ViewController.swift
//  mp3-player
//
//  Created by Tammy Le on 10/16/18.
//  Copyright © 2018 Tammy Le. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

extension UIImageView {
    func setRound() {
        let radius = self.frame.width / 2
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate {

    
    
    //MARK: - Global Variables
    var audioPlayer: AVAudioPlayer! = nil
    var audioList: NSArray!
    
    var currentAudio = ""
    var currentAudioPath: URL!
    var currentAudioIndex = 0
    
    
    var timer: Timer!
    var audioLength = 0.0
    var totalAudioLength = ""
    
    var toggle = true
    var effectToggle = true
    
    var isTableViewOnScreen = false
    var shuffleState = false
    var repeatState = false
    var shuffleArray = [Int]()
    
    

    //MARK: - OUTLETS
    
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var audioImage: UIImageView!
    
    @IBOutlet weak var audioNameLabel: UILabel!
    
    @IBOutlet weak var authorNameLabel: UILabel!
    
    
    @IBOutlet weak var processTimerLabel: UILabel!
    
    @IBOutlet weak var totalAudioLengthLabel: UILabel!
    
    @IBOutlet weak var playerAudioSlider: UISlider!
    
    
    @IBOutlet weak var previousButton: UIButton!
    
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var playButton: UIButton!
    
    
    @IBOutlet weak var shuffleButton: UIButton!
    
    @IBOutlet weak var repeatButton: UIButton!
    
    @IBOutlet weak var listButton: UIButton!
    
    
    @IBOutlet weak var tableViewContainer : UIView!
    
    @IBOutlet weak var tableView : UITableView!
    
    @IBOutlet weak var blurView : UIVisualEffectView!
    
    @IBOutlet weak var backgroundBlurView: UIVisualEffectView!
    
    
    //@IBOutlet weak var tableViewContainerTopConstrain: NSLayoutConstraint!
    
    
    //MARK: - OVERRIDE FUNCS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        retrieveSavedTrackNumber()
        prepareAudio()
        updateAudioLabels()
        //setRepeatAndShuffle()
        assignSliderUI()
        retrievePlayAudioSliderValue()
        backgroundImage.image =  UIImage(named: "blueGradient")
        backgroundBlurView.isHidden = true

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        blurView.isHidden = false
        effectToggle = !effectToggle
        //audioImage.setRound()
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        audioImage.setRound()
    }
    
    
    
    
    
    //MARK: - TABLEVIEWS
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var audioNameDict = NSDictionary()
        audioNameDict = audioList.object(at: (indexPath as NSIndexPath).row) as! NSDictionary
        
        
        let audioName = audioNameDict.value(forKey: "audioName") as! String
        
        
        var authorNameDict = NSDictionary()
        authorNameDict = audioList.object(at: (indexPath as NSIndexPath).row) as! NSDictionary
        let authorName = authorNameDict.value(forKey: "authorName") as! String
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        cell.textLabel?.font = UIFont(name: "Avenir-Heavy", size: 25.0)
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = audioName
        
        cell.detailTextLabel?.font = UIFont(name: "Avenir-Book", size: 16.0)
        cell.detailTextLabel?.textColor = UIColor.white
        cell.detailTextLabel?.text = authorName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 57.0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tableView.backgroundColor = UIColor.clear
        cell.backgroundColor = UIColor.clear
    }
    
    
    //MARK: - TABLE VIEW DELEGATE
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tableViewOffScreen()
        currentAudioIndex = (indexPath as IndexPath).row
        prepareAudio()
        playAudio()
        effectToggle = !effectToggle
        switchPlayPauseButton()
        blurView.isHidden = true
        
    }
    
    
    
    //MARK: - ANIMATE tableViewlist on/off screen
    
    func tableViewOnScreen() {
        self.blurView.isHidden = false
        self.tableViewContainer.isHidden = false
    }
    
    func tableViewOffScreen() {
        self.blurView.isHidden = true
        self.tableViewContainer.isHidden = true
        isTableViewOnScreen = false
    }
    
    
    //MARK: - Set audio file URL
    func setCurrentAudioPath() {
        currentAudio = getAudioName(currentAudioIndex)
        currentAudioPath = URL(fileURLWithPath: Bundle.main.path(forResource: currentAudio, ofType: "mp3")!)
    }
    
    func saveCurrentTrackNumber() {
        UserDefaults.standard.set(currentAudioIndex, forKey: "currentAudioIndex")
        UserDefaults.standard.synchronize()
    }
    
    func retrieveSavedTrackNumber() {
        if let currentAudioIndex_ = UserDefaults.standard.object(forKey: "currentAudioIndex") as? Int {
            currentAudioIndex = currentAudioIndex_
        }
        else {
            currentAudioIndex = 0
        }
    }
    
    
    
    //MARK: - PREPARE AUDIOS
    func prepareAudio() {
        setCurrentAudioPath()
        backgroundBlurView.isHidden = false
        backgroundImage.image = UIImage(named: getAudioImage(currentAudioIndex))
        // keep music play in background
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()
        audioPlayer = try? AVAudioPlayer(contentsOf: currentAudioPath)
        audioPlayer.delegate = self
        audioLength = audioPlayer.duration
        playerAudioSlider.maximumValue = Float(audioPlayer.duration)
        playerAudioSlider.minimumValue = 0.0
        playerAudioSlider.value = 0.0
        audioPlayer.prepareToPlay()
        showTotalSongLength()
        updateAudioLabels()
        processTimerLabel.text = "00:00:00"
        
        
    }
    
    
    
    //MARK: - AUDIO CONTROLS SETUP
    func playAudio() {
        audioPlayer.play()
        startTimer()
        updateAudioLabels()
        saveCurrentTrackNumber()
        //showMediaLockScreen()
    }
    
    func audioPlayingCondition() {
        if audioPlayer.isPlaying {
            prepareAudio()
            playAudio()
        }
        else {
            prepareAudio()
        }
        
    }
    
    func playNextAudio() {
        currentAudioIndex += 1
        
        if currentAudioIndex > audioList.count-1  {
            currentAudioIndex = 0
            audioPlayingCondition()
            return
        }
        
        audioPlayingCondition()
        
    }
    
    func playPreviousAudio() {
        currentAudioIndex -= 1
        
        if currentAudioIndex < 0  {
            currentAudioIndex = audioList.count-1
            audioPlayingCondition()
            return
        }
        
        audioPlayingCondition()
        
    }
    
    
    /*
    func stopAudio() {
        audioPlayer.stop()
    }
    
    func pauseAudio() {
        audioPlayer.pause()
    }
    */
    
    
    
    //MARK: - SWITCH BUTTONS
    func switchPlayPauseButton() {
       
        let playIcon = UIImage(named: "i-play")
        let pauseIcon = UIImage(named: "i-pause")
       
        audioPlayer.isPlaying ? playButton.setImage(pauseIcon, for: UIControl.State()) : playButton.setImage(playIcon, for: UIControl.State())
    }
    
    
    /*
    //if wanna keep user's last clicked on shuffle or repeate button to put on viewdidload
    func setRepeatAndShuffle() {
        shuffleState = UserDefaults.standard.bool(forKey: "shuffleState")
        repeatState = UserDefaults.standard.bool(forKey: "repeatState")
        
        shuffleState ? (shuffleButton.isSelected = true) : (shuffleButton.isSelected = false)
        repeatState ? (repeatButton.isSelected = true) : (repeatButton.isSelected = false)
    }
    */
    
    
    
    //MARK: - UPDATE UI LABELS
    func updateAudioLabels() {
        audioNameLabel.text =  getAudioName(currentAudioIndex)
        authorNameLabel.text = getAuthorName(currentAudioIndex)
        audioImage.image = UIImage(named: getAudioImage(currentAudioIndex))
        
    }
    
    
    func assignSliderUI() {
        let minImage = UIImage(named: "slider-track-fill")
        let maxImage = UIImage(named: "slider-track")
        let thumb = UIImage(named: "slider-thumb")
        
        playerAudioSlider.setMinimumTrackImage(minImage, for: UIControl.State())
        playerAudioSlider.setMaximumTrackImage(maxImage, for: UIControl.State())
        playerAudioSlider.setThumbImage(thumb, for: UIControl.State())
    }
    
    
    
    
    //MARK: - TIME CALCULATE
    func convertTime(_ duration: TimeInterval) ->(hour: String, minute: String, second: String) {
        let intHour = abs(Int((duration/3600).truncatingRemainder(dividingBy: 60)))
        let intMinute = abs(Int((duration/60).truncatingRemainder(dividingBy: 60)))
        let intSecond = abs(Int(duration.truncatingRemainder(dividingBy: 60)))
        
        let hour = intHour > 9 ? "\(intHour)" : "0\(intHour)"
        let minute = intMinute > 9 ? "\(intMinute)" : "0\(intMinute)"
        let second = intSecond > 9 ? "\(intSecond)" : "0\(intSecond)"
        
        return (hour, minute, second)
    }
    
    func calculateAudioLength() {
        let time = convertTime(audioLength)
        totalAudioLength = "\(time.hour):\(time.minute):\(time.second)"
    }
    
    func showTotalSongLength(){
        calculateAudioLength()
        totalAudioLengthLabel.text = totalAudioLength
    }
    
    func startTimer() {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.update(_:)), userInfo: nil, repeats: true)
            timer.fire()
    }
    
    
    func stopTimer() {
        timer.invalidate()
    }
    
    @objc func update(_ timer: Timer) {
        if !audioPlayer.isPlaying {
            return
        }
        else {
            let time = convertTime(audioPlayer.currentTime)
            
            processTimerLabel.text = "\(time.hour):\(time.minute):\(time.second)"
            playerAudioSlider.value = Float(audioPlayer.currentTime)
            UserDefaults.standard.set(playerAudioSlider.value, forKey: "playerAudioSliderValue")
        }

    }
    
    func retrievePlayAudioSliderValue(){
        let playerAudioSliderValue = UserDefaults.standard.float(forKey: "playerAudioSliderValue")

        if playerAudioSliderValue != 0 {
            playerAudioSlider.value = playerAudioSliderValue
            audioPlayer.currentTime = TimeInterval(playerAudioSliderValue)
            
            let time = convertTime(audioPlayer.currentTime)
            processTimerLabel.text = "\(time.hour):\(time.minute):\(time.second)"
            playerAudioSlider.value = Float(audioPlayer.currentTime)
        }
        else {
            playerAudioSlider.value = 0.0
            audioPlayer.currentTime = 0.0
            processTimerLabel.text = "00:00:00"
        }
    }
    
    
    
    //MARK: - Audioplayer DELEGATE CALLBACK
    
    func getRandomIndex() {
        var randomIndex = 0
        var newIndex = false
        while newIndex == false {
            randomIndex = Int(arc4random_uniform(UInt32(audioList.count)))
            shuffleArray.contains(randomIndex) ? (newIndex = false) : (newIndex = true)
        }
        currentAudioIndex = randomIndex
        print("+++++++randomeindex: \(randomIndex)+++++++")
    }
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag == true {
            if shuffleState == false && repeatState == false {
                if currentAudioIndex != audioList.count-1 {
                    playNextAudio()
                    playButton.setImage(UIImage(named: "i-pause"), for: UIControl.State())
                    playAudio()
                }
                else {
                    playButton.setImage(UIImage(named: "i-play"), for: UIControl.State())
                    return
                }
            }
            else if shuffleState == false && repeatState == true {
                prepareAudio()
                playAudio()
            }
            else if shuffleState == true && repeatState == false {
                //shuffle audios till all the audios are played
                shuffleArray.append(currentAudioIndex)
                if shuffleArray.count >= audioList.count {
                    playButton.setImage(UIImage(named: "i-play"), for: UIControl.State())
                    shuffleButton.isSelected = false
                    shuffleArray.removeAll()
                    shuffleState = false
                    return
                }
                getRandomIndex()
                prepareAudio()
                playAudio()
                
            }
            else if shuffleState == true && repeatState == true {
                //shuffle audios and play on loop FOREVER
                 shuffleArray.append(currentAudioIndex)
                if shuffleArray.count >= audioList.count {
                    shuffleArray.removeAll()
                }
                getRandomIndex()
                prepareAudio()
                playAudio()
                
            }
            
        }
    }
    
    
    
    
    //MARK: - GET AUDIOS
    func getAudioData() {
        let path = Bundle.main.path(forResource: "list", ofType: "plist")
        audioList = NSArray(contentsOfFile: path!)
    }
    
    
    func getAudioName(_ indexNumber: Int) -> String {
        getAudioData()
        
        let audioName = (audioList![indexNumber] as! NSDictionary).value(forKey: "audioName")
        //print (audioName!)
        return audioName as! String
        
        //var audioDataDict = NSDictionary()
        //audioDataDict = audioList.object(at: indexNumber) as! NSDictionary
        //let audioName = audioDataDict.value(forKey: "audioName") as! String
        //return audioName
    }
    
    func getAuthorName(_ indexNumber: Int) -> String {
        getAudioData()
        
        let authorName = (audioList![indexNumber] as! NSDictionary).value(forKey: "authorName")
        return authorName as! String
        
        //var audioDataDict = NSDictionary()
        //audioDataDict = audioList.object(at: indexNumber) as! NSDictionary
        //let authorName = audioDataDict.value(forKey: "authorName") as! String
        //return authorName
    }
    
    func getAudioImage(_ indexNumber: Int) -> String {
        getAudioData()
        
        let audioImage = (audioList![indexNumber] as! NSDictionary).value(forKey: "audioImage")
        return audioImage as! String
        
        
        //var audioDataDict = NSDictionary()
        //audioDataDict = audioList.object(at: indexNumber) as! NSDictionary
        //let audioImage = audioDataDict.value(forKey: "audioImage") as! String
        //return audioImage
    }
    
    
    
    
    //MARK: - TAP GUESTURE
    @IBAction func swipeLeft(_ sender: UISwipeGestureRecognizer) {
        next(self)
    }
    
    
    @IBAction func swipeRight(_ sender: UISwipeGestureRecognizer) {
        previous(self)
    }
    
    
    
    //MARK: - IBActions
    @IBAction func play(_ sender : AnyObject) {
        if shuffleState == true {
            shuffleArray.removeAll()
        }
        if audioPlayer.isPlaying {
            //pauseAudio()
            audioPlayer.pause()
            switchPlayPauseButton()
        }
        else {
            playAudio()
            switchPlayPauseButton()
        }
        
    }
    

    @IBAction func next(_ sender : AnyObject) {
        playNextAudio()
    }
    
    @IBAction func previous(_ sender : AnyObject) {
        playPreviousAudio()
    }
    
    @IBAction func sliderDraggingLocation(_ sender: UISlider) {
        audioPlayer.currentTime = TimeInterval(sender.value)
    }
    
    @IBAction func presentAudioList(_ sender : AnyObject) {
        if effectToggle {
            isTableViewOnScreen = true
            self.tableViewOnScreen()
        }
        else {
            self.tableViewOffScreen()
        }
         effectToggle = !effectToggle
    }
    
    @IBAction func repeatButtonClicked(_ sender : UIButton) {
        if sender.isSelected == true {
            sender.isSelected = false
            repeatState = false
            UserDefaults.standard.set(false, forKey: "repeatState")
        }
        else {
            sender.isSelected = true
            repeatState = true
            UserDefaults.standard.set(false, forKey: "repeatState")
        }
    }
    
    @IBAction func shuffleButtonClicked(_ sender: UIButton) {
        shuffleArray.removeAll()
        if sender.isSelected == true {
            sender.isSelected = false
            shuffleState = false
            UserDefaults.standard.set(false, forKey: "shuffleState")
        }
        else {
            sender.isSelected = true
            shuffleState = true
            UserDefaults.standard.set(false, forKey: "shuffleState")
        }
    }
}

