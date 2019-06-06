$(document).foundation();
$(window).on("load", function () {
    $(window).resize();
    $(".top-bar").trigger(":initpage");
    $("#player").trigger(":update");

    $("[debug-console]").trigger(":initpage");
    $("[adstats-console]").trigger(":initpage");
    $("[workloads-console]").trigger(":initpage");
    $("[analytics-console]").trigger(":initpage");
    $(window).trigger('resize');
});
