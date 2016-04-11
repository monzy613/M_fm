//
//  FMLoginViewController.swift
//  M_fm
//
//  Created by 张逸 on 16/4/11.
//  Copyright © 2016年 MonzyZhang. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class FMLoginViewController: UIViewController {
    var channels = [DBChannel]()
    var channelSongDictionary = [DBChannel: DBSongList]()
    var currentTrack: DBSong?
    var downloadButton: MZButtonProgressView!
    var hasDownload = false

    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var trackImageView: UIImageView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressViewWidthConstraint: NSLayoutConstraint!

    //IBActions
    @IBAction func playButtonPressed(sender: UIButton) {
    }
    
    @IBAction func nextButtonPressed(sender: UIButton) {
    }

    func downloadButtonPressed(sender: MZButtonProgressView) {
        if hasDownload == true {
            return
        } else {
            sender.transformToPrograssBar()
            hasDownload = true
        }
        print("downloadButtonPressed")
        Alamofire.download(.GET, (self.channelSongDictionary[self.channels[1]]?.songs[0].mp3URL)!) { (tmpURL, res) -> NSURL in
            let fileManager = NSFileManager.defaultManager()
            let directoryURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            let pathComponent = res.suggestedFilename
            let storePath = directoryURL.URLByAppendingPathComponent(pathComponent ?? "")
            print(storePath)
            return storePath
        }.progress { (bytesRead, totalBytesRead, totalBytesExpectedToRead) in
            dispatch_async(dispatch_get_main_queue(), {
                let progress = CGFloat(Float(totalBytesRead) / Float(totalBytesExpectedToRead))
                self.downloadButton.updateProgress(progress)
            })
        }.response { (req, res, data, error) in
            if let error = error {
                print("download error: \(error)")
            } else {
                print("Download file successfully")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initDownloadButton()
        self.trackImageView.clipsToBounds = true
        Alamofire.request(.GET, DBURL.getChannels).responseJSON {
            res in
            let json = JSON(res.result.value ?? [])
            if let err = res.result.error {
                print("err: \(err)")
            } else if let channels = json["channels"].array {
                for channel in channels {
                    let channelModel = DBChannel(withJSON: channel)
                    self.channels.append(channelModel)
                }
                let testChannelID = self.channels[1].channel_id
                Alamofire.request(.GET, DBURL.getMusicWithChannel(testChannelID)).responseJSON {
                    res in
                    let json = JSON(res.result.value ?? [])
                    if let err = res.result.error {
                        print(err)
                    } else {
                        let songList = DBSongList(withJSON: json)
                        self.channelSongDictionary[self.channels[1]] = songList
                        let picURL = self.channelSongDictionary[self.channels[1]]?.songs[0].pictureURL
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                            let trackImage = UIImage.download(withURL: picURL ?? "")
                            dispatch_async(dispatch_get_main_queue()) {
                                self.trackImageView.image = trackImage
                            }
                        }
                    }
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let width = self.trackImageView.frame.width
        self.trackImageView.layer.cornerRadius = width / 2
    }

    private func initDownloadButton() {
        let width = self.playerView.frame.height * 0.8
        let progressBarLength = width * 3
        downloadButton = MZButtonProgressView(frame: CGRectMake(0, 0, width, width), progressBarLength: progressBarLength)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.addTarget(self, action: #selector(downloadButtonPressed), forControlEvents: .TouchUpInside)
        downloadButton.setImage(UIImage(named: "download"), forState: .Normal)
        downloadButton.endImage = UIImage(named: "tick")
        self.view.addSubview(downloadButton)
        self.view.addConstraints([
            NSLayoutConstraint(item: downloadButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1.0, constant: width),
            NSLayoutConstraint(item: downloadButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1.0, constant: width),
            NSLayoutConstraint(item: downloadButton, attribute: .CenterX, relatedBy: .Equal, toItem: playerView, attribute: .CenterX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: downloadButton, attribute: .Bottom, relatedBy: .Equal, toItem: playerView, attribute: .Top, multiplier: 1.0, constant: -20.0)
            ])
    }
}
