# HTTPHelper
Simple functions for simplifying network operations 

GET: 
~~~
getJsonFrom("http://...") { json in
    print(json)
}
~~~

POST:
~~~
postJson(["name": "sheepy"], toUrl: "http://...") { json in
    print(json)
}
~~~
