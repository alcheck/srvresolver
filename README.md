# SrvResolver

#### DNS SRV records query/resolve for objc/Swift

<pre>
// Swift
SRVQueryResolver.query("@"_sip._udp.sip.voice.google.com"", timeout: 2.0) { records, error in
  // records - array of SRVQueryRecord items
  guard let records = records else { return }
  print(records)
}
</pre>

