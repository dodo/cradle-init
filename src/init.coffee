cradle = require 'cradle'


update_views = (callback) ->
    ids = Object.keys @views
    @db.get ids, (err, data) =>
        (data.rows or data).forEach (el) => # cradle raw mode? doesnt matter
            @log "#{el._id}:#{el._rev}", el
            if (doc = el.doc ? el) # cradle raw mode? doesnt matter
                @views[doc._id]._rev = doc._rev

        views = ids.map (el) =>
            @log @views[el]
            @views[el]

        @db.save views, (err) =>
            callback?(err, @db)



class CradleSetup
    constructor: (@name, @config = {}, opts = {}) ->

        if typeof @name is 'object'
            @config = @name
            @name = @config.name
        @views = {}

        # debugging
        if opts.debug and typeof opts.debug isnt 'function'
            @log = console.log
        else
            @log = -> # dummy

        # defaults
        @config or=  cache:on
        @config.host ?= "http://localhost"
        @config.port ?= 5984

        # initialize connection and database
        conn = new cradle.Connection config.host,config.port,config
        @db = conn.database name


    view: (name, map, reduce) ->
        mapreduce = {map, reduce}
        if typeof map is 'object'
            mapreduce = map

        name = name.split '/'
        id = "_design/#{name[0]}"
        view = @views[id] or= { _id:id, views:{} }
        view.views[name[1]] = mapreduce
        this


    ready: (callback) ->
        @db.exists (err, exists) =>
            @log "does couchdb '#{@name}' exist? #{exists and 'yes' or 'no'}"
            return callback?(err)                    if err
            return update_views.call this, callback  if exists

            @db.create (err, ok) =>
                @log "couchdb '#{@name}' created"
                return callback?(err) if err
                update_views.call this, callback


# exports

module.exports = -> new CradleSetup arguments...
module.exports.CradleSetup = CradleSetup


# testing

unless module.parent
    console.error "lol!!!"
    new CradleSetup('test').ready console.log

