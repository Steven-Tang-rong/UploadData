//
//  AppDelegate.swift
//  UploadData
//
//  Created by TANG,QI-RONG on 2021/2/23.
//

import UIKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let sortedNameFile = "sortednames.plist"
    var authHandler: AuthStateDidChangeListenerHandle!
    override init() {
        super.init()
        FirebaseConfiguration.shared.setLoggerLevel(FirebaseLoggerLevel.min)
        FirebaseApp.configure()
    }
    
    
    
    //上傳
    func uploadDataToFirebase(userNameReference: DatabaseReference, plistName: String) {
        if let fileURL = Bundle.main.url(forResource: "sortednames", withExtension: "plist") {
            guard let sortedNames = NSDictionary(contentsOf: fileURL) as? [String: [String]] else {
                print("解析失敗")
                return
            }
            let uploadQueue = DispatchQueue(label: "uploadDataQueue")
            uploadQueue.async {
                for (key, value) in sortedNames {
                    print("Key: \(key)")
                    for name in value {
                        userNameReference.child(key).childByAutoId().setValue(name)
                    }
                }
            }
        }
    }
    
    func checkHasData() {
        let userNameReference = Database.database().reference(withPath: "tesla/driver")
        userNameReference.observeSingleEvent(of: .value) { (dataSnapshot: DataSnapshot) in
            if dataSnapshot.hasChildren() {
                print("有資料")
            }else {
                print("尚無資料")
                self.uploadDataToFirebase(userNameReference: userNameReference, plistName: self.sortedNameFile)
            }
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        authHandler = Auth.auth().addStateDidChangeListener({ (auth: Auth, user: User?) in
            guard let user = user else {
                print("沒有登入")
                print("準備登入")
                
                Auth.auth().signInAnonymously { (authDataResult: AuthDataResult?, error: Error?) in
                    guard let result = authDataResult, error == nil else {
                        print("登入失敗")
                        return
                    }
                    print("使用者ID： \(result.user.uid)")
                    Auth.auth().removeStateDidChangeListener(self.authHandler) //以免佔用記憶體
                    self.checkHasData()
                }
                return //guard let user
            }
            print("已登入。ID: \(user.uid)")
            self.checkHasData()
        }) //authHandler
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

