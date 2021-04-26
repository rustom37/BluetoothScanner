//
//  PlotMeasurementsViewController.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 14/04/2021.
//  Copyright © 2021 Steve Rustom. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Charts

/// View controller that displays  the measurements.
class PlotMeasurementsViewController: UIViewController, ChartViewDelegate {
    @IBOutlet var chartView: LineChartView!

    var chartPointsPpg: [ChartDataEntry] = []
    var chartPointsAccX: [ChartDataEntry] = []
    var chartPointsAccY: [ChartDataEntry] = []
    var chartPointsAccZ: [ChartDataEntry] = []
    var chartPointsGyrX: [ChartDataEntry] = []
    var chartPointsGyrY: [ChartDataEntry] = []
    var chartPointsGyrZ: [ChartDataEntry] = []
    var dataSets: [LineChartDataSet] = []

    var measurements: [[[Int16]]] = []
    var timeStamp: Double = 0.0

    /// Loads the view
    override func viewDidLoad() {
        super.viewDidLoad()

        if let arr = UserDefaults.standard.object(forKey: "dataArray") as? [[[Int16]]] {
            measurements = arr
        }
        
        for (_,list) in measurements[0].enumerated() {
            chartPointsPpg.append(ChartDataEntry(x:timeStamp , y: Double(list[0])))
            chartPointsAccX.append(ChartDataEntry(x: timeStamp, y: Double(list[1])))
            chartPointsAccY.append(ChartDataEntry(x: timeStamp, y: Double(list[2])))
            chartPointsAccZ.append(ChartDataEntry(x: timeStamp, y: Double(list[3])))
            chartPointsGyrX.append(ChartDataEntry(x: timeStamp, y: Double(list[4])))
            chartPointsGyrY.append(ChartDataEntry(x: timeStamp, y: Double(list[5])))
            chartPointsGyrZ.append(ChartDataEntry(x: timeStamp, y: Double(list[6])))
            timeStamp += 20.0
        }

        dataSets.append(prepareDataSet(entries: chartPointsPpg, label: "PPG", color: hexStringToUIColor(hex: "#FF2600")))
        dataSets.append(prepareDataSet(entries: chartPointsAccX, label: "Acc X", color: hexStringToUIColor(hex: "#011993")))
        dataSets.append(prepareDataSet(entries: chartPointsAccY, label: "Acc Y", color: hexStringToUIColor(hex: "#008F00")))
        dataSets.append(prepareDataSet(entries: chartPointsAccZ, label: "Acc Z", color: hexStringToUIColor(hex: "#942193")))
        dataSets.append(prepareDataSet(entries: chartPointsGyrX, label: "Gyr X", color: hexStringToUIColor(hex: "#FF9300")))
        dataSets.append(prepareDataSet(entries: chartPointsGyrY, label: "Gyr Y", color: hexStringToUIColor(hex: "#76D6FF")))
        dataSets.append(prepareDataSet(entries: chartPointsGyrZ, label: "Gyr Z", color: hexStringToUIColor(hex: "#FFFC79")))

        let data = LineChartData(dataSets: dataSets)
        data.setValueFont(.systemFont(ofSize: 7, weight: .light))
        chartView.data = data
    }

    /// Prepares the data set of points that needs to be plotted
    /// - Parameters:
    ///   - entries: Array of data point entries
    ///   - label: The label of the line plot
    ///   - color: The color of the line plot
    /// - Returns: A dataset of LinePlot entries
    func prepareDataSet(entries: [ChartDataEntry], label: String, color: UIColor) -> LineChartDataSet {
        let lineChartDataSet = LineChartDataSet(entries: entries, label: label)
        lineChartDataSet.lineWidth = 1.5
        lineChartDataSet.circleRadius = 2
        lineChartDataSet.circleHoleRadius = 1
        lineChartDataSet.setColor(color)
        lineChartDataSet.setCircleColor(color)

        return lineChartDataSet
    }

    /// Converts Hex string into color
    /// - Parameter hex: Hex representation of a color
    /// - Returns: Respective color
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
