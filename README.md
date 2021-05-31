# SrvResolver

#### DNS SRV records query/resolve for objc/Swift

<pre>
// Swift
SRVQueryResolver.query("domain", timeout: 5.0) { records, error in
  // records - array of SRVQueryRecord items
  guard let records = records else { return }
  print(records)
}
</pre>

