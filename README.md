# SrvResolver

#### DNS SRV records query/resolve for objc/Swift

```Swift

// Swift example
import srvresolver

SRVQueryResolver.query("_sip._udp.sip1.voice.google.com", timeout: 2) { records, err in
    if let records = records {
        print(records)
    } else if let err = err {
        print(err.localizedDescription)
    }
}

```
```Objective-C

// Objective-C example

@import srvresolver;

[SRVQueryResolver query:@"_sip._udp.sip1.voice.google.com" timeout:2.0 completion:^(NSArray<SRVQueryRecord *> *records, NSError *err) {
    if (records) {
        NSLog(@"Found %ld records:\n%@", records.count, records);
    } else if (err) {
        NSLog(@"%@", err.localizedDescription);
    }
}];
```
