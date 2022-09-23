//
//  WeatherAPI.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 06.09.2022.
//

import Foundation

final class MeteostatWeatherApi {
     
    func load(period: ClosedRange<Date>) async throws  -> [WeatherData] {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        
        var url = URL(string: "https://meteostat.p.rapidapi.com/stations/daily")!
        let start = dateFormatter.string(from: period.lowerBound)
        let end = dateFormatter.string(from: period.upperBound)
        url.append(queryItems: [
            URLQueryItem(name: "station", value: "27612"), // Moscow
            URLQueryItem(name: "freq", value: "D"),
            URLQueryItem(name: "start", value: start),
            URLQueryItem(name: "end", value: end)
        ])
        
        var request = URLRequest(url: url)
        request.setValue("meteostat.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
//        request.setValue("8cede6d95bmsh1282c5181af9084p10a0d8jsn77986609b3cf", forHTTPHeaderField: "x-rapidapi-key")
        request.setValue("e8d23099c7mshbbf5b845065b073p1775aajsnb16b52485bd0", forHTTPHeaderField: "x-rapidapi-key")
        
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let result = try decoder.decode(Response.self, from: data)
            return result.data.compactMap {
                guard   let tmin = $0.tmin,
                        let tmax = $0.tmax,
                        let tavg = $0.tavg else { return nil }
                return WeatherData(datetime: $0.date,
                                   temp: tavg,
                                   tempmax: tmax,
                                   tempmin: tmin,
                                   wind: $0.wspd,
                                   snow: $0.snow,
                                   precipitation: $0.prcp )
            }
        } catch {
            if let resp = response as? HTTPURLResponse {
                print("Response: \(resp)")
            }
            if let json = String(data: data, encoding: .utf8)  {
                print("Data: \(json)")
            }
            
            print("Error: \(error)")
            throw error
        }
            
    }
    
    struct Response: Decodable {
        var data: [Row]
        
        struct Row: Decodable {
            let date: Date
            let tmin: Double?
            let tmax: Double?
            let tavg: Double?
            let wspd: Double?
            let prcp: Double?
            let snow: Double?
        }
    }
}
 
struct NoMoreData: Error {}
