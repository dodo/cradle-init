# cradle-init

creates database if necessary, and updates views. (clobbers, currently)

```javascript
var db = require('cradle-init')(name, opts)
  .view('group/item', function (doc){//map function
    emit(key,value)
    }, function (key,values){

    }).ready(function (err,db){//create and intiailze database.
    })
```


[![Build Status](https://secure.travis-ci.org/dodo/cradle-init.png)](http://travis-ci.org/dodo/cradle-init)
