webUi = (($) ->
    METHODS =
        ajax : {}
    REQUIRED_URLS = ['tree']
    # These should probably be @types and @urls, but that don't work. I assume because I
    # just don't get how ``this'' works in JavaScript. So trailing underscores it is.
    types_ = urls_ = undefined


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



    nodeFromData = (type, data) ->
        typeInfo = types_[type] or throw "Got invalid type from server: #{type}"
        if ('text' of typeInfo)
            args    = []
            args[i] = data[arg] for arg, i in typeInfo.text.args
            text    = vsprintf(typeInfo.text.format, args)
        node    =
            type     : type
            id       : data.uuid
            text     : text || data.name
            children : nodesFromData(data)


    nodesFromData = (data) ->
        nodes = []
        if 'employees'   of data
            nodes.push(nodeFromData('employee',   e)) for e in data.employees
        if 'departments' of data
            nodes.push(nodeFromData('department', d)) for d in data.departments
        if 'companies'   of data
            nodes.push(nodeFromData('company',    c)) for c in data.companies
        return nodes



    buildTree = ->
        $msg = addMessage('Getting tree...', 'load')
        $.get(urls_.tree, {type : 'tree'})
        .done (data) ->
            try
                nodes = nodesFromData(data)
                $('#tree').jstree
                    core    : { data : nodes }
                    plugins : ['contextmenu', 'dnd', 'types', 'wholerow']
                    types   : types_
            catch e
                addMessage("Fatal Error: #{e}", 'error')
        .fail   -> addMessage('Fatal Error: Could not get tree from server.', 'error')
        .always -> removeMessage($msg)
        .always    handleMessages


    ### init()
    Loads the configuration information from the server via AJAX and then does a bunch of
    ugly error checking. If it's happy with the result, it defers to buildTree. Otherwise
    it shows a message and the script dies. Then you go fix your broken server code. ###
    init = ->
        $msg = addMessage('Getting server configuration...', 'load')
        $.get('/', {type : 'config'})
        .done ({method, urls, types}) ->
            try
                errs = []

                if ms = METHODS[method]
                    # TODO
                else
                    errs.push('Server did not return valid method.')

                if urls
                    for u in REQUIRED_URLS
                        errs.push("Missing required URL for #{u}.") unless u of urls
                else
                    errs.push('Server did not return valid URLs.')

                errs.push('Server did not return valid types') if not types

                throw errs if errs.length
                types_ = types
                urls_  = urls
                buildTree()

            catch es
                if $.isArray(es)
                    addMessage("Fatal Error: #{e}",  'error') for e in es
                else
                    addMessage("Fatal Error: #{es}", 'error')
            return
        .fail   -> addMessage('Fatal Error: Could not get server configuration.', 'error')
        .always -> removeMessage($msg)
        .always    handleMessages

)(jQuery)

jQuery(webUi)
jQuery(-> jQuery('.noscript').remove())

