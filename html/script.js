var pages = {
    list: "<table><thead><tr><th>ID</th><th>Name</th><th>Group</th><th>Job</th><th>Ping</th></tr></thead><tbody></tbody></table>",
    con: "<table><thead><tr><th>Name</th><th>Time</th></tr></thead><tbody></tbody></table>",
    disc: "<table><thead><tr><th>Name</th><th>Reason</th><th>Time</th></tr></thead><tbody></tbody></table>"
};
var lasttimeout, mygroup, mouseX, mouseY;

Number.prototype.map = function(in_min, in_max, out_min, out_max) {
    return (this - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

function hexidtodec(sid) {
    return BigInt("0x" + sid.replace("steam:", "")).toString(10);
}

function toggleMenu(state) {
    if (state) {
        $(".main").show();
    } else {
        $(".main,.player-context").hide();
        $(".main-content").html(pages["list"]);
        $(".navbtn").removeClass("selected");
        $($(".navbtn")[0]).addClass("selected");
    }
}

function pingColor(ping) {
    return [ping.map(0, 150, 0, 255), ping.map(0, 150, 255, 0)];
}

function copyText(text, callbackText, callbackFadeTime) {
    clearTimeout(lasttimeout);
    var temp = $("<input>");
    $("body").append(temp);
    temp.val(text).select();
    document.execCommand("copy");
    temp.remove();
    $(".copied").text(callbackText);
    $(".copied").fadeIn();
    lasttimeout = setTimeout(function() {
        $(".copied").fadeOut();
    }, callbackFadeTime);
}

$(function() {
    if (Config.el_bwh_installed) {
        // $('<div class="pl-ctx-btn" style="color:red;" data-action="ban">Ban</div>').insertBefore($(".pl-ctx-btn")[0]); // coming soon :)
        $('<div class="pl-ctx-btn" style="color:orange;" data-action="warn">Warn</div>').insertAfter($(".pl-ctx-btn")[0]);
    }
    $(document).on("click", "#player", function() {
        copyText("https://steamcommunity.com/profiles/" + hexidtodec($(this).data("steamid")), "Steam profile link copied to clipboard", 1500);
    });
    $(".navbtn").click(function() {
        var page = $(this).data("page");
        if (page === undefined) {
            switch ($(this).data("action")) {
                case "web":
                    copyText(Config.website_url, "Website link copied to clipboard", 1500);
                    break;
                case "discord":
                    copyText(Config.discord_url, "Discord link copied to clipboard", 1500);
                    break;
                case "sg":
                    copyText(Config.steam_group_url, "Stean group link copied to clipboard", 1500);
                    break;
                default:
                    console.log("el_scoreboard: unknown button action");
                    break;
            }
        } else {
            $(".navbtn").removeClass("selected");
            $(this).addClass("selected");
            $(".main-content").html(pages[page]);
        }
    });
    $(document).on("contextmenu", "#player", function() {
        if (mygroup !== undefined && Config.admin_groups.includes(mygroup)) {
            $(".player-context").data("sid", $(this).data("sid"));
            $(".player-context").css("top", mouseY);
            $(".player-context").css("left", mouseX);
            $(".player-context").fadeIn();
        }
    });
    $(".pl-ctx-btn").click(function() {
        var receiver = $($(this).parent()).data("sid");
        var action = $(this).data("action");
        if (mygroup !== undefined && Config.admin_groups.includes(mygroup)) {
            var args = null;
            if (["ban", "warn", "kick"].includes(action)) {
                args = window.prompt(action == "ban" ? "Enter ban reason" : (action == "warn" ? "Enter warn message" : "Enter kick reason"), "N/A");
            }
            $.post("http://el_scoreboard/admin-ctx", JSON.stringify({ action: action, target: receiver, args: args }));
        }
    });
    $(document).on("click", function() {
        if ($(".player-context").css("display") != "none") {
            $(".player-context").fadeOut();
        }
    });
});

window.addEventListener('message', function(event) {
    switch (event.data.type) {
        case "toggle":
            toggleMenu(event.data.state);
            break;
        case "setup":
            $(".pname").text(event.data.pn);
            $(".servername").text(event.data.sn);
            $.get("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=" + Config.steam_api_key + "&steamids=" + hexidtodec(event.data.sid), function(data) {
                $(".pfp").prop("src", data.response.players[0].avatarfull);
            });
            break;
        case "update":
            mygroup = event.data.mygroup;
            var newtable = "";
            switch ($(".navbtn.selected").data("page")) {
                case "list":
                    $(event.data.data.pd).each(function(k, v) {
                        var pc = pingColor(v.ping);
                        newtable +=
                            "<tr id='player' data-steamid='" + v.stid + "' data-sid='" + v.sid.toString() + "'>" +
                            "<td>" + v.sid.toString() + "</td>" +
                            "<td>" + v.name + "</td>" +
                            "<td>" + (Config.group_labels[v.group] != null ? Config.group_labels[v.group] : v.group) + "</td>" +
                            "<td>" + v.job + "</td>" +
                            "<td><span style='color:rgb(" + pc[0] + "," + pc[1] + ",0);'>" + v.ping.toString() + "</span> ms</td>" +
                            "</tr>";
                    });
                    break;
                case "con":
                    $(event.data.data.con).each(function(k, v) {
                        var time = new Date(v.time * 1000);
                        newtable +=
                            "<tr>" +
                            "<td>" + v.name + "</td>" +
                            "<td>" + (time.toLocaleDateString() + " " + time.toLocaleTimeString()) + "</td>" +
                            "</tr>";
                    });
                    break;
                case "disc":
                    $(event.data.data.con).each(function(k, v) {
                        var time = new Date(v.time * 1000);
                        newtable +=
                            "<tr>" +
                            "<td>" + v.name + "</td>" +
                            "<td>" + (v.reason === undefined ? "Disconnected" : v.reason) + "</td>" +
                            "<td>" + (time.toLocaleDateString() + " " + time.toLocaleTimeString()) + "</td>" +
                            "</tr>";
                    });
                    break;
            }
            $("table > tbody").html(newtable);
            break;
        default:
            console.log("el_scoreboard: unknown event type");
            break;
    }
});

$(document).mousemove(function(e) {
    mouseX = e.pageX;
    mouseY = e.pageY;
}).mouseover();

document.onkeydown = function(data) {
    if (data.which == 27 || data.which == 120) {
        $.post("http://el_scoreboard/toggle", JSON.stringify(false));
        toggleMenu(false);
    }
};