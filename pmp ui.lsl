/* pmp ui - Example user interface for pmp. */

/* The name of the notecard containing the configuration settings */
string config_notecard_name = "pmp config";

/* Configurable options */
integer hover_text = FALSE;
vector hover_text_color = <1, 1, 1>;
float hover_text_alpha = 1;
float default_volume = 1;
integer progress_bar_size = 30;
string progress_bar_start = "|";
string progress_bar_end = "|";
string progress_bar_fill = "-";
string progress_bar_head = "█";

/* Channel used for dialogs. */
integer dialog_channel = -623424;

string info_request;
integer listener;

key notecard_query;
integer notecard_line;

integer page;

jsonrpc_link_notification(integer link, string method, string params_type, list params)
{
    llMessageLinked(link, 0, llList2Json(JSON_OBJECT, ["jsonrpc", "2.0", "method", method, "params", llList2Json(params_type, params)]), NULL_KEY);
}

string jsonrpc_link_request(integer link, string method, string params_type, list params, string id)
{
    if (id == "") id = (string) llGenerateKey();
    llMessageLinked(link, 0, llList2Json(JSON_OBJECT, ["jsonrpc", "2.0", "id", id, "method", method, "params", llList2Json(params_type, params)]), NULL_KEY);
    return id;
}

/* Convert an integer to a string with left zero padding */
string zero_pad(integer n)
{
    if (n < 10)
    {
        return "0" + (string) n;
    }
    else
    {
        return (string) n;
    }
}

/* Convert a time in seconds to an HH:MM:SS timecode string */
string time_to_string(float time)
{
    string sign;

    if (time < 0)
    {
        sign = "-";
    }

    integer t = (integer) llFabs(time);
    integer s = t % 60;
    integer m = (t / 60) % 60;
    integer h = t / 3600;

    return sign + zero_pad(h) + ":" + zero_pad(m) + ":" + zero_pad(s);
}

/* Set the hover text using the configured color and alpha */
set_hover_text(string text)
{
    llSetText(text, hover_text_color, hover_text_alpha);
}

/* Set the playback status hover text */
set_playback_hover_text(string title, float time, float duration, integer paused, float volume)
{
    float progress = time / duration;

    /* Calculate the position of the head on the progress bar */
    integer head_pos = (integer) (progress * progress_bar_size);

    /* Create the progress bar string */
    string bar = progress_bar_start;

    integer i;

    for (i = 0; i < head_pos; ++i)
    {
        bar += progress_bar_fill;
    }

    bar += progress_bar_head;

    for (; i < progress_bar_size; ++i)
    {
        bar += progress_bar_fill;
    }

    bar += progress_bar_end;

    string vol = (string) ((integer) (volume * 100));

    string status;

    if (paused)
    {
        status = "⏸️ Paused";
    }
    else
    {
        status = "🎵 Playing";
    }

    /* Set the hover text */
    set_hover_text(status + ": " + title + " (🔊 " + vol + "%)\n" + time_to_string(time) + " " + bar + " " + time_to_string(duration));
}

process_config(string data)
{
    /* Ignore comments. */
    if (llGetSubString(data, 0, 1) == "#")
    {
        return;
    }

    /* Each line will be in the form of: setting_name = setting_value */
    list parts = llParseStringKeepNulls(data, [" = "], []);

    /* Ignore malformed lines. */
    if (llGetListLength(parts) != 2)
    {
        return;
    }

    string setting_name = llList2String(parts, 0);
    string setting_value = llList2String(parts, 1);
    
    if (setting_name == "hover_text")
    {
        hover_text = (integer) setting_value;
    }
    else if (setting_name == "hover_text_color")
    {
        hover_text_color = (vector) setting_value;
    }
    else if (setting_name == "hover_text_alpha")
    {
        hover_text_alpha = (float) setting_value;
    }
    else if (setting_name == "default_volume")
    {
        default_volume = (float) setting_value;
    }
    else if (setting_name == "progress_bar_size")
    {
        progress_bar_size = (integer) setting_value;
    }
    else if (setting_name == "progress_bar_start")
    {
        progress_bar_start = setting_value;
    }
    else if (setting_name == "progress_bar_end")
    {
        progress_bar_end = setting_value;
    }
    else if (setting_name == "progress_bar_head")
    {
        progress_bar_head = setting_value;
    }
    else if (setting_name == "progress_bar_fill")
    {
        progress_bar_fill = setting_value;
    }
}

list song_list()
{
    list songs;
    
    integer num_notecards = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer i;
    
    for (i = 0; i < num_notecards; ++i)
    {
        string name = llGetInventoryName(INVENTORY_NOTECARD, i);
        
        if (name != config_notecard_name)
        {
            songs += name;
        }
    }
    
    return songs;
}

open_song_menu(key id)
{
    list songs = song_list();
    integer num_songs = llGetListLength(songs);
    
    integer total_pages = llCeil(num_songs / 9.0);
    
    string text = "\nPick a song (pg " + (string) (page + 1) + " of " + (string) total_pages + "):\n";
    list buttons;
    
    integer i;

    for (i = page * 9; i < (page + 1) * 9 && i < num_songs; ++i)
    {
        text += "\n" + (string) i + ": " + llList2String(songs, i);
        buttons += (string) i;
    }

    llListenRemove(listener);
    listener = llListen(dialog_channel, "", id, "");
    llDialog(id, text, ["<", "STOP", ">"] + buttons, dialog_channel);
}

default
{
    state_entry()
    {
        notecard_query = llGetNotecardLine(config_notecard_name, notecard_line = 0);
    }

    dataserver(key query_id, string data)
    {
        if (query_id != notecard_query)
        {
            return;
        }

        while (data != EOF && data != NAK)
        {
            process_config(data);   
            data = llGetNotecardLineSync(config_notecard_name, ++notecard_line);
        }
        
        if (data == NAK)
        {
            notecard_query == llGetNotecardLine(config_notecard_name, ++notecard_line);
        }
        
        if (data == EOF)
        {
            if (hover_text)
            {
                llSetTimerEvent(1);
            }
        }
    }

    touch_start(integer num_detected)
    {
        key toucher = llDetectedKey(0);

        if (toucher != llGetOwner())
        {
            return;
        }
        
        open_song_menu(toucher);
    }

    listen(integer channel, string name, key id, string message)
    {
        llListenRemove(listener);
        
        list songs = song_list();
        integer num_songs = llGetListLength(songs);
        integer total_pages = llCeil(num_songs / 9.0);

        if (message == "STOP")
        {
            jsonrpc_link_notification(LINK_SET, "pmp:stop", JSON_OBJECT, []);
        }
        else if (message == "<")
        {
            if (page > 0)
            {
                --page;
            }
            else
            {
                page = total_pages - 1;
            }

            open_song_menu(id);
        }
        else if (message == ">")
        {            
            if (page < total_pages - 1)
            {
                ++page;
            }
            else
            {
                page = 0;
            }

            open_song_menu(id);
        }
        else
        {
            integer index = (integer) message;

            if (index < num_songs)
            {
                jsonrpc_link_notification(LINK_SET, "pmp:play", JSON_OBJECT, ["title", llList2String(songs, index), "loop", FALSE, "volume", default_volume]);
            }
        }
    }

    timer()
    {
        info_request = jsonrpc_link_request(LINK_SET, "pmp:info", JSON_OBJECT, [], "");
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (llJsonGetValue(str, ["id"]) != info_request)
        {
            return;
        }
        
        string title = llJsonGetValue(str, ["result", "title"]);

        if (title == JSON_INVALID)
        {
            return;
        }

        if (title == "")
        {
            llSetText("", ZERO_VECTOR, 0);
        }
        else
        {
            float time = (float) llJsonGetValue(str, ["result", "time"]);
            float duration = (float) llJsonGetValue(str, ["result", "duration"]);
            integer paused = (integer) llJsonGetValue(str, ["result", "paused"]);
            float volume = (float) llJsonGetValue(str, ["result", "volume"]);
            set_playback_hover_text(title, time, duration, paused, volume);
        }
    }
}
