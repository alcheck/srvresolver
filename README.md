# SrvResolver

#### DNS SRV records query/resolve for objc/Swift

Add to you podfile:
```
pod 'srvresolver'

```

Use:
```Swift

// Swift example
import srvresolver

SRVQueryResolver.query("_xmpp-server._tcp.gmail.com", timeout: 2) { records, err in
    if let records = records {
        records.forEach { record in
            print("\(record.target) : \(record.port), ttl: \(record.ttl), priority: \(record.priority)")
        }
    } else if let err = err {
        print(err.localizedDescription)
    }
}

```
```Objective-C

// Objective-C example

@import srvresolver;

[SRVQueryResolver query:@"_xmpp-server._tcp.gmail.com" timeout:2.0 completion:^(NSArray<SRVQueryRecord *> *records, NSError *err) {
    if (records) {
        for(SRVQueryRecord *record in records) {
            NSLog(@"%@ : %ld, ttl: %ld, priority: %ld", record.target, record.port, record.ttl, record.priority);
        }
    } else if (err) {
        NSLog(@"%@", err.localizedDescription);
    }
}];

```

```
Output:

alt1.xmpp-server.l.google.com : 5269, ttl: 1127, priority: 20
alt3.xmpp-server.l.google.com : 5269, ttl: 1127, priority: 20
alt4.xmpp-server.l.google.com : 5269, ttl: 1127, priority: 20
alt2.xmpp-server.l.google.com : 5269, ttl: 1127, priority: 20
xmpp-server.l.google.com : 5269, ttl: 1127, priority: 5

```
