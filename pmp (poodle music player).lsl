/* The version number of pmp. */
string version = "2.1.0";

/* CONFIGURATION */

/* The name of the notecard containing the configuration settings */
string config_notecard_name = "pmp config";

/* The default volume to play songs at. */
float default_volume = 1.0;

/* How often to check if the next clip should be played. */
float update_interval = 0.01;

/* END OF CONFIGURATION */

/* How much time is remaining before the next clip plays. */
float time_remaining;

/* The last time the timer event fired. */
float last_timer;

/* Stored lists of clips and songs */
list clips;

/* Current song information */
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

/* These variables store the details of the configuration and song notecards as they're being read in the dataserver event */
string notecard_name;
key notecard_query_id;
integer notecard_index;
integer notecard_line;

/* Whether the script has finished initializing. */
integer initialized = FALSE;

/* JSON-RPC functions */
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

/* Preload a sound clip by playing it silently on a linked prim so it loads faster when actually playing it */
preload(integer index)
{
    key clip_id = llList2Key(clips, index);
    
    if (clip_id)
    {
        jsonrpc_link_notification(LINK_SET, "pmp:preload", JSON_OBJECT, ["sound", clip_id]);
    }
}

/* Read a song notecard into memory and start the song. */
play_song(string name, integer loop, float vol)
{
    if (title != "")
    {
        stop_song();
    }
    
    if (llGetInventoryType(name) == INVENTORY_NOTECARD)
    {
        clips = [];
        repeat = loop;
        volume = vol;
        clip = 0;
        first_clip = 0;
        last_clip = 0;
        
        notecard_query_id = llGetNotecardLine(notecard_name = name, notecard_line = 0);
    }
}

/* Start playing a song */
start_song()
{
    duration = (last_clip - first_clip) * clip_len + last_clip_len;
    
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
    
    paused = FALSE;
    
    /* Give the clip a second to preload and start the timer event */
    time_remaining = 1.0;
    llSetTimerEvent(update_interval);
    
    /* Send out a message to linked prims that a song has been started */
    jsonrpc_link_notification(LINK_SET, "pmp:song-started", JSON_OBJECT, ["title", title]);
}

/* Stop the current song from playing */
stop_song()
{
    clips = [];
    
    /* Send out a message to linked prims that the song has ended or was stopped */
    jsonrpc_link_notification(LINK_SET, "pmp:song-ended", JSON_OBJECT, ["title", title]);
    
    /* Stop any currently playing clip */
    llStopSound();
    
    /* Stop the timer event */
    llSetTimerEvent(0);
    
    /* Reset data. */
    title = "";
    clip = 0;
    first_clip = 0;
    last_clip = 0;
    duration = 0;
}

/* Initialize the script and read the configuration notecard. */
initialize()
{
    llSetText("Initializing...", <1, 1, 1>, 1);

    /* Reset stored clips and songs. */
    initialized = FALSE;
    clips = [];
    
    if (llGetInventoryType(config_notecard_name) == INVENTORY_NOTECARD)
    {
        notecard_query_id = llGetNotecardLine(notecard_name = config_notecard_name, notecard_line = 0);
    }
    else
    {
        llSetText("", ZERO_VECTOR, 0);
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
    
    /* Ignore malformed lines. */
    if (llGetListLength(setting) != 2)
    {
        return;
    }
    
    string setting_name = llList2String(setting, 0);
    string setting_value = llList2String(setting, 1);
    
    if (setting_name == "default_volume")
    {
        default_volume = (float) setting_value;
    }
}

/* Calculate current time of song. */
float get_time()
{
    float t;
        
    if (clip == -1)
    {
        t = duration - time_remaining;
    }
    else
    {
        t = (clip - first_clip) * clip_len - time_remaining;
    }
    
    if (t < 0)
    {
        t = 0;
    }
    
    return t;
}

/* Set the volume of the current song. */
set_volume(float vol)
{
    if (vol < 0)
    {
        vol = 0;
    }
    else if (vol > 1)
    {
        vol = 1;
    }
    
    volume = vol;
    default_volume = vol;
    
    llAdjustSoundVolume(volume);
}

/* Set the playback time of the current song. */
set_time(float time)
{
    llSetTimerEvent(0);
    llStopSound();
    
    if (time < 0.0)
    {
        time = 0.0;
    }
    else if (time > duration)
    {
        time = duration;
    }
    
    clip = first_clip + (integer) (time / clip_len);
        
    preload(clip);
        
    time_remaining = 1.0;
    llSetTimerEvent(update_interval);
}

/* Process a message from a linked prim or listener. */
process_message(integer sender, string message)
{
    /* If we haven't finished initializing, ignore the message */
    if (!initialized)
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
        
        play_song(title, loop, volume);
    }
    else if (method == "pmp:set-volume")
    {        
        set_volume((float) llJsonGetValue(message, ["params", "volume"]));
    }
    else if (method == "pmp:adjust-volume")
    {
        float by = (float) llJsonGetValue(message, ["params", "by"]);
        set_volume(volume + by);
    }
    else if (method == "pmp:set-time")
    {
        set_time((float) llJsonGetValue(message, ["params", "time"]));
    }
    else if (method == "pmp:adjust-time")
    {
        float by = (float) llJsonGetValue(message, ["params", "by"]);
        set_time(get_time() + by);
    }
    else if (method == "pmp:pause")
    {
        if (paused)
        {
            paused = FALSE;
            preload(clip);
            time_remaining = 1.0;
            llSetTimerEvent(update_interval);
        }
        else
        {
            paused = TRUE;
            llStopSound();
            llSetTimerEvent(0);
            
            /* Go back to the previous clip */
            if (clip > first_clip)
            {
                --clip;
            }
        }
    }
    else if (method == "pmp:info")
    {
        jsonrpc_link_response(sender, message, llList2Json(JSON_OBJECT, [
            "title", title,
            "time", get_time(),
            "duration", duration,
            "paused", paused,
            "volume", volume
        ]));
    }
}

/* Parse a line of a notecard being read. */
parse_notecard_line(string data)
{
    /* If this is the first line... */
    if (notecard_line == 0)
    {
        /* If this is the first line of the configuration file, handle it the same as any other line */
        if (notecard_name == config_notecard_name)
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
        if (notecard_name == config_notecard_name)
        {
            process_config(data);
        }
        /* All other lines in a song notecard will be the UUIDs of each sound clip, so add them to the stored clips list */
        else
        {
            clips += (key) data;
        }
    }   
}

default
{
    state_entry()
    {
        initialize();
    }
    
    timer()
    {
        time_remaining -= llGetTime() - last_timer;
        
        last_timer = llGetTime();
                
        if (time_remaining <= 0)
        {
            /* If the clip is -1, the song has ended, so stop playing and exit */
            if (clip == -1)
            {
                stop_song();
                return;
            }
            
            /* Play the current sound clip */
            key clip_id = llList2Key(clips, clip);
            
            if (clip_id)
            {
                llPlaySound(clip_id, volume);
            }
            
            /* If the current clip is the intro clip, the next clip is the first main clip */
            if (clip == intro_clip)
            {
                clip = first_clip;
                time_remaining = intro_clip_len;
            }
            /* If the current clip is any of the clips except the last, the next clip is the next index up. */
            else if (clip < last_clip)
            {
                ++clip;
                time_remaining = clip_len;
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
                
                time_remaining = last_clip_len;
            }
            
            /* Preload the next clip unless there is none */
            if (clip != -1)
            {
                preload(clip);
            }
        }        
    }
    
    dataserver(key request_id, string data)
    {
        /* Ignore any requests not made by this script */
        if (request_id != notecard_query_id)
        {
            return;
        }
        
        while (data != EOF && data != NAK)
        {
            parse_notecard_line(data);
            data = llGetNotecardLineSync(notecard_name, ++notecard_line);
        }

        if (data == NAK)
        {
            notecard_query_id = llGetNotecardLine(notecard_name, notecard_line);
        }

        if (data == EOF)
        {
            if (notecard_name == config_notecard_name)
            {
                llSetText("", ZERO_VECTOR, 0);
                
                if (!initialized)
                {
                    initialized = TRUE;
                    jsonrpc_link_notification(LINK_SET, "pmp:startup-complete", JSON_OBJECT, []);
                    llOwnerSay("Free memory: " + (string) llGetFreeMemory());
                }
            }
            else
            {
                last_clip = llGetListLength(clips) - 1;
                title = notecard_name;
                start_song();
            }            
        }
    }
    
    /* Process commands from linked prims */
    link_message(integer sender, integer num, string str, key id)
    {
        process_message(sender, str);
    }
}
