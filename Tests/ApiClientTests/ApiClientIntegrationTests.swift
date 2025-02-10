import XCTest
import struct CoreModule.Request
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
        let request = Request(apiEnvironment: ApiEnvironment(environmentType: PokemonNetworkEnvironment.prod), path: "pokemon/ditto", httpMethod: .get)
        

        let response: PokemonInformationModel = try! await apiClient.request(request)

        XCTAssertEqual(response.id, 132)
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
