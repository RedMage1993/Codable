A macro that is useful whenever the compiler cannot synthesize conformance to Codable on its own, e.g. an Observable class.

```
import Codable

@Observable
@Codable
class Something {
    let property: OtherCodableType
    var mutable: String
}
```