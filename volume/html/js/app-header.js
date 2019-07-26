$(".top-bar").on(":initpage", function(e) {
    $("#setting").find("[ui-header-setting-user] input").val(settings.user());
    $("#setting").find("[ui-header-setting-analytics-window] input").val(settings.analytics_window());
    $("#setting").find("[ui-header-setting-ad-interval-window] input").val(settings.ad_interval_window());
    $(this).find("[user-name-menu]").text(settings.user());

    /* disable all switches */
    $("#playListSwitch").prop("checked",true);
    $("#objDetectionSwitch").prop("checked",true);
    $.each(["debug","analytics","adstats","workloads","analyticPerf"],function(i,x) {
        $("#"+x+"ConsoleSwitch").prop("checked",false);
    });
});

$("#setting").find("form").submit(function() {
    var page=$(this);

    var user=page.find("[ui-header-setting-user] input").val().toLowerCase();
    settings.user(user);
    $(".top-bar").find("[user-name-menu]").text(user);

    settings.analytics_window(page.find("[ui-header-setting-analytics-window] input").val());
    var interval=page.find("[ui-header-setting-ad-interval-window] input").val()
    settings.ad_interval_window(interval);

    $.each(["debug","analytics","adstats","workloads","analyticPerf"],function(i,x) {
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
 
    /* ["obj_detection", "emotion", "face_recognition"] */
    if ($("#objDetectionSwitch").is(":checked")) {
       var casename="obj_detection"
       var enable=1
       apiHost.usecase(user,casename,enable)
    } else {
       var casename="obj_detection"
       var enable=0
       apiHost.usecase(user,casename,enable)
    }

    if ($("#emotionRecognitionSwitch").is(":checked")) {
       var casename="emotion"
       var enable=1
       apiHost.usecase(user,casename,enable)
    } else {
       var casename="emotion"
       var enable=0
       apiHost.usecase(user,casename,enable)
    }

    if ($("#faceRecognitionSwitch").is(":checked")) {
       var casename="face_recognition"
       var enable=1
       apiHost.usecase(name,casename,enable)
       apiHost.usecase(user,casename,enable)
    } else {
       var casename="face_recognition"
       var enable=0
       apiHost.usecase(user,casename,enable)
    }

    var benchmode=0
    if ($("#benchModeSwitch").is(":checked")) {
       benchmode=1
    }
    apiHost.usecase(user,benchmode,interval)

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
    ad_interval_window: function (size) {
        if (typeof size != "undefined") localStorage.ad_interval_window=size;
        return typeof localStorage.ad_interval_window!="undefined"?parseFloat(localStorage.ad_interval_window):24;
    },
}
