# SrvResolver

#### DNS SRV records query/resolve for objc/Swift

<pre>

// Swift example

SRVQueryResolver.query("_sip._udp.sip1.voice.google.com", timeout: 2) { records, err in
    if let records = records {
        print(records)
    } else if let err = err {
        print(err.localizedDescription)
    }
}

</pre>

