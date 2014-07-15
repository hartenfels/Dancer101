webUi = (($) ->
    # These should probably be @types and @urls, but that don't work. I assume because I
    # just don't get how ``this'' works in JavaScript. So trailing underscores it is.
    types_ = method_ = menu_ = undefined


    ajax =
        buildTree : () ->
            $msg = addMessage('Getting tree...', 'load')
            $.get(method_.tree_url, {type : 'tree'})
            .done (data) ->
                try
                    nodes = nodesFromData(if $.isArray(data) then data else [data])
                    $('#tree').jstree
                        core        : {data  : nodes}
                        contextmenu : {items : menu_}
                        plugins     : ['contextmenu', 'dnd', 'types', 'wholerow']
                        types       : types_
                catch e
                    addMessage("Fatal Error: #{e}", 'error')
            .fail   -> addMessage('Fatal Error: Could not get tree from server.', 'error')
            .always -> removeMessage($msg)
            .always    handleMessages

        executeAction : (key, node) ->
            console.debug key, node, $('#tree').jstree().get_node(node.reference)


    ### addMessage(Str text, Str classes?)
    Shows a message with the given text. Additional CSS classes may be given as a
    space-separated string. Returns the message's $div. ###
    addMessage = (text, classes) ->
        $div = $('<div class="message"></div>').text(text).hide()
        $div.addClass(classes) if classes
        $div.appendTo('#messages').slideDown()


    ### removeMessage($div)
    Hides and removes the given message. Returns the $div to be removed after it gets done
    sliding up, whatever good that'll do ya. You should probably just leave it alone. ###
    removeMessage = ($div) ->
        $div.slideUp({complete : -> $div.remove()})


    ### notice(Str text, Str classes?)
    Dispatches to addMessage, waits five seconds and then calls removeMessage. Happens to
    return the timeout ID of the five-second wait. ###
    notice = (text, classes) ->
        $div = addMessage(text, classes)
        setTimeout((-> removeMessage($div)), 5000)


    ### handleMessage(Str|{Str :text, Str :type} msg)
    Defers to notice. I can't explain it simpler or shorter than the code. ###
    handleMessage = (msg) ->
        if   typeof(msg) is 'string'
        then notice(msg)
        else notice(msg.text, msg.type)
        return


    ### handleMessages({Object|[Object] :messages} data)
    Defers to handleMessage for each message in the given data, if that object has a
    ``messages'' property. It may either be a single message or an array of them. ###
    handleMessages = (data) ->
        if data && 'messages' of data && messages = data.messages
            if   $.isArray(messages)
            then handleMessage(m) for m in messages
            else handleMessage(messages)
        return



    nodeFromData = (data) ->
        type = types_[data.type] or throw "Unknown type: #{data.type}"
        if ('printf' of type)
            args      = []
            args[i]   = data[arg] for arg, i in type.printf.args
            formatted = vsprintf(type.printf.format, args)
        node =
            type     : data.type
            id       : data.id
            text     : formatted || data.text
        node['state'   ] = data.state                   if 'state'    of data
        node['children'] = nodesFromData(data.children) if 'children' of data
        return node


    nodesFromData = (list) ->
        nodes = []
        nodes.push(nodeFromData(n)) for n in list
        return nodes


    buildAction = (key, value, separator) ->
        action = {action : (node) -> method_.executeAction(key, node)}
        if typeof value is 'string'
            action['label'] = value
        else
            action['label'] = value.text or throw "Missing text for action #{k}"
            action['icon' ] = value.icon if 'icon' of value
        action['separator_before'] = true if separator
        return action

    buildMenu = (types, actions) ->
        menus     = {}
        separator = false
        for t, v of types
            menus[t] = {}
            for a in v.actions
                if a
                    throw "Unknown action: #{a}" if not a of actions
                    menus[t][a] = buildAction(a, actions[a], separator)
                    separator   = false
                else
                    separator = true
        return (node) -> menus[node.type]

    ### init()
    Loads the configuration information from the server via AJAX and then does a bunch of
    ugly error checking. If it's happy with the result, it defers to buildTree. Otherwise
    it shows a message and the script dies. Then you go fix your broken server code. ###
    init = ->
        $msg = addMessage('Getting server configuration...', 'load')
        $.get('/', {type : 'config'})
        .done ({method, types, actions}) ->
            try
                errs = []

                switch method.name
                    when 'ajax'
                        'tree_url'    of method or errs.push('ajax missing tree_url.'   )
                        'action_urls' of method or errs.push('ajax missing action_urls.')
                        break if errs.length
                        ajax.tree_url    = method.tree_url
                        ajax.action_urls = method.action_urls
                        method_          = ajax
                    else
                        errs.push("Unsupported method: #{method.name}")

                errs.push('Server did not return valid types.'  ) unless types
                errs.push('Server did not return valid actions.') unless actions

                throw errs if errs.length
                types_ = types
                menu_  = buildMenu(types, actions)
                method_.buildTree()

            catch es
                if $.isArray(es)
                    addMessage("Fatal Error: #{e}",  'error') for e in es
                else
                    addMessage("Fatal Error: #{es}", 'error')
                throw es
            return
        .fail   -> addMessage('Fatal Error: Could not get server configuration.', 'error')
        .always -> removeMessage($msg)
        .always    handleMessages

)(jQuery)

jQuery(webUi)
jQuery(-> jQuery('.noscript').remove())

