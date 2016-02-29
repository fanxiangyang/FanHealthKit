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
    lazy var dateFormatter:NSDateFormatter = {
        
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        formatter.dateStyle = .MediumStyle
        return formatter;
        
    }()
    /// 时间格式化
    let durationFormatter = NSDateComponentsFormatter()
    /// 能量格式化
    let energyFormatter = NSEnergyFormatter()
    /// 长度格式化
    let distanceFormatter = NSLengthFormatter()


    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
         let addBar = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: Selector("addRunningWorkout"))
        let refreshBar = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: Selector("refreshRunningHealthKit"))
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
                print("Error reading workouts: \(error.localizedDescription)")
                return;
            }else{
                print("Workouts read successfully!")
            }
            self.workouts.removeAll()
            self.workouts = results as! [HKWorkout]
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            });
        })
    }
    /**
     添加一个运动
     */
    func addRunningWorkout(){
        var hkUnit = HKUnit.meterUnitWithMetricPrefix(.Kilo)//千米
        hkUnit = HKUnit.mileUnit()//米
        // 2. 保存
        self.healthManager?.saveRunningWorkout(NSDate(timeIntervalSinceNow: -1800), endDate: NSDate(timeIntervalSinceNow: 0), distance: 2000 , distanceUnit:hkUnit, kiloCalories: 1000, completion: { (success, error ) -> Void in
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

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.workouts.count
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 88
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("WorkCell", forIndexPath: indexPath)
        cell.textLabel?.text="\(indexPath.row)"
        cell.detailTextLabel?.numberOfLines = 0;
        cell.detailTextLabel?.textAlignment = .Left
        let workout  = workouts[indexPath.row]
        let startDate = dateFormatter.stringFromDate(workout.startDate)
        var detailText = "开始时间: " + startDate + "\n"
        detailText += "耗时:" + durationFormatter.stringFromTimeInterval(workout.duration)! + "\n"
        let distanceInMiles = workout.totalDistance!.doubleValueForUnit(HKUnit.mileUnit())
        detailText +=  "距离: " + distanceFormatter.stringFromValue(distanceInMiles, unit: NSLengthFormatterUnit.Mile)
        let energyBurned = workout.totalEnergyBurned!.doubleValueForUnit(HKUnit.jouleUnit())
        detailText += " 能量:" + energyFormatter.stringFromJoules(energyBurned)
        cell.detailTextLabel?.text = detailText;   

        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView .deselectRowAtIndexPath(indexPath, animated: true)
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
