//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import CoreGraphics
import RxSwift
import RxBluetoothKit
import CoreBluetooth

public struct BleScanResult {
    public let name: String?
    public let rssi: Int
    public let id: String
    public let services: Dictionary<UUID, Data>
    public init(name: String?, rssi: Int, id: String, services: Dictionary<UUID, Data>) {
        self.name = name
        self.rssi = rssi
        self.id = id
        self.services = services
    }
}
extension BleScanResult: Hashable {
    public func hash(into hasher: inout Hasher){
        hasher.combine(self.id)
    }
}
extension BleScanResult: Equatable {
    public static func ==(lhs: BleScanResult, rhs: BleScanResult) -> Bool{
        return lhs.id == rhs.id
    }
}

public struct BleCharacteristic: CharacteristicIdentifier {
    public var uuid: CBUUID { return CBUUID(nsuuid: id) }
    public var service: ServiceIdentifier { return BleService(id: serviceId)}
    
    public let serviceId: UUID
    public let id: UUID
    public init(serviceId: UUID, id: UUID) {
        self.serviceId = serviceId
        self.id = id
    }
}
private struct BleService: ServiceIdentifier {
    public var uuid: CBUUID { return CBUUID(nsuuid: id) }
    let id: UUID
}

public protocol BleDevice {
    var id: String { get }
    func stayConnected() -> Observable<Void>
    func isConnected() -> Observable<Bool>
    func rssi() -> Single<Int>
    func read(characteristic: BleCharacteristic) -> Single<Data>
    func write(characteristic: BleCharacteristic, value: Data) -> Single<Void>
    func notify(characteristic: BleCharacteristic) -> Observable<Data>
}

public let manager = CentralManager(queue: .main, options:[CBCentralManagerOptionRestoreIdentifierKey:"abcdef" as AnyObject])
private let requireBle = manager.observeStateWithInitialValue()
    .doOnNext { print("Got \($0)") }
    .filter { $0 == .poweredOn }
    .doOnError { print("Err: \($0)") }
    .firstOrError()



public extension ViewControllerAccess {
    func bleScan(lowPower: Bool = false, filterForService: UUID? = nil) -> Observable<BleScanResult> {
        return requireBle.asObservable().flatMap { _ in
            manager.scanForPeripherals(withServices: filterForService.map { [CBUUID(nsuuid: $0)] }, options: nil).map { it in
                var serviceData = Dictionary<UUID, Data>()
                for entry in it.advertisementData.serviceData ?? [:] {
                    print("Found uuid \(entry.key.uuidString)")
                    if let uuid = UUID(uuidString: entry.key.uuidString) {
                        serviceData[uuid] = entry.value
                    } else if let uuid = UUID(uuidString: "0000\(entry.key.uuidString)-0000-1000-8000-00805F9B34FB") {
                        serviceData[uuid] = entry.value
                    }
                }
                for service in it.advertisementData.serviceUUIDs ?? [] {
                    if let uuid = UUID(uuidString: service.uuidString) {
                        serviceData[uuid] = Data()
                    } else if let uuid = UUID(uuidString: "0000\(service.uuidString)-0000-1000-8000-00805F9B34FB") {
                        serviceData[uuid] = Data()
                    }
                }
                print("Service data \(serviceData)")
                return BleScanResult(
                    name: it.advertisementData.localName ?? "",
                    rssi: Int(truncating: it.rssi),
                    id: it.peripheral.identifier.uuidString,
                    services: serviceData
                )
            }
        }
    }
    //Mtu cannot be changed in swift, default value is there because you can in android.
    func bleDevice(id: String, mtu: Int = 0) -> any BleDevice {
        return coreBleDeviceDictionary.getOrPut(key: id, defaultValue: {
            CoreBleDevice(peripheral: manager.retrievePeripherals(withIdentifiers: [UUID(uuidString: id)!]).first!)
        })
    }
}

private var coreBleDeviceDictionary: Dictionary<String, CoreBleDevice> = [:]

private class CoreBleDevice: BleDevice, Hashable {
    
    let peripheral: Peripheral
    init(peripheral: Peripheral) {
        self.peripheral = peripheral
    }
    var id: String {
        return peripheral.identifier.uuidString
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: CoreBleDevice, rhs: CoreBleDevice) -> Bool { return lhs.id == rhs.id }
    
    lazy var connected = {
        requireBle.toObservable().switchMap { [weak self] _ -> Observable<Peripheral> in
            guard let self = self else { return Observable.never() }
            return self.peripheral.establishConnection()
                .doOnNext { print("Connection established: \($0)") }
                .doOnError { print("Connection error: \($0)") }
                .retry { $0.delay(.seconds(1), scheduler: MainScheduler.instance) }
        }
            .share(replay: 1, scope: .whileConnected)
    }()
    
    func stayConnected() -> Observable<Void> {
        return connected.map { _ in () }
    }
    
    func isConnected() -> Observable<Bool> {
        return peripheral.observeConnection()
    }
    
    func rssi() -> Single<Int> {
        return peripheral.readRSSI().map { $0.1 }
    }
    
    func read(characteristic: BleCharacteristic) -> Single<Data> {
        print("Doing the read")
        return connected
            .doOnError { print("Failed a read \(characteristic.uuid) with connection issue \($0)") }
            .flatMap { it in
                print("Attempting read of \(characteristic.uuid) - \(it.state.rawValue)")
                return it.characteristic(with: characteristic)
                    .doOnError { print("Failed a read \(characteristic.uuid) with char discovery \($0)") }
                    .flatMap {
                        print("Found characteristic \($0)")
                        return it.readValue(for: $0)
                    }
            }
            .doOnError { print("Failed a read \(characteristic.uuid) with readValue issue \($0)") }
            .map { $0.value ?? Data() }
            .firstOrError()
    }
    
    func write(characteristic: BleCharacteristic, value: Data) -> Single<Void> {
        return connected
            .flatMap { $0.writeValue(value, for: characteristic, type: .withResponse) }
            .map { _ in () }
            .doOnError { print("Failed a write \(characteristic.uuid) with \($0)") }
            .firstOrError()
    }
    
    func notify(characteristic: BleCharacteristic) -> Observable<Data> {
        return connected.switchMap { $0.observeValueUpdateAndSetNotification(for: characteristic) }.compactMap { $0.value }
            .doOnError { print("Failed a notify \(characteristic.uuid) with \($0)") }.retry { $0.delay(.seconds(1), scheduler: MainScheduler.instance) }
    }
}

public extension BleDevice {
    func readNotify(characteristic: BleCharacteristic) -> Observable<Data> {
        return Observable.merge(
            read(characteristic: characteristic).asObservable(),
            notify(characteristic: characteristic)
        )
    }
}

private extension Dictionary {
    mutating func getOrPut(key: Key, defaultValue: ()->Value) -> Value {
        if let value = self[key] {
            return value
        } else {
            let newValue = defaultValue()
            self[key] = newValue
            return newValue
        }
    }
}
