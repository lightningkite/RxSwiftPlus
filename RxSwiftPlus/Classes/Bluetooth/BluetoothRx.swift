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

private let manager = CentralManager(queue: .main)
private let requireBle = manager.observeStateWithInitialValue()
    .filter { $0 == .poweredOn }
    .firstOrError()

public extension ViewControllerAccess {
    func bleScan(lowPower: Bool = false, filterForService: UUID? = nil) -> Observable<BleScanResult> {
        return manager.scanForPeripherals(withServices: filterForService.map { [CBUUID(nsuuid: $0)] }, options: nil).map { it in
            var serviceData = Dictionary<UUID, Data>()
            for entry in it.advertisementData.serviceData ?? [:] {
                serviceData[UUID(uuidString: entry.key.uuidString)!] = entry.value
            }
            for service in it.advertisementData.serviceUUIDs ?? [] {
                serviceData[UUID(uuidString: service.uuidString)!] = Data()
            }
            return BleScanResult(
                name: it.advertisementData.localName ?? "",
                rssi: Int(truncating: it.rssi),
                id: it.peripheral.identifier.uuidString,
                services: serviceData
            )
        }
    }
    func bleDevice(id: String, requiresBond: Bool) -> BleDevice {
        return CoreBleDevice(peripheral: manager.retrievePeripherals(withIdentifiers: [UUID(uuidString: id)!]).first!, requiresBond: requiresBond)
    }
}

private class CoreBleDevice: BleDevice {
    
    let peripheral: Peripheral
    let requiresBond: Bool
    init(peripheral: Peripheral, requiresBond: Bool) {
        self.peripheral = peripheral
        self.requiresBond = requiresBond
    }
    var id: String {
        return peripheral.identifier.uuidString
    }
    
    lazy var connected = {
        peripheral.establishConnection()
            .retry { $0.delay(.seconds(1), scheduler: MainScheduler.instance) }
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
        return connected.firstOrError()
            .flatMap { $0.readValue(for: characteristic) }
            .map { $0.value ?? Data() }
    }
    
    func write(characteristic: BleCharacteristic, value: Data) -> Single<Void> {
        return connected.firstOrError()
            .flatMap { $0.writeValue(value, for: characteristic, type: .withResponse) }
            .map { _ in () }
    }
    
    func notify(characteristic: BleCharacteristic) -> Observable<Data> {
        return connected.switchMap { $0.observeValueUpdateAndSetNotification(for: characteristic) }.compactMap { $0.value }.retry { $0.delay(.seconds(1), scheduler: MainScheduler.instance) }
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
