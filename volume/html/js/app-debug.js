
$("[debug-console]").on(":initpage",function () {
    var page=$(this);

    var prev;
    page.find("[console-title]").mousedown(function(e) {
        prev={x:e.clientX,y:e.clientY};
        var move=function(e) {
            var tmp={x:prev.x-e.clientX,y:prev.y-e.clientY};
            prev={x:e.clientX,y:e.clientY};
            var offset=page.offset();
            page.offset({left:offset.left-tmp.x,top:offset.top-tmp.y});
        };
        var up=function (e) {
            $(document).off('mouseup',up);
            $(document).off('mousemove',move);
        };
        $(document).mouseup(up).mousemove(move);
    });

    page.find("button").click(function() {
        page.hide();
        $("#debugConsoleSwitch").prop("checked",false);
    });

    apiHost.debug(function (e) {
        var doc;
        try {
            doc=JSON.parse(e.data);
        } catch (e) {
            return;
        }

        if (page.is(":visible") && doc.topic!="workloads") {
            page.append("<pre>"+doc.topic+": "+doc.value+"<br></pre>");
            if (page.children().length>50)
                page.children().slice(2,3).remove();
        }

        try {
            doc.value=JSON.parse(doc.value);
        } catch (e) {
            return;
        }

        var panel=$("[workloads-console]");
        if (doc.topic=="workloads") {
            if (panel.is(":visible")) {
                try {
                    panel.trigger(":update-workloads",[moment(doc.value.time),doc.value.machine,doc.value.workload]);
                } catch (e) {
                }
            }
            return;
        }

        panel=$("[adstats-console]");
        if (doc.topic=="adstats") {
            if (panel.is(":visible")) {
                try {
                    panel.trigger(":update-adstats",[doc.value]);
                } catch (e) {
                }
            }
            return;
        }
    });
});

$("[analytics-console]").on(":initpage", function () {
    var page=$(this);
    var video=$("#player video");
    var fps=30;
    
    var svg=$("#player svg");
    var drawFrame=function () {
        var frame=Math.floor((new Date()-page.data('time_offset'))/fps);
        if (frame!=page.data('last_draw')) {
            page.data('last_draw',frame);

            svg.empty();
            var objects=page.data('objects');
            if (frame in objects) {
                $.each(objects[frame], function (x,v2) {
                    var sx=svg.width()/v2.resolution.width;
                    var sy=svg.height()/v2.resolution.height;
                    var sxy=Math.min(sx,sy);
                    var sw=sxy*v2.resolution.width;
                    var sh=sxy*v2.resolution.height;
                    var sxoff=(svg.width()-sw)/2;
                    var syoff=(svg.height()-sh)/2;
                    $.each(v2.objects, function (x,v1) {
                        if ("detection" in v1) {
                            var xmin=v1.detection.bounding_box.x_min*sw;
                            var xmax=v1.detection.bounding_box.x_max*sw;
                            var ymin=v1.detection.bounding_box.y_min*sh;
                            var ymax=v1.detection.bounding_box.y_max*sh;
                            if (xmin!=xmax && ymin!=ymax) {
                                svg.append($(document.createElementNS(svg.attr('xmlns'),"rect")).attr({
                                    x:sxoff+xmin,
                                    y:syoff+ymin,
                                    width:xmax-xmin,
                                    height:ymax-ymin,
                                    stroke:"cyan",
                                    "stroke-width":5,
                                    fill:"none",
                                }));
                                svg.append($(document.createElementNS(svg.attr('xmlns'),"text")).attr({
                                    x:sxoff+xmin,
                                    y:syoff+ymin,
                                    fill: 'cyan',
                                }).text(v1.detection.label+":"+Math.floor(v1.detection.confidence*100)+"%"));
                            }
                        }
                        if ("emotion" in v1) {
                        }
                        if ("face_id" in v1) {
                        }
                    });
                });
            }
        }
        if (video[0].paused) return page.data('time_offset',0);
        requestAnimationFrame(drawFrame);
    };

    video.unbind('loadedmetadata').bind('loadedmetadata',function () {
        page.data('objects',{});
        page.data('time_offset',0);
        var start_time=0;
        var read=function (stream) {
            if (!page.is(":visible")) return;
            if ($("#player input").val()!=stream) return;
            apiHost.analytics(stream,start_time,start_time+2).then(function (data) {
                var objects=page.data('objects');
                $.each(data, function (x,v1) {
                    var frame=Math.floor(v1.time*1000/fps);
                    if (!(frame in objects)) objects[frame]=[];
                    objects[frame].push(v1);
                });
                start_time=start_time+2;
                if (start_time<=video[0].duration) {
                    var delta=(start_time-video[0].currentTime-2)*1000;
                    setTimeout(read,delta<0?0:delta,stream);
                }
            });
        };
        read($("#player input").val());
    }).unbind('timeupdate').on('timeupdate',function () {
        var tmp=page.data('time_offset');
        page.data('time_offset',new Date()-video[0].currentTime*1000);
        if (!tmp) drawFrame();
    });
}).on(":mouseclick",function (e) {
    $(this).next().trigger(e);
}).on(":mousemove",function (e) {
    $(this).next().trigger(e);
});

$("[adstats-console]").on(":initpage",function (e) {
    var page=$(this);

    page.data("chart",new Chart(page.find("[adstats-chart]"),{
        type: 'horizontalBar',
        data: {
            labels: [],
            datasets: [{
                data: [],
            }],
        },
        options: {
            elements: {
                rectangle: {
                    borderWidth: 2,
                },
            },
            reponsive: true,
            maintainAspectRatio: false,
            legend: {
                display: false,
            },
            title: {
                display: true,
                text: 'AD Report',
            },
            plugins: {
                colorschemes: {
                    scheme: 'tableau.Tableau20'
                },
            },
        }
    }));
}).on(":update-adstats",function (e, data) {
    var page=$(this);
    var chart=page.data("chart");

    $.each(data,function (k,v) {
        var i=chart.config.data.labels.indexOf(k);
        if (i>=0) {
            chart.config.data.datasets[0].data[i]=v;
            return;
        }
        chart.config.data.labels.push(k);
        chart.config.data.datasets[0].data.push(v);
    });
    chart.update();
});

$("[workloads-console]").on(":initpage",function (e) {
    var page=$(this);

    page.data("chart",new Chart(page.find("[workloads-chart]"),{
        type: 'line',
        data: {
            labels: [],
            datasets: [],
        },
        options: {
            reponsive: true,
            maintainAspectRatio: false,
            title: {
                display: true,
                text: 'Server Workloads',
            },
            scales: {
                yAxes: [{
                    display: true,
                    scaleLabel: {
                        display: false
                    },
                    stacked: false, //true
                }],
                xAxes: [{
                    display: true,
                    scaleLabel: {
                        display: false
                    },
                    type: 'time',
                    time: {
                        displayFormats: {
                            second: 'hh:mm:ss'
                        }
                    },
                    distribution: 'linear',
                }],
            },
            plugins: {
                colorschemes: {
                    scheme: 'tableau.Tableau20'
                },
            },
            elements: {
                line: {
                    tension:0,
                }
            },
            animation: {
                duration:0,
            },
            hover: {
                animationDuration:0,
            },
            responsiveAnimationDuration:0,
        }
    }));
}).on(":update-workloads",function (e, time, machine, workload) {
    var page=$(this);
    var chart=page.data("chart");

    var labels=chart.config.data.labels;
    labels.push(time);
    labels.sort();

    var datasets=chart.config.data.datasets;
    var m=-1;
    for (var i=0;i<datasets.length;i++)
        if (datasets[i].label==machine) { m=i; break; }
    if (m<0) {
        //if (datasets.length==0)
        //    datasets.push({label:machine,fill:'origin',data:[]});
        //else
        //    datasets.push({label:machine,fill:'-1',data:[]});
        datasets.push({label:machine,fill:false,data:[]});
        m=datasets.length-1;
    }

    datasets[m].data.push({t:time,y:workload});
    for (m=0;m<datasets.length;m++) {
        datasets[m].data.sort(function(a,b){
            return (a.t>b.t)-(a.t<b.t);
        });
    }

    /* remove excessive data points */
    if (labels.length>20) {
        var t=labels.shift();
        for (m=0;m<datasets.length;m++)
            for (var i=0;i<datasets[m].data.length;i++)
                datasets[m].data=datasets[m].data.filter(v=>v.t>t);
    }

    chart.update();
});
