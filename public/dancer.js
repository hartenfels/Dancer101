var dancer = function($) {

var treePlugins = ['contextmenu', 'types', 'wholerow'];
var treeTypes   = {
    company: {
        icon          : '/comp_icon.png',
        valid_children: ['department'],
    },
    department: {
        icon          : '/dept_icon.png',
        valid_children: ['department', 'employee'],
    },
    employee: {
        icon          : '/empl_icon.png',
        valid_children: [],
    },
    address: {
        icon          : '/addr_icon.png',
        valid_children: [],
    },
    salary: {
        icon          : '/slry_icon.png',
        valid_children: [],
    },
};

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


var showMessage = function(div) {
    div.slideDown()
       .delay(5000)
       .slideUp({complete: function() { div.remove(); } });
}

var addMessage = function(msg) {
    var div = $('<div class="message"></div>').text(msg.text).hide();
    if (+msg.is_error) div.addClass('error');
    $('#messages').append(div);
    showMessage(div);
}


var currentDialog;

var showDialog = function(dom) {
    var sub = dom.find('[name="submit"]').hide();
    var can = dom.find('[name="cancel"]').hide();

    var but = {};
    but[sub.attr('value')] = function() { $(this).submit();        };
    but[can.text()       ] = function() { $(this).dialog('close'); };

    dom.submit(function(e) {
            var node = $(e.target);
            $.post(node.attr('tourl'), node.serialize(), ajax, 'json');
            dom.dialog('close');
            return false;
        })
       .dialog({
            buttons: but,
            close  : function() { $(this).remove(); },
            show   : {effect: 'drop', direction: 'down'},
            hide   : {effect: 'drop', direction: 'up'  },
        });

    try { currentDialog.dialog('close'); } catch(e) {}
    currentDialog = dom;
}


var rebuild = function(obj, info) {

    var rebuildEmpls = function(employees) {
        var nodes = [];
        for (var i = 0; i < employees.length; ++i) {
            var empl = employees[i];
            var uuid = 'employee-' + empl.uuid;
            nodes.push({
                id      : uuid,
                text    : ' ' + empl.name,
                type    : 'employee',
                state   : {opened: !info[uuid], selected: info.selected == uuid},
                li_attr : {class: 'empl-item'},
                children: [
                    {
                        id      : 'address-' + empl.uuid,
                        text    : ' ' + empl.address,
                        type    : 'address',
                        state   : {opened: !info[uuid], selected: info.selected == uuid},
                        li_attr : {class: 'addr-item'},
                    }, {
                        id      : 'salary-' + empl.uuid,
                        text    : ' '  + empl.salary,
                        type    : 'address',
                        state   : {opened: !info[uuid], selected: info.selected == uuid},
                        li_attr : {class: 'slry-item'},
                    },
                ],
            });
        }
        return nodes;
    }

    var rebuildDepts = function(departments) {
        var nodes = [];
        for (var i = 0; i < departments.length; ++i) {
            var dept = departments[i];
            var uuid = 'department-' + dept.uuid;
            nodes.push({
                id      : uuid,
                text    : ' ' + dept.name,
                type    : 'department',
                state   : {opened: !info[uuid], selected: info.selected == uuid},
                li_attr : {class: 'dept-item'},
                children: rebuildEmpls(dept.employees).concat(
                                                       rebuildDepts(dept.departments)),
            });
        }
        return nodes;
    }

    var rebuildCompanies = function(companies) {
        var nodes = [{
            id  : 'add-company',
            text: ' Create Company ',
            icon: '/plus.png',
        }];
        for (var i = 0; i < companies.length; ++i) {
            var comp = companies[i];
            var uuid = 'company-' + comp.uuid;
            nodes.push({
                id      : uuid,
                text    : ' ' + comp.name,
                type    : 'company',
                state   : {opened: !info[uuid], selected: info.selected == uuid},
                li_attr : {class: 'comp-item'},
                children: rebuildDepts(comp.departments),
            });
        }
        return nodes;
    }

    return rebuildCompanies(obj);
}


var gatherNodeInfo = function(nodes) {
    var info = {};

    var recursiveGather = function(node) {
        info[node.id] = !node.state.opened;
        if (node.state.selected) info.selected = node.id;
        for (var j = 0; j < node.children.length; ++j)
            recursiveGather(node.children[j]);
    }

    for (var i = 0; i < nodes.length; ++i)
        recursiveGather(nodes[i]);
    return info;
}


var ajax = function(data) {
    for (var i = 0; i < data.messages.length; ++i)
        addMessage(data.messages[i]);

    switch (data.type) {
    case 'get':
        showDialog($(data.html));
        break;
    case 'success':
        var tree = $('#company-tree');
        var info = gatherNodeInfo(tree.jstree('get_json'));
        tree.jstree('destroy')
            .empty()
            .on('select_node.jstree', function(e, data) {
                 if (data.node.id == 'add-company') addCompany();
             })
            .jstree({
                 core       : {data : rebuild(data.companies, info)},
                 contextmenu: {items: getContextMenu},
                 plugins    : treePlugins,
                 types      : treeTypes,
             });
        break;
    case 'failure':
    case 'info':
        break;
    default:
        throw 'Unknown AJAX response type: ' + data.type;
    }
};


var getContextMenu = function(node) {
    var id    = node.id;
    var type  = getTypeFromId(id);

    var items = {
        cut: {
            label: 'Cut',
            action: function() {
                $.post('/cut/' + getUuidFromId(id), {}, ajax, 'json');
            },
        },

        median: {
            label: 'Median',
            action: function() {
                $.post('/median/' + getUuidFromId(id), {}, ajax, 'json');
            },
        },

        total: {
            label: 'Total',
            action: function() {
                $.post('/total/' + getUuidFromId(id), {}, ajax, 'json');
            },
        },

        edit: {
            label           : 'Edit',
            separator_before: true,
            action          : function() {
                $.get('/edit/' + id.replace('-', '/'), {}, ajax, 'json');
            },
        },

        remove: {
            label          : 'Delete',
            separator_after: true,
            action         : function() {
                $.get('/delete/' + getUuidFromId(id), {}, ajax, 'json');
            },
        },
    };

    if (type & (types.COMPANY | types.DEPARTMENT)) {
        items.addDepartment = {
            icon  : '/dept_add.png',
            label : 'Add Department',
            action: function() {
                $.get('/add/department/' + getUuidFromId(id), {}, ajax, 'json');
            },
        };
    }

    if (type & types.DEPARTMENT) {
        items.addEmployee = {
            icon  : '/empl_add.png',
            label : 'Add Employee',
            action: function() {
                $.get('/add/employee/' + getUuidFromId(id), {}, ajax, 'json');
            },
        };
    }

    items.addCompany = {
        icon            : '/comp_add.png',
        label           : 'Create Company',
        separator_before: true,
        action          : function() {
            $.get('/add', {}, ajax, 'json');
        },
    };

    return items;
};


return function() {
    $('noscript').remove();
    $('.edit'   ).remove();

    $('.comp-item').attr('data-jstree', '{"type":"company", "opened":true}');
    $('.dept-item').attr('data-jstree', '{"type":"department"}');
    $('.empl-item').attr('data-jstree', '{"type":"employee"}');
    $('.addr-item').attr('data-jstree', '{"type":"address"}');
    $('.slry-item').attr('data-jstree', '{"type":"salary"}');

    $('#messages').css('position', 'absolute');
    showMessage($('.message').hide());

    $('#add-company').text(' Create Company')
                     .attr('data-jstree', '{"icon":"/plus.png"}');
    $('#company-tree').on('select_node.jstree', function(e, data) {
                           if (data.node.id == 'add-company') addCompany();
                       })
                      .jstree({
                           contextmenu: {'items': getContextMenu},
                           plugins    : treePlugins,
                           types      : treeTypes,
                       });

    $('#info').append('<p>Right-click for a context menu.</p>');
};

}($);

$(dancer);

