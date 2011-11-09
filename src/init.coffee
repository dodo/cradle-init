cradle = require 'cradle'
sync   = require './sync'


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
        @conn = new cradle.Connection @config.host, @config.port, @config
        @db = @conn.database @name


    view: (name, map, reduce) =>
        mapreduce = {map, reduce}
        if typeof map is 'object'
            mapreduce = map

        name = name.split '/'
        id = "_design/#{name[0]}"
        view = @views[id] or= { _id:id, views:{}, language:'javascript' }
        view.views[name[1]] = mapreduce
        this


    ready: (callback) =>
        @log "connected to couchdb #{@conn.host}:#{@conn.port}"
        @db.exists (err, exists) =>
            @log "does db '#{@name}' exist? #{exists and 'yes' or 'no'}"

            return callback?(err)                    if err
            return update_views.call this, callback  if exists

            @db.create (err, ok) =>
                @log "db '#{@name}' created"

                return callback?(err) if err
                update_views.call this, callback


# exports

module.exports = -> new CradleInit arguments...
module.exports.CradleInit = CradleInit


# testing

unless module.parent
    new CradleInit('test').ready console.log

