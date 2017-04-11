//
//  FanHealthManager.swift
//  FanHealthKit
//
//  Created by 向阳凡 on 15/11/26.
//  Copyright © 2015年 向阳凡. All rights reserved.
//

import UIKit
import HealthKit

class FanHealthManager: NSObject {
    /// 创建健康管理对象
    let healthKitStore:HKHealthStore=HKHealthStore();
    /**
     请求健康授权
     
     - parameter completion: 授权返回回调
     - parameter error:      错误
     */
    func authorizeHealthKit(_ completion:((_ success:Bool,_ error:NSError?)->Void)!){
        //个人特征：出生日期，性别，血液类型 数据采集信息：身体质量，身高  锻炼健身信息
        var healthKitTypesToRead=Set([HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!,HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!,HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.bloodType)!,HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!,HKObjectType.workoutType()]);
        if #available(iOS 9.0, *) {
            healthKitTypesToRead.insert(HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.fitzpatrickSkinType)!);
        } else {
            // Fallback on earlier versions
        };
        //锻炼与健身信息，身体体重指数（BMI），能量消耗，运动距离
        let healthKitTypesToWrite = Set([
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,   HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!,
            HKQuantityType.workoutType()
            ]);
        //验证是否支持健康
        if !HKHealthStore.isHealthDataAvailable() {
            let error=NSError(domain: "com.fan.FanHealthkit", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available in this Device"]);
            if(completion != nil){
//                completion(success:false,error: error);
                completion(false,error);
            }
            return;
        }
        healthKitStore.requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead) { (success, error) -> Void in
            if ( completion != nil ){
                
                completion(success,error as? NSError)
            }
        }
    }
    /**
     读取用户的个人信息
     
     - returns: （年龄，性别，血型）
     */
    func readProfile()->(age:Int?,sex:HKBiologicalSexObject?,bloodType:HKBloodTypeObject?){
        var birthday:Date?;
        var age:Int?;
        var sexObj:HKBiologicalSexObject?;
        var bloodTypeObj:HKBloodTypeObject?;
        do{
            birthday = try healthKitStore.dateOfBirth()
            let today = Date()
            let differenceComponents = (Calendar.current as NSCalendar).components(NSCalendar.Unit.year, from: birthday!, to: today, options:NSCalendar.Options(rawValue: 0));
            age = differenceComponents.year
        }catch{
            print("获取出生日期失败");
        }
        do{
            sexObj = try healthKitStore.biologicalSex()
        }catch{
            print("获取性别失败");
        }
        do{
            bloodTypeObj = try healthKitStore.bloodType()
        }catch{
            print("获取血液类型失败");
        }
        return (age,sexObj,bloodTypeObj);
    }
    /**
     查询用户最近一条 身体信息
     
     - parameter sampleType: 身体类型（身高，体重）
     - parameter completion: 回调（实例，错误）
     */
    func readMostRecentSample(_ sampleType:HKSampleType , completion: ((HKSample?, NSError?) -> Void)!)
    {
        // 1. 创建一个查询器，从很久以前到现在
        let past = Date.distantPast as Date
        let now   = Date()
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: past, end:now, options: HKQueryOptions())
        // 2. 创建排序检索器
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        // 3. 创建查询Query
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: 1, sortDescriptors: [sortDescriptor]){ (sampleQuery, results, error ) -> Void in
                if let _ = error {
                    completion(nil,error as? NSError)
                    return;
                }
                //取到第一个简单实例
                let mostRecentSample = results!.first as? HKQuantitySample
                // 结果回调
                if completion != nil {
                    completion(mostRecentSample,nil)
                }
        }
        // 5. 开始查询
        self.healthKitStore.execute(sampleQuery)
    }
    /**
     创建一个身高体重指数并保存
     
     - parameter bmi:  指数
     - parameter date: 时间
     */
    func saveBMISample(_ bmi:Double,date:Date){
        // 1. 创建一个BMI实例
        let bmiType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex)
        let bmiQuantity = HKQuantity(unit: HKUnit.count(), doubleValue: bmi)
        let bmiSample = HKQuantitySample(type: bmiType!, quantity: bmiQuantity, start: date, end: date)
        // 2. 保存到健康数据中
        healthKitStore.save(bmiSample, withCompletion: { (success, error) -> Void in
            if( error != nil ) {
                print("Error saving BMI sample: \(error!.localizedDescription)")
            } else {
                print("BMI sample saved successfully!")
            }  
        })
    }
    /**
     保存运动数据
     
     - parameter startDate:    开始时间
     - parameter endDate:      结束时间
     - parameter distance:     距离
     - parameter distanceUnit: 距离单位
     - parameter kiloCalories: 千焦卡尔单位
     - parameter completion:   回调成功失败
     */
    func saveRunningWorkout(_ startDate:Date , endDate:Date , distance:Double, distanceUnit:HKUnit , kiloCalories:Double,
        completion: ( (Bool, NSError?) -> Void)!) {
            // 1.创建运动（距离，能量）实例
            let distanceQuantity = HKQuantity(unit: distanceUnit, doubleValue: distance)
            let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: kiloCalories)
            // 2. 保存运动数据
            let workout = HKWorkout(activityType: HKWorkoutActivityType.running, start: startDate, end: endDate, duration: abs(endDate.timeIntervalSince(startDate)), totalEnergyBurned: caloriesQuantity, totalDistance: distanceQuantity, metadata: nil)
            healthKitStore.save(workout, withCompletion: { (success, error) -> Void in
                if( error != nil  ) {
                    // Error saving the workout
                    completion(success,error as? NSError)
                }
                else {
                    // Workout saved  
                    completion(success,nil)    
                }  
            })  
    }
    /**
     查询跑步数据
     
     - parameter completion: 数组回调
     */
    func readRunningWorkOuts(_ completion: (([AnyObject]?, NSError?) -> Void)!) {
        // 1.创建跑步的连接谓词
        let predicate =  HKQuery.predicateForWorkouts(with: HKWorkoutActivityType.running)
        // 2.添加日期排序
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        // 3. Create the query
        let sampleQuery = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor])
            { (sampleQuery, results, error ) -> Void in
                if let queryError = error {
                    print( "There was an error while reading the samples: \(queryError.localizedDescription)")
                }
                completion(results,error as? NSError)
        }
        // 4. 执行SQL语句
        healthKitStore.execute(sampleQuery)
    }
}







