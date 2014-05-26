$(function() {
    $('noscript').remove();
    $('.edit'   ).remove();

    $('.comp-item').attr('data-jstree', '{"icon":"/comp_icon.png", "opened":true}');
    $('.dept-item').attr('data-jstree', '{"icon":"/dept_icon.png"}');
    $('.empl-item').attr('data-jstree', '{"icon":"/empl_icon.png"}');
    $('.addr-item').attr('data-jstree', '{"icon":"/addr_icon.png"}');
    $('.slry-item').attr('data-jstree', '{"icon":"/slry_icon.png"}');

    $('#company-tree').jstree({
        plugins: [
            'wholerow'
        ]
    });
});

