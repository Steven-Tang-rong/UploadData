//
//  ViewController.swift
//  UploadData
//
//  Created by TANG,QI-RONG on 2021/2/23.
//

import UIKit
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var mainTableView: UITableView!
    var authHandler: AuthStateDidChangeListenerHandle!
    var dataKeys = [String]()
    var namesDictionary = [String: [String]]()
    
    
    var activityIndicatorView: UIActivityIndicatorView!
    func initUI() {
        self.activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        self.activityIndicatorView.hidesWhenStopped = true
        self.activityIndicatorView.transform = CGAffineTransform(scaleX: 2.5, y: 2.5)
        self.activityIndicatorView.color = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        self.activityIndicatorView.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        self.activityIndicatorView.layer.cornerRadius = 20
        self.view.addSubview(self.activityIndicatorView)
    }
    
    func setUI() {
        self.activityIndicatorView.center = self.view.center
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let dataQueue = DispatchQueue(label: "com.dataQueue", qos: .userInteractive, attributes: .concurrent)
        
        dataQueue.async {
            self.authHandler = Auth.auth().addStateDidChangeListener({ (auth: Auth, user: User?) in
                if user != nil {
                    if self.dataKeys.isEmpty {
                        let driverNameRef = Database.database().reference(withPath: "tesla/driver")
                        driverNameRef.observe(.value) { (Snapshot: DataSnapshot) in
                            if let driverNameValue = Snapshot.value as? [String: [String:String]] {
                                //將無序的Dic轉換成有序的Array
                                self.dataKeys = Array(driverNameValue.keys).sorted()
                                for key in self.dataKeys {
                                    var names = [String]()
                                    let keyGroup = driverNameValue[key]!
                                    for(_, driversName) in keyGroup {
                                        names.append(driversName)
                                    }
                                    self.namesDictionary[key] = names
                                }
                            }
                            self.mainTableView.reloadData()
                        } //observe
                    } //dataKeys.isEmpty
                    Auth.auth().signInAnonymously { (authDataResult: AuthDataResult?, error: Error?) in
                        guard let driver = authDataResult, error == nil else {
                            print("登入失敗")
                            return
                        }
                        print("登入ID: \(driver.user.uid)")
                    }
                } //user
            })
        }
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(authHandler)
        
        
        }
    
    


}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainTableView.dataSource = self
        mainTableView.delegate = self

        DispatchQueue.main.async {
            self.initUI()
            self.setUI()
            self.activityIndicatorView.startAnimating()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if dataKeys.isEmpty {
            return 1
        }
        
        return self.dataKeys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if dataKeys.isEmpty {
            return 1
        }
        
        let key = dataKeys[section]
        let names = namesDictionary[key]!
        return names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "DataCell"
        
        if dataKeys.isEmpty{
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            //cell.textLabel?.text = "正在下載資料"

            return cell
        }
        
        self.activityIndicatorView.stopAnimating()
        let key = dataKeys[indexPath.section]
        let names = namesDictionary[key]!
        let driverName = names[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = driverName
        return cell
    }
    
      //與 viewForHeaderInSection 擇一使用
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if dataKeys.isEmpty {
            return nil
        }else {
            return dataKeys[section]
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if dataKeys.isEmpty {
            return nil
        }
        
        let key = dataKeys[section]
        let nib = UINib(nibName: "TitleView", bundle: nil)
        let views = nib.instantiate(withOwner: self, options: nil)
        let view = views[0] as! TitleView
        view.titleLabel.text = key
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if dataKeys.isEmpty{
            return nil
        }else {
            return dataKeys
        }
    }
    
}

