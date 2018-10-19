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
    
    @IBOutlet weak var repeateButton: UIButton!
    
    @IBOutlet weak var listButton: UIButton!
    
    
    @IBOutlet weak var tableViewContainer : UIView!
    
    @IBOutlet weak var tableView : UITableView!
    
    @IBOutlet weak var blurView : UIVisualEffectView!
    
    @IBOutlet weak var tableViewContainerTopConstrain: NSLayoutConstraint!
    
    
    //MARK: - OVERRIDE FUNCS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //backgroundImage.image =  UIImage(named: "blueGradient")
        
        retrieveSavedTrackNumber()
        prepareAudio()
        updateAudioLabels()
        setRepeatAndShuffle()
        
        //assignSliderUI()
        //retrievePlayerSliderValue()
        
//        blurView.isHidden = true
//        tableView.isHidden = true
//        tableViewContainer.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        blurView.isHidden = false
        effectToggle = !effectToggle
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
        
        print("audioNameDict: \(audioNameDict)")
        
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
        
        let bgView = UIView(frame: CGRect.zero)
        bgView.backgroundColor = UIColor.clear
        
        cell.backgroundView = bgView
        cell.backgroundColor = UIColor.clear
    }
    
    
    //MARK: - tableViewDelegate
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
    
    
    
    //MARK: - animate tableViewlist on/off screen
    
    func tableViewOnScreen() {
        self.blurView.isHidden = false
        self.tableViewContainer.isHidden = false
//        UIView.animate(withDuration: 0.15, delay: 0.01, options:
//            UIView.AnimationOptions.curveEaseIn, animations: {
//                self.tableViewContainer.layoutIfNeeded()
//        }, completion: {(bool) in
//        })
    }
    
    func tableViewOffScreen() {
        self.blurView.isHidden = true
        self.tableViewContainer.isHidden = true
        isTableViewOnScreen = false
//        UIView.animate(withDuration: 0.20, delay: 0.0, options:
//            UIView.AnimationOptions.curveEaseOut, animations: {
//                self.tableViewContainer.layoutIfNeeded()
//        }, completion: {
//            (value: Bool) in
//            self.blurView.isHidden = true
//        })
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
    
    
    
    //MARK: - pepare audios
    func prepareAudio() {
        setCurrentAudioPath()
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
        audioPlayer.prepareToPlay()
        processTimerLabel.text = "00:00"
        
        //showTotalSongLength()
        updateAudioLabels()

        
    }
    
    
    
    //MARK: - audios controls set up
    func playAudio() {
        audioPlayer.play()
        //startTimer()
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
    
    func stopAudio() {
        audioPlayer.stop()
    }
    
    func pauseAudio() {
        audioPlayer.pause()
    }
    
    
    
    //MARK: - SWITCH BUTTONS
    func switchPlayPauseButton() {
       
        let playIcon = UIImage(named: "i-play")
        let pauseIcon = UIImage(named: "i-pause")
       
        audioPlayer.isPlaying ? playButton.setImage(pauseIcon, for: UIControl.State()) : playButton.setImage(playIcon, for: UIControl.State())
    }
    
    func setRepeatAndShuffle() {
        shuffleState = UserDefaults.standard.bool(forKey: "shuffeStatte")
        repeatState = UserDefaults.standard.bool(forKey: "repeatState")
        
        shuffleState ? (shuffleButton.isSelected = true) : (shuffleButton.isSelected = false)
        repeatState ? (repeateButton.isSelected = true) : (repeateButton.isSelected = false)
    }
    
    
    
    
    //MARK: - get data from plist
    func getAudioData() {
        let path = Bundle.main.path(forResource: "list", ofType: "plist")
        audioList = NSArray(contentsOfFile: path!)
        //print (audioList)
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
    
    
    //MARK: - UPDATE UI Labels
    func updateAudioLabels() {
        audioNameLabel.text =  getAudioName(currentAudioIndex)
        authorNameLabel.text = getAuthorName(currentAudioIndex)
        audioImage.image = UIImage(named: getAudioImage(currentAudioIndex))
        
    }
    
    
    //MARK: - IBActions
    

    @IBAction func play(_ sender : AnyObject) {
        if shuffleState == true {
            shuffleArray.removeAll()
        }
        if audioPlayer.isPlaying {
            pauseAudio()
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
}

