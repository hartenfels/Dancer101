var dancer = {

COMPANY   : 0x1,
DEPARTMENT: 0x2,
EMPLOYEE  : 0x4,
ADDRESS   : 0x8,
SALARY    : 0x10,

init: function() {
    $('noscript').remove();
    $('.edit'   ).remove();

    $('.comp-item').attr('data-jstree', '{"icon":"/comp_icon.png", "opened":true}');
    $('.dept-item').attr('data-jstree', '{"icon":"/dept_icon.png"}');
    $('.empl-item').attr('data-jstree', '{"icon":"/empl_icon.png"}');
    $('.addr-item').attr('data-jstree', '{"icon":"/addr_icon.png"}');
    $('.slry-item').attr('data-jstree', '{"icon":"/slry_icon.png"}');

    $('#company-tree').jstree({
        plugins    : ['wholerow', 'contextmenu'],
        contextmenu: {'items': dancer.getContextMenu},
    });
},


getTypeFromId: function(id) {
    var type = dancer[id.substring(0, id.indexOf('-')).toUpperCase()];
    if (!type) throw 'Unknown type or not an id: ' + id;
    return type;
},


getUuidFromId: function(id) { return id.substring(id.indexOf('-') + 1); },


getContextMenu: function(node) {
    var id    = node.id;
    var type  = dancer.getTypeFromId(id);

    var items = {
        edit: {
            label : 'Edit',
            action: function() { dancer.edit(node); },
        },

        remove: {
            label          : 'Delete',
            action         : function() { dancer.remove(node); },
            separator_after: true,
        },
    };

    if (type & (dancer.COMPANY | dancer.DEPARTMENT)) {
        items.addDepartment = {
            icon  : '/dept_icon.png',
            label : 'Add Department',
            action: function() { dancer.addDepartment(node); },
        };
    }

    if (type & dancer.DEPARTMENT) {
        items.addEmployee = {
            icon  : '/empl_icon.png',
            label : 'Add Employee',
            action: function() { dancer.addEmployee(node); },
        };
    }

    items.addCompany = {
        icon            : '/comp_icon.png',
        label           : 'Create Company',
        action          : dancer.addCompany,
        separator_before: true,
    };

    return items;
},


edit: function(node) {
    $.get('/edit/' + node.id.replace('-', '/'), {}, dancer.ajax, 'html');
},


remove: function(node) {
    var name = node.text.trim();
    $('<div></div>').text('Really delete ' + name + '?').dialog({
        title  : 'Delete ' + name,

        buttons: {
            Yes: function() {
                $.post('/delete/' + dancer.getUuidFromId(node.id),
                       {}, dancer.done, 'json');
                $(this).dialog('close');
            },

            No : function() {
                $(this).dialog('close');
            },
        },

        close  : function() { $(this).remove(); },
    });
},


addCompany: function() {
    $.get('/add', {}, dancer.ajax, 'html');
},


addDepartment: function(node) {
    $.get('/add/department/' + dancer.getUuidFromId(node.id), {}, dancer.ajax, 'html');
},


addEmployee: function(node) {
    $.get('/add/employee/' + dancer.getUuidFromId(node.id), {}, dancer.ajax, 'html');
},


ajax: function(data) {
    $(data).submit(dancer.submit)
           .dialog({
                buttons: {
                    Submit: function() { $(this).submit();        },
                    Cancel: function() { $(this).dialog('close'); },
                },
                close: function() { $(this).remove(); },
            })
           .find('.actions').hide();
},


submit: function(e) {
    var node = $(e.target);
    $.post(node.attr('tourl'), node.serialize());
    return false;
},


done: function(data, ok) {
    console.log('done');
    console.debug(data);
},


};

$(dancer.init);

