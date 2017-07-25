//
//  GalleryImageViewController.swift
//  AVFoundationExample
//
//  Created by Bindu on 12/07/17.
//  Copyright © 2017 Xminds. All rights reserved.
//


import UIKit
import Photos
import AVKit
import AVFoundation

class GalleryImageViewController: UIViewController ,UICollectionViewDelegate , UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    let Album_Title = "CamCam"
    var photosAsset: PHFetchResult<AnyObject>!
    var assetCollection: PHAssetCollection!
    let imageManager = PHCachingImageManager()
    var localVideoUrl = NSURL()
    var player = AVPlayer()
    var asset = PHAsset()
    var timer : Timer?
    var playDuration : CMTime?
    var playerLayer : AVPlayerLayer?
    let progressview = UIProgressView()
    var pauseTime : CMTime?
    @IBOutlet var imageCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        pauseTime = CMTimeMake(0, 1)
        var albumFound = false
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", Album_Title)
        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let first_obj:Any = collection.firstObject {
            albumFound = true
            print(first_obj)
        }
        
        if albumFound {
            
            photosAsset = PHAsset.fetchAssets(in: assetCollection, options: nil) as! PHFetchResult<AnyObject>
            
            print(photosAsset.count)
            imageCollectionView.reloadData()
            
            let indexPath = IndexPath(row: photosAsset.count-1, section: 0)
            
            imageCollectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: false)
        }
        
    }
    
    //MARK: - UICollectionView DataSource and Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosAsset.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell : ImageCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageCollectionViewCell
        
        asset = photosAsset.object(at: indexPath.row) as! PHAsset
    
        let videoOptions: PHVideoRequestOptions = PHVideoRequestOptions()
        videoOptions.version = .original
    
        if (asset.mediaType == PHAssetMediaType.video) {
            
            cell.playButton.isHidden = false;
            cell.playButton.tag = indexPath.row
            PHImageManager.default().requestAVAsset(forVideo: asset, options: videoOptions) { (asset, audioMix, info) in
                
                if let urlAsset = asset as? AVURLAsset {
                    self.localVideoUrl = urlAsset.url as NSURL
                }
            }
        } else {
            cell.playButton.isHidden = true;
        }
        
        let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = true
        
        imageManager.requestImage(for: asset , targetSize: imageSize, contentMode: .aspectFill, options: options, resultHandler: { (result, info) in
            DispatchQueue.main.async {
                cell.gallerImageView.image = result
            }
        })
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize.init(width:  UIScreen.main.bounds.size.width, height:  UIScreen.main.bounds.size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UIButton Actions
    
    @IBAction func playButtonClicked(_ sender: UIButton) {
        
        let indexPath = IndexPath(row: sender.tag, section: 0)
        let cell: ImageCollectionViewCell = imageCollectionView.cellForItem(at: indexPath) as! ImageCollectionViewCell
        
        if player.rate != 0 && player.error == nil {
            
            player.pause()
            pauseTime = player.currentTime()
            cell.bringSubview(toFront: cell.playButton)
            
        } else {
            
            if (CMTimeGetSeconds(pauseTime!) != 0) {
                
                player.seek(to: pauseTime!, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
                player.play()
                
            } else {
                let asset = AVURLAsset(url: localVideoUrl as URL)
                
                let playerItem = AVPlayerItem(asset: asset)
                
                player = AVPlayer(playerItem: playerItem)
                
                NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(play:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
                
                playerLayer = AVPlayerLayer(player: player)
                playerLayer?.frame = self.view.bounds
                cell.layer.addSublayer(playerLayer!)
                
                progressview.isHidden = false
                
                progressview.frame = CGRect(x:10, y:UIScreen.main.bounds.size.height-30, width:UIScreen.main.bounds.width-20, height:20)
                progressview.progress = 0
                progressview.progressTintColor = UIColor.red
                progressview.trackTintColor = UIColor.blue
                cell.addSubview(progressview)
                
                player.play()
                
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(syncScrubber), userInfo: nil, repeats: true)
                timer?.fire()
            }
        }
    }
    
    //MARK: - Methods
    
    func playerItemDuration() -> CMTime {
        
        if (player.currentItem?.status == AVPlayerItemStatus.readyToPlay) {
            
            return(player.currentItem?.duration)!
        }
        return(kCMTimeInvalid);
    }
    
    func syncScrubber() {
        
        let playDuration  :CMTime = playerItemDuration()
        
        let duration = CMTimeGetSeconds(playDuration)
        let progressTime = Float64(CMTimeGetSeconds(player.currentTime()))
        
        
        if (duration.isFinite && duration>0 && (progressTime != duration)) {
            
            print("progress time :\(progressTime)")
            progressview.progress=Float(progressTime/duration)
        } else {
            progressview.progress=1
        }
    }
    
    func itemDidFinishPlaying(play:AVPlayer) {
        
        pauseTime = CMTimeMake(0, 1)
        player.pause()
        player.replaceCurrentItem(with: nil)
        playerLayer?.removeFromSuperlayer()
        
        if (timer != nil) {
            progressview.isHidden = true
            progressview.removeFromSuperview()
            timer?.invalidate()
            timer=nil
        }
        
    }
    //MARK: - Pinch Gesture
    
    
    @IBAction func dismiss(_ sender: UIPinchGestureRecognizer) {
        
        self.dismiss(animated: false, completion: nil)
    }
    
    //MARK: - Scrollview Delegate
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        itemDidFinishPlaying(play: player)
        
        let pageWidth : CGFloat = imageCollectionView.frame.size.width
        let currentPage:Int = Int(imageCollectionView.contentOffset.x/pageWidth)
        
        let indexPath = IndexPath(row: currentPage, section: 0)
        imageCollectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: true)
        
        asset = photosAsset.object(at: currentPage) as! PHAsset
        let videoOptions: PHVideoRequestOptions = PHVideoRequestOptions()
        videoOptions.version = .original
        
        if (asset.mediaType == PHAssetMediaType.video) {
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: videoOptions) { (asset, audioMix, info) in
                
                if let urlAsset = asset as? AVURLAsset {
                    self.localVideoUrl = urlAsset.url as NSURL
                }
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
