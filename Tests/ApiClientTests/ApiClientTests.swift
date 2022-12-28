@testable import ApiClient
import CoreModule
import XCTest

final class ApiClientTests: XCTestCase {
    func testDidApiClientSetUp() {
        ApiClient.setup(ApiClient.DefaultParameterConfig())
        XCTAssertNotNil(ApiClient.shared)
    }

    // MARK: - Integration Tests with Example APIs

    func testFetchWeatherDataWithCityNameRequest() {
        ApiClient.setup(ApiClient.DefaultParameterConfig(defaultURLParameters: ["appid": ""])) // insert appid

        let expectation = XCTestExpectation(description: "Fetch Character List")

        let completion: (Result<WeatherInformationResponseModel, NetworkError>) -> Void = {
            result in
            switch result {
            case let .success(response):
                XCTAssertEqual(response.city.name, "Istanbul")
                expectation.fulfill()
            case .failure:
                fatalError()
            }
        }

        ApiClient.shared.request(HomePageRequest(request: .fetchWeatherDataWithCityName(cityName: "Istanbul"), apiEnvironment: ApiEnvironment(environmentType: WeatherForecastNetworkEnvironment.prod)), completion: completion)
        wait(for: [expectation], timeout: 10.0)
    }

    private struct HomePageRequest: Request {
        enum Request {
            case fetchWeatherDataWithCityName(cityName: String)
            case fetchWeatherDataWithCoordinates(latitude: Double, longitude: Double)
        }

        var request: HomePageRequest.Request
        var apiEnvironment: ApiEnvironment

        init(request: HomePageRequest.Request, apiEnvironment: ApiEnvironment) {
            self.request = request
            self.apiEnvironment = apiEnvironment
        }

        var path: String {
            switch request {
            case .fetchWeatherDataWithCityName:
                return "forecast"
            case .fetchWeatherDataWithCoordinates:
                return "forecast"
            }
        }

        var httpMethod: HTTPMethods {
            .get
        }

        var urlParameters: Parameters? {
            switch request {
            case let .fetchWeatherDataWithCityName(cityName):
                var urlParameters: Parameters = .init()
                urlParameters["q"] = cityName
                urlParameters["units"] = "metric"

                return urlParameters
            case let .fetchWeatherDataWithCoordinates(latitude, longitude):
                var urlParameters: Parameters = .init()
                urlParameters["lat"] = "\(latitude)"
                urlParameters["lon"] = "\(longitude)"
                urlParameters["units"] = "metric"

                return urlParameters
            }
        }

        var bodyParameters: Parameters? {
            nil
        }

        var httpHeaders: HTTPHeaders? {
            nil
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
