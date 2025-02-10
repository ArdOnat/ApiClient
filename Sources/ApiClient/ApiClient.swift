import Foundation
import struct CoreModule.Request
import enum CoreModule.NetworkError
import typealias CoreModule.Parameters
import typealias CoreModule.HTTPHeaders
import struct CoreModule.ErroredRequestDetail

protocol NetworkClient {
    func request<T: Decodable>(_ request: CoreModule.Request) async throws -> T
}

public class ApiClient: NetworkClient {
    private let urlSession: URLSession
    private let defaultParameterConfig: DefaultParameterConfig?

    public init(urlSession: URLSession = URLSession.shared, defaultParameterConfig: DefaultParameterConfig? = nil) {
        self.urlSession = urlSession
        self.defaultParameterConfig = defaultParameterConfig
    }

    // MARK: Default parameters

    public struct DefaultParameterConfig {
        let defaultURLParameters: Parameters?
        let defaultBodyParameters: Parameters?

        public init(defaultURLParameters: Parameters? = nil, defaultBodyParameters: Parameters? = nil) {
            self.defaultURLParameters = defaultURLParameters
            self.defaultBodyParameters = defaultBodyParameters
        }
    }
    public func request<T: Decodable>(_ request: CoreModule.Request) async throws -> T {
        let createdRequest = try self.buildRequest(from: request)
        let (data, response) = try await URLSession.shared.data(for: createdRequest)
        
        guard response.validateStatusCode() else {
            if let httpUrlResponse = response as? HTTPURLResponse {
                let erroredRequestDetail = ErroredRequestDetail(
                    statusCode: httpUrlResponse.statusCode,
                    errorResponseData: data,
                    request: request
                )
                throw NetworkError.invalidStatusCode(requestDetail: erroredRequestDetail)
            }
            throw NetworkError.custom(errorText: "HTTP URL Response is not available")
        }

        guard let decodedResponse = try? JSONDecoder().decode(T.self, from: data) else {
            throw NetworkError.decodingFailed
        }

        return decodedResponse
    }

    fileprivate func buildRequest(from requestToMake: CoreModule.Request) throws -> URLRequest {
        guard let baseURL = URL(string: requestToMake.apiEnvironment.baseURL) else {
            throw NetworkError.invalidBaseURL
        }

        var request = URLRequest(
            url: baseURL.appendingPathComponent(requestToMake.path),
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 10.0
        )
        request.httpMethod = requestToMake.httpMethod.rawValue

        do {
            if let additionalHeaders = requestToMake.httpHeaders {
                addAdditionalHeaders(additionalHeaders, request: &request)
            }
            try configureParameters(
                bodyParameters: requestToMake.bodyParameters,
                urlParameters: requestToMake.urlParameters,
                request: &request
            )
            return request
        } catch {
            throw error
        }
    }

    fileprivate func configureParameters(
        bodyParameters: Parameters?,
        urlParameters: Parameters?,
        request: inout URLRequest
    ) throws {
        do {
            if var bodyParameters = bodyParameters {
                if let defaultBodyParameters = self.defaultParameterConfig?.defaultBodyParameters {
                    for (key, value) in defaultBodyParameters {
                        bodyParameters[key] = value
                    }
                }

                try JSONParameterEncoder.encode(urlRequest: &request, with: bodyParameters)
            }

            if var urlParameters = urlParameters {
                if let defaultURLParameters = self.defaultParameterConfig?.defaultURLParameters {
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

private extension URLResponse {
    var acceptableStatusCodes: Range<Int> { 200 ..< 300 }

    func validateStatusCode() -> Bool {
        if let httpURLResponse = self as? HTTPURLResponse, acceptableStatusCodes.contains(httpURLResponse.statusCode) {
            return true
        } else {
            return false
        }
    }
}
