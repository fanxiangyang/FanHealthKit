//
//  FanWorkoutTableViewController.swift
//  FanHealthKit
//
//  Created by 向阳凡 on 15/11/26.
//  Copyright © 2015年 向阳凡. All rights reserved.
//

import UIKit
import HealthKit

class FanWorkoutTableViewController: UITableViewController {
    
    var healthManager:FanHealthManager?
    
    var workouts = [HKWorkout]()
    
    // MARK: - Formatters
    /// 日期格式化
    lazy var dateFormatter:DateFormatter = {
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter;
        
    }()
    /// 时间格式化
    let durationFormatter = DateComponentsFormatter()
    /// 能量格式化
    let energyFormatter = EnergyFormatter()
    /// 长度格式化
    let distanceFormatter = LengthFormatter()


    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
         let addBar = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(FanWorkoutTableViewController.addRunningWorkout))
        let refreshBar = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(FanWorkoutTableViewController.refreshRunningHealthKit))
        self.navigationItem.rightBarButtonItems=[addBar,refreshBar]
        
        self.title="运动数据刷新/添加"
        
        //刷新
        refreshRunningHealthKit()
    }
    /**
     请求运动数据
     */
    func refreshRunningHealthKit(){
        healthManager?.readRunningWorkOuts({ (results, error) -> Void in
            if( error != nil ){
                print("Error reading workouts: \(error?.localizedDescription)")
                return;
            }else{
                print("Workouts read successfully!")
            }
            self.workouts.removeAll()
            self.workouts = results as! [HKWorkout]
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
            });
        })
    }
    /**
     添加一个运动
     */
    func addRunningWorkout(){
        var hkUnit = HKUnit.meterUnit(with: .kilo)//千米
        hkUnit = HKUnit.mile()//米
        // 2. 保存
        self.healthManager?.saveRunningWorkout(Date(timeIntervalSinceNow: -1800), endDate: Date(timeIntervalSinceNow: 0), distance: 2000 , distanceUnit:hkUnit, kiloCalories: 1000, completion: { (success, error ) -> Void in
            if( success )
            {
                print("Workout saved!")
            }  
            else if( error != nil ) {  
                print("\(error)")  
            }  
        })
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.workouts.count
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WorkCell", for: indexPath)
        cell.textLabel?.text="\(indexPath.row)"
        cell.detailTextLabel?.numberOfLines = 0;
        cell.detailTextLabel?.textAlignment = .left
        let workout  = workouts[indexPath.row]
        let startDate = dateFormatter.string(from: workout.startDate)
        var detailText = "开始时间: " + startDate + "\n"
        detailText += "耗时:" + durationFormatter.string(from: workout.duration)! + "\n"
        let distanceInMiles = workout.totalDistance!.doubleValue(for: HKUnit.mile())
        detailText +=  "距离: " + distanceFormatter.string(fromValue: distanceInMiles, unit: LengthFormatter.Unit.mile)
        let energyBurned = workout.totalEnergyBurned!.doubleValue(for: HKUnit.joule())
        detailText += " 能量:" + energyFormatter.string(fromJoules: energyBurned)
        cell.detailTextLabel?.text = detailText;   

        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView .deselectRow(at: indexPath, animated: true)
    }

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

}
