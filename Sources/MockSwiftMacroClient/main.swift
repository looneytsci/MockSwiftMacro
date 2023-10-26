import MockSwiftMacro

@Mock
protocol Service {
    func doWork() -> String?
}

@Mock
protocol IService: AnyObject {
    var worker: String { get set }
    var optionalWorker: String? { get set }
    var forceUnwrappedWorker: String! { get set }

    func doWork()
    func doWorkWithArg(arg: String)
    func doWorkWithReturnValue() -> String
    func doWorkWithArgAndReturnValue(arg: String) -> String
}

let serviceMock = IServiceMock()
