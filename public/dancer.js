var dancer = function($) {

var types = {
    COMPANY   : 0x1,
    DEPARTMENT: 0x2,
    EMPLOYEE  : 0x4,
    ADDRESS   : 0x8,
    SALARY    : 0x10,
};


var getTypeFromId = function(id) {
    var type = types[id.substring(0, id.indexOf('-')).toUpperCase()];
    if (!type) throw 'Unknown type or not an id: ' + id;
    return type;
};


var getUuidFromId = function(id) { return id.substring(id.indexOf('-') + 1); };


var update = function(node, data) {
    console.log(data);
}; 

var submit = function(e) {
    var node = $(e.target);
    $.post(node.attr('tourl'), node.serialize(),
           function(data) { update(node, data); }, 'json');
    return false;
};


var ajax = function(data) {
    var dom = $(data);
    var sub = dom.find('[name="submit"]').hide();
    var can = dom.find('[name="cancel"]').hide();

    var but = {};
    but[sub.attr('value')] = function() { $(this).submit();        };
    but[can.text()       ] = function() { $(this).dialog('close'); };

    dom.submit(submit)
       .dialog({
            buttons: but,
            close  : function() { $(this).remove(); },
        });
};


var edit = function(node) {
    $.get('/edit/' + node.id.replace('-', '/'), {}, ajax, 'html');
};


var remove = function(node) {
    $.get('/delete/' + getUuidFromId(node.id), {}, ajax, 'html');
};


var addCompany = function() {
    $.get('/add', {}, ajax, 'html');
};


var addDepartment = function(node) {
    $.get('/add/department/' + getUuidFromId(node.id), {}, ajax, 'html');
};


var addEmployee = function(node) {
    $.get('/add/employee/' + getUuidFromId(node.id), {}, ajax, 'html');
};


var getContextMenu = function(node) {
    var id    = node.id;
    var type  = getTypeFromId(id);

    var items = {
        edit: {
            label : 'Edit',
            action: function() { edit(node); },
        },

        remove: {
            label          : 'Delete',
            action         : function() { remove(node); },
            separator_after: true,
        },
    };

    if (type & (types.COMPANY | types.DEPARTMENT)) {
        items.addDepartment = {
            icon  : '/dept_icon.png',
            label : 'Add Department',
            action: function() { addDepartment(node); },
        };
    }

    if (type & types.DEPARTMENT) {
        items.addEmployee = {
            icon  : '/empl_icon.png',
            label : 'Add Employee',
            action: function() { addEmployee(node); },
        };
    }

    items.addCompany = {
        icon            : '/comp_icon.png',
        label           : 'Create Company',
        action          : addCompany,
        separator_before: true,
    };

    return items;
};


return function() {
    $('noscript').remove();
    $('.edit'   ).remove();

    $('.comp-item').attr('data-jstree', '{"icon":"/comp_icon.png", "opened":true}');
    $('.dept-item').attr('data-jstree', '{"icon":"/dept_icon.png"}');
    $('.empl-item').attr('data-jstree', '{"icon":"/empl_icon.png"}');
    $('.addr-item').attr('data-jstree', '{"icon":"/addr_icon.png"}');
    $('.slry-item').attr('data-jstree', '{"icon":"/slry_icon.png"}');

    $('#company-tree').jstree({
        plugins    : ['wholerow', 'contextmenu'],
        contextmenu: {'items': getContextMenu},
    });
};

}($);

$(dancer);

