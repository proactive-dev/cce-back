//= require jquery
//= require jquery-ui.min

$(function() {

    $("#accordion").accordion({
        collapsible : true, // close all when click
        active : 0,       // Boolean or Integer : true - all closed, 0 - first opened
        heightStyle: "content"
    });

    var onBannerClick = function(banner_img) {
        var affiliate_url = document.getElementById("affiliate_url").innerText;
        $('textarea#html_code').val("<a href='" + affiliate_url + "' target='_blank'><img src='" + this.origin + "/affiliates/" + banner_img + ".png' alt=''></a>");
    };

    var $active_wrapper = $("#active_wrapper");

    $("figure").each(function () {
        $(this).click(function () {
            onBannerClick(this.id);

            $(this).addClass("active");
            $(this).siblings().removeClass("active");
            $active_wrapper.detach();
            $(this).append($active_wrapper);
        });
    });
});