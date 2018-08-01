//= require jquery.min
//= require jquery.utilcarousel.min
//= require jquery.nice-select.min

//= require bootstrap

//= require menumaker
//= require count
//= require wow.min
//= require particles


$("#cssmenu").menumaker({
    title: "",
    format: "multitoggle"
});

$(document).ready(function () {
    $('select').niceSelect();
});

$(function () {

    $('#normal-imglist').utilCarousel({
        pagination: false,
        navigationText: ['<i class="icon-left-open-big"></i>', '<i class=" icon-right-open-big"></i>'],
        breakPoints: [
            [1920, 3],
            [1199, 2],
            [992, 2],
            [480, 1]
        ],
        navigation: true,
        rewind: false,
        autoPlay: true
    });

    function toggleIcon(e) {
        $(e.target)
            .prev('.panel-heading')
            .find(".more-less")
            .toggleClass('glyphicon-plus glyphicon-minus');
    }
    $('.panel-group').on('hidden.bs.collapse', toggleIcon);
    $('.panel-group').on('shown.bs.collapse', toggleIcon);


    $('#testimonial').utilCarousel({
        showItems: 1,
        breakPoints: [
            [1920, 1]
        ],
        autoPlay: true
    });


    $('#ourteam').utilCarousel({
        showItems: 2,
        breakPoints: [
            [1920, 2],
            [480, 1]
        ],
        autoPlay: true
    });

});

(function (e, t, n) {
    var r = e.querySelectorAll("html")[0];
    r.className = r.className.replace(/(^|\s)no-js(\s|$)/, "$1js$2")
})(document, window, 0);

// wow animation put it after Document.ready
wow = new WOW({
    mobile: false
});
wow.init();