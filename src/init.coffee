cradle = require 'cradle'
sync   = require './sync'


class CradleInit
    constructor: (@name, @config = {}, opts = {}) ->

        if typeof @name is 'object'
            opts = @config
            @config = @name
            @name = @config.name
        @designs = {}

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


    _save: (type, name, value) ->
        name = name.split '/'
        id = "_design/#{name[0]}"
        view = @designs[id] or=
            language:'javascript'
            _id:id
            views:{} # this is a must, because else cradle wouldnt recognize it as _design
        @designs[id][type] ?= {}
        @designs[id][type][name[1]] = value


    view: (name, map, reduce) =>
        mapreduce = {map, reduce}
        if typeof map is 'object'
            mapreduce = map
        @_save 'views', name, mapreduce
        this


    update: (name, value) =>
        @_save 'updates', name, value
        this


    list: (name, value) =>
        @_save 'lists', name, value
        this


    ready: (callback) =>
        @log "connecting to couchdb on #{@conn.host}:#{@conn.port} …"
        @db.exists (err, exists) =>
            return callback?(err)            if err
            return sync.call this, callback  if exists

            @db.create (err, ok) =>
                @log "db '#{@name}' created"
                return callback?(err) if err

                # just throw them all in, because db is new and empty
                designs = for own id, design of @designs
                    design

                @db.save designs, (err) =>
                    callback?(err, @db)


# exports

module.exports = -> new CradleInit arguments...
module.exports.CradleInit = CradleInit


# testing

unless module.parent
    new CradleInit('test').ready console.log

