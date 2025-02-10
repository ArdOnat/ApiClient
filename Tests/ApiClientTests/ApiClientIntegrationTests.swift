import XCTest
import protocol CoreModule.Request
import enum CoreModule.NetworkError
import typealias CoreModule.Parameters
import typealias CoreModule.HTTPHeaders
import class CoreModule.ApiEnvironment
import protocol CoreModule.NetworkEnvironment
import enum CoreModule.HTTPMethods

import XCTest
@testable import ApiClient

final class ApiClientIntegrationTests: XCTestCase {
    
    // MARK: - Integration Tests with Example APIs
    
    var apiClient: ApiClient!
    
    override func setUp() {
        super.setUp()
        apiClient = ApiClient()
    }
    
    override func tearDown() {
        apiClient = nil
        super.tearDown()
    }
    
    func testFetchWeatherDataWithCityNameRequest() async {
        let response: PokemonInformationModel = try! await apiClient.request(PokemonRequest.init(request: .pokemonDitto, apiEnvironment: ApiEnvironment(environmentType: PokemonNetworkEnvironment.prod)))

        XCTAssertEqual(response.id, 132)
    }
    
    private struct PokemonRequest: Request {
        
        enum Request {
            case pokemonDitto
        }
        
        var request: PokemonRequest.Request
        var apiEnvironment: ApiEnvironment
        
        init (request: PokemonRequest.Request, apiEnvironment: ApiEnvironment) {
            self.request = request
            self.apiEnvironment = apiEnvironment
        }
        
        var path: String {
            switch request {
            case .pokemonDitto:
                return "pokemon/ditto"
            }
        }
        
        var httpMethod: HTTPMethods {
            return .get
        }
        
        var urlParameters: Parameters? {
            return nil
        }
        
        var bodyParameters: Parameters? {
            return nil
        }
        
        var httpHeaders: HTTPHeaders? {
            return nil
        }
    }
    
    private enum PokemonNetworkEnvironment: NetworkEnvironment {
        case prod
        
        var baseURL: String {
            switch self {
            case .prod: return "https://pokeapi.co/api/v2/"
            }
        }
    }
    
    private struct PokemonInformationModel: Codable {
        let id: Int
    }
}
