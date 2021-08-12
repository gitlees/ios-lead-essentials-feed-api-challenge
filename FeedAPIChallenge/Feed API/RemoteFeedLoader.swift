//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

private struct FeedImageListRemote: Decodable {
	let items: [FeedImageRemote]
}

private struct FeedImageRemote: Decodable {
	let imageId: UUID
	let imageDesc: String?
	let imageLoc: String?
	let imageUrl: URL
}

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] result in
			guard let self = self else { return }
			switch result {
			case .failure:
				completion(.failure(Error.connectivity))
			case let .success((data, response)):
				if let items = self.mapFeedImageListRemote(data: data)?.items, response.statusCode == 200 {
					completion(.success(items.asFeedImages))
				} else {
					completion(.failure(Error.invalidData))
				}
			}
		}
	}

	private func mapFeedImageListRemote(data: Data) -> FeedImageListRemote? {
		do {
			let decoder = JSONDecoder()
			decoder.keyDecodingStrategy = .convertFromSnakeCase
			return try decoder.decode(FeedImageListRemote.self, from: data)
		} catch {
			return nil
		}
	}
}

private extension Array where Element == FeedImageRemote {
	var asFeedImages: [FeedImage] {
		return map { FeedImage(id: $0.imageId, description: $0.imageDesc, location: $0.imageLoc, url: $0.imageUrl) }
	}
}
