{ keys } = Object


deep_diff = (t, a, b) ->
    for own k, va of a[t]
        vb = b[t][k]
        if va isnt undefined
            return yes unless vb?
            if t is "views" # special case
                return yes if "#{va.map}"    isnt "#{vb.map}"
                return yes if "#{va.reduce}" isnt "#{vb.reduce}"
            else if va isnt vb # doesnt exist or isnt the same
                return yes
    return no

##
# test if two designs are diffent to each other
diff = (a, b) ->
    # shortcuts, cauz im lazy
    [u, v, l] = types = ["updates", "views", "lists"]
    if a[u]? isnt b[u]? or a[v]? isnt b[v]? or a[l]? isnt b[l]? # XOR!
        return yes

    for t in types
        continue unless a[t]? or b[t]? # both undefined
        if deep_diff(t,a,b) or deep_diff(t,b,a)
            return yes

    return no # no return 'til now means they are the same

##
# every time a design is changed, it should be synced with the db, else skip it
sync = (done) ->
    queue = []
    ids = keys(@designs)
    @db.get ids, (err, data) =>
        return callback?(err) if err

        (data.rows or data).forEach (el) => # cradle raw mode? doesnt matter
            doc = el.doc ? el
            design = @designs[doc?._id]
            return unless design?


            if doc.error # whateva (mostly not_found, but i dont care)
                @log "new design '#{design._id}'", design
                queue.push design

            else if diff doc, design
                @log "design '#{design._id}' changed", doc, design
                design._rev = doc._rev
                queue.push design

        @db.save queue, (err) =>
            done?(err, @db)


# exports

module.exports = sync

