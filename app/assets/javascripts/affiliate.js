//= require jquery
//= require jquery-ui.min

$(function() {

    $("#accordion").accordion({
        collapsible : true, // close all when click
        active : 0       // Boolean or Integer : true - all closed, 0 - first opened
    });

    var onBannerClick = function(banner_img) {
        var affiliate_url = document.getElementById("affiliate_url").innerText;
        $('textarea#html_code').val("<a href='" + affiliate_url + "' target='_blank'><img src='" + this.origin + "/affiliates/" + banner_img + ".png' alt=''></a>");
    };

    $('a#full_banner').on('click', function() {
        onBannerClick(this.parentNode.id);
    });

    $('a#rectangle').on('click', function() {
        onBannerClick(this.parentNode.id);
    });

    $('a#square').on('click', function() {
        onBannerClick(this.parentNode.id);
    });

    $('a#sky_scraper').on('click', function() {
        onBannerClick(this.parentNode.id);
    });

    $('a#wide_sky_scraper').on('click', function() {
        onBannerClick(this.parentNode.id);
    });

});