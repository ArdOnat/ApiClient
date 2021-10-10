import CoreModule
import XCTest
@testable import ApiClient

final class ApiClientTests: XCTestCase {
    
    func testDidApiClientSetUp() {
        ApiClient.setup(ApiClient.DefaultParameterConfig())
        XCTAssertNotNil(ApiClient.shared)
    }
    
    // MARK: - Integration Tests with Example APIs
    
    func testFetchWeatherDataWithCityNameRequest() {
        ApiClient.setup(ApiClient.DefaultParameterConfig(defaultURLParameters: ["appid": ""])) // insert appid
        
        let expectation = XCTestExpectation(description: "Fetch Character List")
        
        let completion: (Result<WeatherInformationResponseModel, NetworkError>) -> Void =  {
            result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.city.name, "Istanbul")
                expectation.fulfill()
            case .failure(_):
                fatalError()
            }
        }
    
        ApiClient.shared.request(HomePageRequest.init(request: .fetchWeatherDataWithCityName(cityName: "Istanbul"), apiEnvironment: ApiEnvironment(environmentType: WeatherForecastNetworkEnvironment.prod)), completion: completion)
        wait(for: [expectation], timeout: 10.0)
    }
    
    private struct HomePageRequest: Request {
        
        enum Request {
            case fetchWeatherDataWithCityName(cityName: String)
            case fetchWeatherDataWithCoordinates(latitude: Double, longitude: Double)
        }
        
        var request: HomePageRequest.Request
        var apiEnvironment: ApiEnvironment
        
        init (request: HomePageRequest.Request, apiEnvironment: ApiEnvironment) {
            self.request = request
            self.apiEnvironment = apiEnvironment
        }
        
        var path: String {
            switch request {
            case .fetchWeatherDataWithCityName(_):
                return "forecast"
            case .fetchWeatherDataWithCoordinates(_, _):
                return "forecast"
            }
        }
        
        var httpMethod: HTTPMethods {
            return .get
        }
        
        var urlParameters: Parameters? {
            switch request {
            case .fetchWeatherDataWithCityName(let cityName):
                var urlParameters: Parameters = Parameters()
                urlParameters["q"] = cityName
                urlParameters["units"] = "metric"
                
                return urlParameters
            case .fetchWeatherDataWithCoordinates(let latitude, let longitude):
                var urlParameters: Parameters = Parameters()
                urlParameters["lat"] = "\(latitude)"
                urlParameters["lon"] = "\(longitude)"
                urlParameters["units"] = "metric"
                
                return urlParameters
            }
        }
        
        var bodyParameters: Parameters? {
            return nil
        }
        
        var httpHeaders: HTTPHeaders? {
            return nil
        }
    }
    
    private enum WeatherForecastNetworkEnvironment: NetworkEnvironment {
        case prod
        
        var baseURL: String {
            switch self {
            case .prod: return "https://api.openweathermap.org/data/2.5/"
            }
        }
    }
    
    private struct WeatherInformationResponseModel: Codable {
        let list: [CountryWeatherInformationModel]
        let city: CityInformationModel
    }

    private struct CountryWeatherInformationModel: Codable {
        let main: MainformationModel
        let weather: [WeatherInformationModel]
        let dt_txt: String
    }

    private struct MainformationModel: Codable {
        let temp: Double
        let temp_min: Double
        let temp_max: Double
        let humidity: Double
    }

    private struct WeatherInformationModel: Codable {
        let main: String
        let icon: String
    }

    private struct CityInformationModel: Codable {
        let name: String
    }
}
