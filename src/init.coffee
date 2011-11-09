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



class CradleInit
    constructor: (@name, @config = {}, opts = {}) ->

        if typeof @name is 'object'
            opts = @config
            @config = @name
            @name = @config.name
        @views = {}

        # debugging
        if opts.debug
            if typeof opts.debug is 'function'
                @log = opts.debug
            else
                @log = console.log
        else
            @log = -> # dummy

        # defaults
        @config or= cache:on

        # initialize connection and database
        conn = new cradle.Connection config.host, config.port, config
        @db = conn.database name


    view: (name, map, reduce) ->
        mapreduce = {map, reduce}
        if typeof map is 'object'
            mapreduce = map

        name = name.split '/'
        id = "_design/#{name[0]}"
        view = @views[id] or= { _id:id, views:{}, language:'javascript' }
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

module.exports = -> new CradleInit arguments...
module.exports.CradleInit = CradleInit


# testing

unless module.parent
    new CradleInit('test').ready console.log

