//
//  FanUserInfoTableViewController.swift
//  FanHealthKit
//
//  Created by 向阳凡 on 15/11/27.
//  Copyright © 2015年 向阳凡. All rights reserved.
//

import UIKit
import HealthKit

class FanUserInfoTableViewController: UITableViewController {
    
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var sexLabel: UILabel!
    @IBOutlet weak var BloodLabel: UILabel!
    
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var bodyBMILabel: UILabel!
    
    
    
    var healthManager:FanHealthManager?
    /// 身高体重等
    var height,weight:HKQuantitySample?
    //身高体重指数
    var bmi=0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.title="个人身体数据"

        self.updateUserInfo();
    }
    
    func updateUserInfo(){
        //读取个人信息（年龄，性别，血液类型）
        updateProfile()
        //更新体重
        updateWeight()
        //更新身高
        updateHeight()
//        //更新身高体重指数
//        updateBMI()
//        let time=dispatch_time(DISPATCH_TIME_NOW, Int64(3*NSEC_PER_SEC));
//        dispatch_after(time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//            self.updateBMI()
//        });
    }
    func updateProfile(){
        //读取个人信息（年龄，性别，血液类型）
        let profile=healthManager?.readProfile();
        ageLabel.text="\(profile?.age==nil ? 0 : profile!.age!)";
        sexLabel.text=self.biologicalSexLiteral(profile?.sex?.biologicalSex);
        BloodLabel.text=self.bloodTypeLiteral(profile?.bloodType?.bloodType);
    }
    
    func updateWeight(){
        var weightLocalizedString = "无数据";
        
        let sampleType=HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)
        self.healthManager?.readMostRecentSample(sampleType!, completion: { (mostRecentWeight, error) -> Void in
            if error != nil {
                print("读取体重出错: \(error?.localizedDescription)")
            }
            self.weight = mostRecentWeight as? HKQuantitySample
            
            if let kilograms = self.weight?.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo)) {
                let weightFormatter = MassFormatter()
                weightFormatter.isForPersonMassUse = true;
                weightLocalizedString = weightFormatter.string(fromKilograms: kilograms)
            }
            // 主线程更新（因为healthKit是线程操作）
            DispatchQueue.main.async(execute: { () -> Void in
                self.weightLabel.text = weightLocalizedString
                //更新体重指数
                self.updateBMI()
            });
        })
    }
    
    func updateHeight(){
        var heightLocalizedString = "无数据";
        
        let sampleType=HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)
        self.healthManager?.readMostRecentSample(sampleType!, completion: { (mostRecentHeight, error) -> Void in
            if error != nil {
                print("读取身高出错: \(error?.localizedDescription)")
            }
            self.height = mostRecentHeight as? HKQuantitySample
            
            if let meters = self.height?.quantity.doubleValue(for: HKUnit.meter()) {
                let heightFormatter = LengthFormatter()
                heightFormatter.isForPersonHeightUse = true;
                heightLocalizedString = heightFormatter.string(fromMeters: meters)
            }
            // 主线程更新（因为healthKit是线程操作）
            DispatchQueue.main.async(execute: { () -> Void in
                self.heightLabel.text = heightLocalizedString
                //更新体重指数
                self.updateBMI()
            });
        })
    }
    
    func updateBMI(){
        var weightInKilograms:Double=0
        var heightInMeters:Double=0
        if weight != nil && height != nil {
            weightInKilograms = weight!.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            heightInMeters = height!.quantity.doubleValue(for: HKUnit.meter())
        }
        DispatchQueue.main.async { () -> Void in
            if heightInMeters != 0 {
                self.bmi=weightInKilograms/heightInMeters
                self.bodyBMILabel.text =  String(format: "%.02f%%", self.bmi)
            }else{
                self.bodyBMILabel.text = "无数据"
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if (section == 0 || section == 1) {
            return 3
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            //重新加载数据
            updateUserInfo();
        }else if indexPath.section == 3 {
            if bmi > 0.0 {
                healthManager?.saveBMISample(bmi, date: Date())
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    // MARK: - 辅助方法
   //血型转字符串
    func bloodTypeLiteral(_ bloodType:HKBloodType?)->String{
        
        var bloodTypeText = "未设置";
        
        if bloodType != nil {
            
            switch( bloodType! ) {
            case .aPositive:
                bloodTypeText = "A+"
            case .aNegative:
                bloodTypeText = "A-"
            case .bPositive:
                bloodTypeText = "B+"
            case .bNegative:
                bloodTypeText = "B-"
            case .abPositive:
                bloodTypeText = "AB+"
            case .abNegative:
                bloodTypeText = "AB-"
            case .oPositive:
                bloodTypeText = "O+"
            case .oNegative:
                bloodTypeText = "O-"
            default:
                break;
            }
        }
        return bloodTypeText;
    }
    //性别转换
    func biologicalSexLiteral(_ biologicalSex:HKBiologicalSex?)->String{
        var sexString="未设置"
        if  biologicalSex != nil {
            switch biologicalSex! {
            case .female :
                sexString="女"
                break
            case .male:
                sexString="男"
                break
            case .other:
                sexString="变性人"
                break
            default:
                break;
            }
        }
        return sexString;
    }
}
