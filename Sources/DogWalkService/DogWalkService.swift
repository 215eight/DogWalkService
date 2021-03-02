import SEDogWalkCoreData
import Combine
import Foundation
import SEPlatform

enum DogWalkServiceError: Error {
    case invalidManagedObject
}

public struct Dog {
    public var id: UUID
    public var name: String
    public var walks: [Walk]
}

extension Dog: Identifiable {}

extension Dog {

    init(nsDog: SEDogWalkCoreData.Dog) throws {
        guard let id = nsDog.id,
              let name = nsDog.name,
              let walksArray = nsDog.walks?.allObjects else {
            throw DogWalkServiceError.invalidManagedObject
        }
        self.id = id
        self.name = name
        self.walks = try walksArray.map { any -> Walk in
            guard let nsWalk = any as? SEDogWalkCoreData.Walk else {
                throw DogWalkServiceError.invalidManagedObject
            }
            return try Walk(nsWalk: nsWalk)
        }
    }
}

public struct Walk {
    public var id: UUID
    public var date: Date
    public var dogId: UUID
}

extension Walk: Identifiable {}

extension Walk {

    init(nsWalk: SEDogWalkCoreData.Walk) throws {
        guard let id = nsWalk.id,
              let dogId = nsWalk.dogId,
              let date = nsWalk.date else {
            throw DogWalkServiceError.invalidManagedObject
        }
        self.id = id
        self.dogId = dogId
        self.date = date
    }
}

public protocol DogWalkServicing {
    func addDog(name: String) ->  SinglePublisher<AnyPublisher<Dog, Error>>
    func addWalk(date: Date, dogId: UUID) -> SinglePublisher<AnyPublisher<Walk, Error>>
    func fetchDogs() -> SinglePublisher<AnyPublisher<[Dog], Error>>
    func fetchWalks(dogId: UUID) -> SinglePublisher<AnyPublisher<[Walk], Error>>
}

public class DogWalkService {

    private let store = DogWalkCoreData()

    public init() {}

    public func load() -> Result<(), Error> {
        return store.load()
    }
}

extension DogWalkService: DogWalkServicing {

    public func addDog(name: String) ->  SinglePublisher<AnyPublisher<Dog, Error>> {
        store.addDog(name: name)
            .tryMap { try Dog(nsDog: $0) }
            .eraseToSinglePublisher()
    }

    public func fetchDogs() -> SinglePublisher<AnyPublisher<[Dog], Error>> {
        store.fetchDogs()
            .tryMap { nsDogs in
                return try nsDogs.map { try Dog(nsDog: $0) }
            }
            .eraseToSinglePublisher()
    }

    public func addWalk(date: Date, dogId: UUID) -> SinglePublisher<AnyPublisher<Walk, Error>> {
        store.addWalk(date: date, dogId: dogId)
            .tryMap { nsWalk in
                return try Walk(nsWalk: nsWalk)
            }
            .eraseToSinglePublisher()
    }

    public func fetchWalks(dogId: UUID) -> SinglePublisher<AnyPublisher<[Walk], Error>> {
        store.fetchWalks(from: dogId)
            .tryMap { nsWalks in
                return try nsWalks.map { try Walk(nsWalk: $0) }
            }
            .eraseToSinglePublisher()
    }

}
