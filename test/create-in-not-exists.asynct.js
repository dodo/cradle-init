var init = require('../cradle-init')
  , it = require('it-is').style('colour')
  , request = require('request')
  , dbname = 'cradle-init-test'
  , dbconf = {
      host:'localhost',
      port:5984,
  }
  , dbopts = {
      debug:true,
  }
exports.__setup = function (test){
  request({
    uri:'http://'+dbconf.host+':'+dbconf.port+'/'+dbname,
    method:'DELETE',
  },
  function (err){
    if(err)
      throw err //test.error(err)
    test.done()
  })
}
/*
exports ['will callback error if there is no couchdb running'] = function (test){

  init('test',{host:'localhost', port:2352}).ready(function (err,db){
    console.log("ASDFASFASFAS",arguments)
    it(err).ok()
    it(db).equal(null)
    test.done()
  })
}
*/
exports ['database exists'] = function (test){

  init(dbname, dbconf, dbopts).ready(function (err,db){
    it(err).equal(null)
    it(db).ok()
    db.exists(function (err,exists){
      it(err).equal(null)
      it(exists).equal(exists)
        test.done()
    })
  })
}

exports ['intialize views'] = function (test){
  var map, reduce
  init(dbname, dbconf, dbopts)
  .view('group/item', map = function (doc){
    emit(1,"HELLO")
  }, reduce = function (keys,values){

  })
  .ready(function (err,db){
    it(err).equal(null)
    it(db).ok()

    db.get('_design/group', function (err,data){
      it(err).equal(null)
      it(data).has({
        views: {
          item: {
            map: it.equal(map.toString()),
            reduce: it.equal(reduce.toString())
          }
        }
      })
      test.done()
    })
  })
}

exports['initialize multiple views'] = function (test){
  var map, map2
  init(dbname, dbconf, dbopts)
  .view('group/item', map = function (doc){
    emit(1,"HELLO")
  })
  .view('group/thing', map2 = function (doc){
    emit(-1,"GOODBYE")
  }).ready(function (err,db){
    it(err).equal(null)
    it(db).ok()
    db.get('_design/group', function (err,data){
      it(err).equal(null)
      it(data).has({
        views: {
          item: {
            map: it.equal(map.toString())
          },
          thing: {
            map: it.equal(map2.toString()),
          }
        }
      })
      test.done()
    })
  })

}