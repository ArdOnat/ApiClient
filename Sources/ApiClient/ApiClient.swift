//
//  File.swift
//
//
//  Created by Arda Onat on 6.09.2021.
//

import Foundation
import Alamofire
import CoreModule

public class ApiClient: NetworkClient {
    
    // MARK: Singleton
    public static let shared = ApiClient()
    
    // MARK: Default parameters
    public struct DefaultParameterConfig {
        let defaultURLParameters: Parameters?
        let defaultBodyParameters: Parameters?
        
        public init(defaultURLParameters: Parameters? = nil, defaultBodyParameters: Parameters? = nil) {
            self.defaultURLParameters = defaultURLParameters
            self.defaultBodyParameters = defaultBodyParameters
        }
    }
    
    private static var defaultParameterConfig: DefaultParameterConfig?
    
    private init () {
        guard ApiClient.defaultParameterConfig != nil else {
            fatalError("Error - you must call setup before accessing ApiClient.shared")
        }
    }
    
    /// Function to setup default parameters.
    /// - Parameter defaultParameterConfig: Default parameters struct for url and body parameters.
    public class func setup(_ defaultParameterConfig:DefaultParameterConfig? = DefaultParameterConfig()){
        ApiClient.defaultParameterConfig = defaultParameterConfig
    }
    
    public func request<T>(_ request: CoreModule.Request, queue: DispatchQueue = .main, completion: @escaping (Result<T, NetworkError>) -> ()) where T : Decodable {
        guard let request = try? self.buildRequest(from: request) else {
            return completion(.failure(.invalidRequest))
        }
        AF.request(request).validate().responseDecodable(of: T.self, queue: queue) { response in
            switch response.result {
            case .success(let decodableResult):
                completion(.success(decodableResult))
            case .failure(_):
                completion(.failure(.invalidStatusCode))
            }
        }
    }

    fileprivate func buildRequest(from requestToMake: CoreModule.Request) throws -> URLRequest {
        guard let baseURL = URL(string: requestToMake.apiEnvironment.baseURL) else {
            throw NetworkError.invalidBaseURL
        }

        var request = URLRequest(url: baseURL.appendingPathComponent(requestToMake.path), cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0)
        request.httpMethod = requestToMake.httpMethod.rawValue
        
        do {
            if let additionalHeaders = requestToMake.httpHeaders {
                self.addAdditionalHeaders(additionalHeaders, request: &request)
            }
            try self.configureParameters(bodyParameters: requestToMake.bodyParameters, urlParameters: requestToMake.urlParameters, request: &request)
            return request
        } catch {
            throw error
        }
    }
    
    fileprivate func configureParameters(bodyParameters: Parameters?, urlParameters: Parameters?, request: inout URLRequest) throws {
        do {
            if var bodyParameters = bodyParameters {
                if let defaultBodyParameters = ApiClient.defaultParameterConfig?.defaultBodyParameters {
                    for (key, value) in defaultBodyParameters {
                        bodyParameters[key] = value
                    }
                }
                
                try JSONParameterEncoder.encode(urlRequest: &request, with: bodyParameters)
            }
            
            if var urlParameters = urlParameters {
                if let defaultURLParameters = ApiClient.defaultParameterConfig?.defaultURLParameters {
                    for (key, value) in defaultURLParameters {
                        urlParameters[key] = value
                    }
                }
                
                try URLParameterEncoder.encode(urlRequest: &request, with: urlParameters)
            }
        } catch {
            throw error
        }
    }
    
    fileprivate func addAdditionalHeaders(_ additionalHeaders: CoreModule.HTTPHeaders?, request: inout URLRequest) {
        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
}
