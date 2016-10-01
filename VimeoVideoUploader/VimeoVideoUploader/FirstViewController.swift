//
//  FirstViewController.swift
//  VimeoVideoUploader
//
//  Created by Mohd Haider on 30/09/16.
//  Copyright © 2016 InstantSystemsInc. All rights reserved.
//

import UIKit


class FirstViewController: UIViewController {

    struct Constants {
        
        static let kVimeoClientID           = "6300c90752c2b19ad76aee440b9d41200c231f55"
        static let kVimeoClientSecret       = "f967d7bd9ce2c39cf9d2cb0869dee7966b8d3a39"
        static let kVimeoAccessToken        = "1167295e3bad07fca8e12b252eae5b9a"
        static let kVimeoAccessTokenSecret  = "f112e64223dbf38bb99609693c3747ba19483417"
        
        static let kVimeoHeaderInputAccept  = "application/vnd.vimeo.*+json; version=3.2"
        
        static let kVimeoScope          = "public private create edit delete interact upload"
        static let kVimeoRedirectUrl    = "vimeoaff6eaaa1ce5e667daea4066adcdf3793f52108b://auth"
        
        
        static let KeychainAccessGroup        = "GoldCleatsAccessGroup"
        static let KeychainService            = "GoldCleatsKeychain"
        
        static let BackgroundSessionIdentifierApp = "instantsys_goldcleats"
        static let BackgroundSessionIdentifierExtension = "goldCleats"; // Must be different from BackgroundSessionIdentifierApp
        static let SharedContainerID = "GoldCleats_Shared_ID"
        
        static let kClientEmail = "ahmads@goldcleats.com"
        static let kClientPassword = "syd-hid-paid"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.lightGrayColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    @IBAction func btnPressed(sender: UIButton) {
        
        print("\(#function), \(#line)");
        
        self.authenticateVimeoAccount()
    }
    
    
    // MARK: - Vimeo Test
    
    func authenticateVimeoAccount() -> Void {
        
        let appConfiguration = AppConfiguration(
            clientIdentifier: Constants.kVimeoClientID,
            clientSecret: Constants.kVimeoClientSecret,
            scopes: [.Public, .Private, .Interact, .Edit, .Delete, .Upload, .Create]
        )
        
        let vimeoClient = VimeoClient(appConfiguration: appConfiguration)
        
        if vimeoClient.isAuthenticated {
            self.getAllVimeoVideos(vimeoClient)
        }
        else {
            let authenticationController = AuthenticationController(client: vimeoClient)
            authenticationController.accessToken(Constants.kVimeoAccessToken) { result in
                switch result
                {
                case .Success(let account):
                    
                    print("authenticated successfully: \(account)")
                    self.getAllVimeoVideos(vimeoClient)
                    
                case .Failure(let error):
                    
                    print("failure authenticating: \(error)")
                }
            }
        }
    }
    
    func getAllVimeoVideos(vimeoClient: VimeoClient?) -> Void {
        
        print("\(#function), \(#line)");
        
        if let client = vimeoClient {
            
            let videoRequest = Request<VIMModelObject>(path: "/me/videos?page=1")
            
            client.request(videoRequest) { result in
                switch result {
                case .Success(let response):
                    
                    print("response = \(response)")
                    
                    //let video: VIMVideo = response.model
                    //print("retrieved video: \(video)")
                case .Failure(let error):
                    print("error retrieving video: \(error)")
                }
            }
        }
    }

}
