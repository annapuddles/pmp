/* The version number of pmp. */
string version = "1.0.0";

/* The name of the notecard containing the configuration settings */
string CONFIG_NAME = "pmp config";

/* Configurable options */
integer debug = FALSE;
integer hover_text = TRUE;
vector hover_text_color = <1, 1, 1>;
float hover_text_alpha = 1;
float default_volume = 1.0;
integer progress_bar_size = 30;
string progress_bar_start = "|";
string progress_bar_fill = "-";
string progress_bar_head = "[]";
string progress_bar_end = "|";

/* Stored lists of clips and songs */
list clips;
list songs;

/* Current song information */
integer song = -1;
string title;
integer intro_clip;
float intro_clip_len;
integer first_clip;
integer last_clip;
float clip_len;
float last_clip_len;
integer repeat;
float volume;
integer clip;
float duration;
integer paused;

string jsonrpc_link_request(integer link, string method, string params_type, list params, string id)
{
    if (id == "") id = (string) llGenerateKey();
    llMessageLinked(link, 0, llList2Json(JSON_OBJECT, ["jsonrpc", "2.0", "id", id, "method", method, "params", llList2Json(params_type, params)]), NULL_KEY);
    return id;
}

jsonrpc_link_notification(integer link, string method, string params_type, list params)
{
    llMessageLinked(link, 0, llList2Json(JSON_OBJECT, ["jsonrpc", "2.0", "method", method, "params", llList2Json(params_type, params)]), NULL_KEY);
}

jsonrpc_link_response(integer link, string request, string result)
{
    string id = llJsonGetValue(request, ["id"]);
    llMessageLinked(link, 0, llList2Json(JSON_OBJECT, ["jsonrpc", "2.0", "id", id, "result", result]), NULL_KEY);
}

/* Set the hover text using the configured color and alpha */
set_hover_text(string text)
{
    llSetText(text, hover_text_color, hover_text_alpha);
}

/* Preload a sound clip by playing it silently on a linked prim so it loads faster when actually playing it */
preload(integer index)
{
    jsonrpc_link_notification(LINK_SET, "pmp:preload", JSON_OBJECT, ["sound", llList2Key(clips, index)]);;
}

/* Play a sound clip by its index in the stored clips list */
play_clip(integer index)
{
    llPlaySound(llList2Key(clips, index), volume);
}

/* Start playing a song */
start_song(string name, integer loop, float vol)
{
    /* Locate the song in the stored songs list */
    integer index = llListFindList(songs, [name]);
    
    /* If the song could not be found, exit */
    if (index == -1)
    {
        if (debug)
        {
            llOwnerSay("Invalid song: " + name);
        }
        
        return;
    }
    
    /* If the song is already playing, exit */
    if (song == index)
    {
        return;
    }

    /* Set the current song details */
    song = index;
    title = llList2String(songs, index++);
    intro_clip = llList2Integer(songs, index++);
    intro_clip_len = llList2Float(songs, index++);
    first_clip = llList2Integer(songs, index++);
    last_clip = llList2Integer(songs, index++);
    clip_len = llList2Float(songs, index++);
    last_clip_len = llList2Float(songs, index++);
    repeat = loop;
    volume = vol;
    duration = (last_clip - first_clip - 1) * clip_len + last_clip_len;

    if (debug)
    {
        llOwnerSay("Playing " + title);
    }
    
    /* Set hover text */
    if (hover_text)
    {
        set_hover_text("Playing: " + title);
    }
    
    /* If the song has an intro clip, play that first */
    if (intro_clip != -1)
    {
        clip = intro_clip;
    }
    /* Otherwise, start with the first main clip */
    else
    {
        clip = first_clip;
    }
    
    /* Preload the first clip so it will load faster */
    preload(clip);
    
    /* Give the clip a second to preload and start the timer event */
    llSetTimerEvent(1.0);
    
    /* Send out a message to linked prims that a song has been started */
    jsonrpc_link_notification(LINK_SET, "pmp:song-started", JSON_OBJECT, ["title", title]);
}

/* Stop the current song from playing */
stop_song()
{
    /* If no song is playing, exit */
    if (song == -1)
    {
        return;
    }
    
    /* Send out a message to linked prims that the song has ended or was stopped */
    jsonrpc_link_notification(LINK_SET, "pmp:song-ended", JSON_OBJECT, ["title", title]);
    
    /* Unset the current song details */
    song = -1;
    
    if (debug)
    {
        llOwnerSay("Stopping");
    }
    
    /* Clear the hover text */
    set_hover_text("");
    
    /* Stop any currently playing clip */
    llStopSound();
    
    /* Stop the timer event */
    llSetTimerEvent(0);
}

/* Pause the current song */
pause_song()
{
    if (song == -1)
    {
        return;
    }
    
    if (paused)
    {
        return;
    }

    paused = TRUE;
    llStopSound();
    llSetTimerEvent(0);
    
    /* Go back to the previous clip */
    if (clip > first_clip)
    {
        --clip;
    }
    
    /* Update the hover text if applicable */
    if (hover_text)
    {
        set_playback_hover_text();
    }
}

/* Resume playing the current song */
resume_song()
{
    if (song == -1)
    {
        return;
    }
    
    if (!paused)
    {
        return;
    }

    paused = FALSE;
    preload(clip);
    llSetTimerEvent(1.0);
}

/* Check whether any song is currently playing */
integer is_song_playing()
{
    return song != -1;
}

/* These variables store the details of the configuration and song notecards as they're being read in the dataserver event */
list notecards;
key notecard_query_id;
integer notecard_index;
integer notecard_line;
integer notecards_read = FALSE;

/* Read songs from notecards in the inventory. */
read_notecards()
{
    if (debug)
    {
        llOwnerSay("Initializing...");
    }
    
    set_hover_text("Initializing...");

    /* Reset stored clips and songs. */
    notecards_read = FALSE;
    clips = [];
    songs = [];

    /* Get the total number of notecards in the inventory. */
    integer total = llGetInventoryNumber(INVENTORY_NOTECARD);
    
    /* Create a list of all the notecard names that need to be read. */
    notecards = [];
    integer i;
    for (i = 0; i < total; ++i)
    {
        string name = llGetInventoryName(INVENTORY_NOTECARD, i);
        
        /* Ensure the configuration notecard is read first */
        if (name == CONFIG_NAME)
        {
            notecards = [name] + notecards;
        }
        else
        {
            notecards += name;
        }
    }
    
    /* If there are any new notecards to read, begin the process */
    if (llGetListLength(notecards) > 0)
    {
        /* Reset indexes. */
        notecard_index = 0;
        notecard_line = 0;
        first_clip = 0;
        last_clip = 0;
        
        /* Start reading the first line of the first notecard. */
        notecard_query_id = llGetNotecardLine(llList2String(notecards, notecard_index), notecard_line);
    }
    else
    {
        set_hover_text("");
    }
}

/* Process a line in the configuration notecard */
process_config(string data)
{
    /* Ignore comments. */
    if (llGetSubString(data, 0, 1) == "#")
    {
        return;
    }
    
    /* Each line will be in the form of: setting_name = setting_value */
    list setting = llParseString2List(data, [" = "], []);
    
    string setting_name = llList2String(setting, 0);
    string setting_value = llList2String(setting, 1);
    
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
    else if (setting_name == "debug")
    {
        debug = (integer) setting_value;
    }
    else if (setting_name == "default_volume")
    {
        default_volume = (float) setting_value;
    }
    else if (setting_name == "progress_bar_size")
    {
        progress_bar_size = (integer) setting_value;
    }
    else if (setting_name == "progress_bar_end")
    {
        progress_bar_end = setting_value;
    }
    else if (setting_name == "progress_bar_fill")
    {
        progress_bar_fill = setting_value;
    }
    else if (setting_name == "progress_bar_head")
    {
        progress_bar_head = setting_value;
    }
    else if (setting_name == "progress_bar_start")
    {
        progress_bar_start = setting_value;
    }
}

/* Check if the music player is ready to be used. */
integer is_ready()
{
    return notecards_read;
}

/* Get the current song title, or empty string if no song is playing */
string get_title()
{
    if (song == -1)
    {
        return "";
    }
     
    return title;
}

/* Get a percentage of progress in the current song as a value from 0.0 to 1.0, or -1 if no song is playing */
float get_progress()
{
    if (song == -1)
    {
        return -1;
    }

    return (float) (clip - first_clip) / (float) (last_clip - first_clip);
}

/* Get the current time of the current song in seconds, or -1 if no song is playing */
float get_time()
{
    if (song == -1)
    {
        return -1;
    }

    return (clip - first_clip) * clip_len;
}

/* Set the current playback time in seconds with error checking */
set_time(float time)
{
    if (song == -1)
    {
        return;
    }
    
    if (time < 0.0)
    {
        time = 0.0;
    }
    else if (time > duration)
    {
        time = duration;
    }
    
    clip = first_clip + (integer) (time / clip_len);

    if (debug)
    {
        llOwnerSay("Time set to " + (string) time);
    }
    
    preload(clip);
    
    llSetTimerEvent(1.0);
}

/* Get the current song duration in seconds, or -1 if no song is playing */
float get_duration()
{
    if (song == -1)
    {
        return -1;
    }
    
    return duration;
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
    integer t = (integer) time;
    integer s = t % 60;
    integer m = (t / 60) % 60;
    integer h = t / 3600;
    
    string s_s;
    string m_s;
    string h_s;
    
    return zero_pad(h) + ":" + zero_pad(m) + ":" + zero_pad(s);
}

/* Get the volume setting, either the current song's volume, or the default volume if no song is playing */
float get_volume()
{
    if (song == -1)
    {
        return default_volume;
    }
    else
    {
        return volume;
    }
}

/* Set the volume settings with error checking */
set_volume(float vol)
{
    if (vol >= 0.0 && vol <= 1.0)
    {
        volume = vol;
        default_volume = vol;
        
        if (debug)
        {
            llOwnerSay("Volume set to " + (string) volume);
        }
    }
    else
    {
        if (debug)
        {
            llOwnerSay("Invalid volume value: " + (string) volume);
        }
    }
    
    /* Update the hover text if applicable */
    if (hover_text)
    {
        set_playback_hover_text();
    }
}

/* Process a message from a linked prim or listener. */
process_message(integer sender, string message)
{
    /* If we haven't finished initializing, ignore the message */
    if (!is_ready())
    {
        return;
    }
    
    string method = llJsonGetValue(message, ["method"]);
    
    if (method == "pmp:stop")
    {
        stop_song();
    }
    else if (method == "pmp:play")
    {
        string title;
        integer loop;
        float volume;
        
        if (llJsonValueType(message, ["params", "title"]) == JSON_STRING)
        {
            title = llJsonGetValue(message, ["params", "title"]);
        }
        else
        {
            return;
        }
        
        if (llJsonValueType(message, ["params", "loop"]) == JSON_NUMBER)
        {
            loop = (integer) llJsonGetValue(message, ["params", "loop"]);
        }
        else
        {
            loop = FALSE;
        }
        
        if (llJsonValueType(message, ["params", "volume"]) == JSON_NUMBER)
        {
            volume = (float) llJsonGetValue(message, ["params", "volume"]);
        }
        else
        {
            volume = default_volume;
        }
        
        start_song(title, loop, volume);
    }
    else if (method == "pmp:is-ready")
    {
        string id = llJsonGetValue(message, ["id"]);
        
        jsonrpc_link_response(sender, message, (string) is_ready());
    }
    else if (method == "pmp:current-song")
    {
        jsonrpc_link_response(sender, message, get_title());
    }
    else if (method == "pmp:set-volume")
    {
        float volume = (float) llJsonGetValue(message, ["params", "volume"]);
        set_volume(volume);
    }
    else if (method == "pmp:get-volume")
    {
        jsonrpc_link_response(sender, message, (string) get_volume());
    }
    else if (method == "pmp:get-duration")
    {
        jsonrpc_link_response(sender, message, (string) get_duration());
    }
    else if (method == "pmp:get-time")
    {
        jsonrpc_link_response(sender, message, (string) get_time());
    }
    else if (method == "pmp:set-time")
    {
        float time = (float) llJsonGetValue(message, ["params", "time"]);
        set_time(time);
    }
    else if (method == "pmp:get-progress")
    {
        jsonrpc_link_response(sender, message, (string) get_progress());
    }
    else if (method == "pmp:pause")
    {
        pause_song();
    }
    else if (method == "pmp:resume")
    {
        resume_song();
    }
    else if (method == "pmp:is-paused")
    {
        jsonrpc_link_response(sender, message, (string) paused);
    }
}

/* Set the playback status hover text */
set_playback_hover_text()
{
    /* Calculate the position of the head on the progress bar */
    integer head_pos = (integer) (get_progress() * progress_bar_size);

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
        status = "Paused";
    }
    else
    {
        status = "Playing";
    }

    /* Set the hover text */
    set_hover_text(status + ": " + title + " (" + vol + "%)\n" + time_to_string(get_time()) + " " + bar + " " + time_to_string(duration));
}

default
{
    state_entry()
    {
        read_notecards();
    }
    
    timer()
    {
        /* If the clip is -1, the song has ended, so stop playing and exit */
        if (clip == -1)
        {
            stop_song();
            return;
        }
        
        /* Set the playback status hover text */
        if (hover_text)
        {
            set_playback_hover_text();
        }
        
        /* Play the current sound clip */
        play_clip(clip);
        
        /* If the current clip is the intro clip, the next clip is the first main clip */
        if (clip == intro_clip)
        {
            clip = first_clip;
            llSetTimerEvent(intro_clip_len);
        }
        /* If the current clip is any of the clips except the last, the next clip is the next index up. */
        else if (clip < last_clip)
        {
            clip = clip + 1;
            llSetTimerEvent(clip_len);
        }
        /* Otherwise, if the current clip is the last clip... */
        else
        {
            /* If loop mode is on, go back to the first main clip */
            if (repeat)
            {
                clip = first_clip;
            }
            /* Otherwise, set clip to -1 so the next timer event will end the song */
            else
            {
                clip = -1;
            }

            llSetTimerEvent(last_clip_len);
        }
        
        /* Preload the next clip unless there is none */
        if (clip != -1)
        {
            preload(clip);
        }
    }
    
    dataserver(key request_id, string data)
    {
        /* Ignore any requests not made by this script */
        if (request_id != notecard_query_id)
        {
            return;
        }
        
        /* Get the name of the current notecard that is being read */
        string name = llList2String(notecards, notecard_index);
        
        /* If the end of the notecard has been reached... */
        if (data == EOF)
        {
            /* If the notecard being read is the configuration notecard, there's nothing else to do after reaching the end */
            if (name == CONFIG_NAME)
            {
                /* If in debug mode, print out the values of all the configuration settings */
                if (debug)
                {
                    llOwnerSay("Version: " + version);
                    llOwnerSay("Configuration:");
                    llOwnerSay("  hover_text = " + (string) hover_text);
                    llOwnerSay("  hover_text_color = " + (string) hover_text_color);
                    llOwnerSay("  hover_text_alpha = " + (string) hover_text_alpha);
                    llOwnerSay("  default_volume = " + (string) default_volume);
                    llOwnerSay("  progress_bar_size = " + (string) progress_bar_size);
                    llOwnerSay("  progress_bar_start = " + progress_bar_start);
                    llOwnerSay("  progress_bar_fill = " + progress_bar_fill);
                    llOwnerSay("  progress_bar_head = " + progress_bar_head);
                    llOwnerSay("  progress_bar_end = " + progress_bar_end);
                }
            }
            /* If the notecard is a song notecard, add the song to the stored song list */
            else
            {
                /* Append the song to the stored songs list with the details read from the notecard */
                songs += [name, intro_clip, intro_clip_len, first_clip, last_clip - 1, clip_len, last_clip_len];
                
                /* If in debug mode, print out the details read from the song notecard */
                if (debug)
                {
                    llOwnerSay("  title: " + name);
                    llOwnerSay("  intro_clip: " + (string) intro_clip);
                    llOwnerSay("  intro_clip_len: " + (string) intro_clip_len);
                    llOwnerSay("  first_clip: " + (string) first_clip);
                    llOwnerSay("  last_clip: " + (string) (last_clip - 1));
                    llOwnerSay("  clip_len: " + (string) clip_len);
                    llOwnerSay("  last_clip_len: " + (string) last_clip_len);
                }
                
                /* Set the first clip of the next song to the index after the last clip of this song */
                first_clip = last_clip;
            }
            
            /* Move to the next notecard in the queue */
            ++notecard_index;
            
            /* If all the notecards have been read, finish the initialization process */
            if (notecard_index >= llGetListLength(notecards))
            {
                if (debug)
                {
                    llOwnerSay("Finished reading notecards.");
                }
                
                set_hover_text("");
                
                notecards_read = TRUE;
                
                jsonrpc_link_notification(LINK_SET, "pmp:startup-complete", JSON_OBJECT, []);

                return;
            }
            
            /* Get the name of the next notecard to read and reset the line counter to 0 */
            name = llList2String(notecards, notecard_index);            
            notecard_line = 0;            
        }
        /* If this is a line from a notecard, process it */
        else
        {
            /* If this is the first line... */
            if (notecard_line == 0)
            {
                if (debug)
                {
                    llOwnerSay("Reading " + name + "...");
                }
                
                /* If this is the first line of the configuration file, handle it the same as any other line */
                if (name == CONFIG_NAME)
                {
                    process_config(data);
                }
                /* If this is the first line of a song notecard, then read the clip length details */
                else
                {
                    list info = llParseString2List(data, [" "], []);
                    
                    integer len = llGetListLength(info);
                    
                    if (len == 1)
                    {
                        intro_clip = -1;
                        intro_clip_len = 0;
                        clip_len = (float) llList2String(info, 0);
                        last_clip_len = (float) llList2String(info, 0);
                    }
                    else if (len == 2)
                    {
                        intro_clip = -1;
                        intro_clip_len = 0;
                        clip_len = (float) llList2String(info, 0);
                        last_clip_len = (float) llList2String(info, 1);
                    }
                    else if (len == 3)
                    {
                        intro_clip = first_clip;
                        intro_clip_len = (float) llList2String(info, 0);
                        clip_len = (float) llList2String(info, 1);
                        last_clip_len = (float) llList2String(info, 2);
                        
                        ++first_clip;
                    }
                }
            }
            /* If this is any other line than the first... */
            else
            {
                /* Handle lines in the configuration file the same way */
                if (name == CONFIG_NAME)
                {
                    process_config(data);
                }
                /* All other lines in a song notecard will be the UUIDs of each sound clip, so add them to the stored clips list */
                else
                {
                    clips += (key) data;
                    ++last_clip;
                }
            }
            
            /* Move to the next line in the notecard */
            ++notecard_line;
        }
        
        /* Read the next line in the notecard */
        notecard_query_id = llGetNotecardLine(name, notecard_line);
    }
    
    /* Process commands from linked prims */
    link_message(integer sender, integer num, string str, key id)
    {
        process_message(sender, str);
    }
    
    /* If the inventory changes, re-initialize to update the configuration and list of songs */
    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            stop_song();
            read_notecards();
        }
    }
}
