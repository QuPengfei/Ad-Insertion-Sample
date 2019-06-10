$(".top-bar").on(":initpage", function(e) {
    $("#setting").find("[ui-header-setting-user] input").val(settings.user());
    $("#setting").find("[ui-header-setting-analytics-window] input").val(settings.analytics_window());
    $(this).find("[user-name-menu]").text(settings.user());

    /* disable all switches */
    $("#playListSwitch").prop("checked",true);
    $("#analyticsConsoleSwitch").prop("checked",true);
    $.each(["debug","adstats","workloads"],function(i,x) {
        $("#"+x+"ConsoleSwitch").prop("checked",false);
    });
});

$("#setting").find("form").submit(function() {
    var page=$(this);

    var user=page.find("[ui-header-setting-user] input").val().toLowerCase();
    settings.user(user);
    $(".top-bar").find("[user-name-menu]").text(user);
    
    settings.analytics_window(page.find("[ui-header-setting-analytics-window] input").val());

    $.each(["debug","analytics","adstats","workloads"],function(i,x) {
        if ($("#"+x+"ConsoleSwitch").is(":checked"))
            $("["+x+"-console]").show();
        else
            $("["+x+"-console]").hide();
    });

    if ($("#playListSwitch").is(":checked")) {
        $("#player [playlist-section]").show();
        $("#player [video-section]").width("70%");
    } else {
        $("#player [playlist-section]").hide();
        $("#player [video-section]").width("100%");
    }

    $("#player").trigger(":update");
    return false;
});

var settings={
    user: function (name) {
        if (typeof name != "undefined") localStorage.user=name;
        return typeof localStorage.user!="undefined"?localStorage.user:"guest";
    },
    analytics_window: function (size) {
        if (typeof size != "undefined") localStorage.analytics_window=size;
        return typeof localStorage.analytics_window!="undefined"?parseFloat(localStorage.analytics_window):10;
    },
}
