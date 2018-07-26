#  FOAAS (Swift)

Wrote a quick wrapper for the [FOAAS.com](http://foaas.com) API using Swift 4's JSON decoding. 
I make no claims of ownership of FOAAS or to it's availability.

[FOAAS on GitHub](https://github.com/tomdionysus/foaas)


### Basic usage

Copy the *FOAAS.swift* file into your own project and you're good to go!

```
let fuck = FOAAS()
fuck.off(name: "Friend", from: "You", completion: { (response, error)
    if let error = error {
        print(error)
        return
    }
    guard let response = response else { return }
    print(response.message)
    print(response.subtitle)
})

fuck.random(name: "Friend", from: "You") { (response, error) in
    if let error = error {
        print(error)
        return
    }
    guard let response = response else { return }
    print(response.message)
    print(response.subtitle)
}
```

### License

Do whatever you like with this
