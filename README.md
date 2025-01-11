# Adding pmp to an object

To add the Poodle Music Player (pmp) to an object, place the "pmp (poodle music player)" script, "pmp config" notecard, "pmp preloader", and any song notecards on to a prim.

The preloader is optional, but can improve the smoothness of playback.


# Creating song notecards

First, you must divide your song into clips of 10 seconds or less in order to upload them. All of the clips must be the same length except the last.

Next, create a notecard for the song. A song notecard has the following format:

```
[<intro_clip_len>] <clip_len> [<last_clip_len>]
<clip 1 UUID>
<clip 2 UUID>
...
```
    
The first line has one to three float values:

- If only one value is given, then it is the length of all clips, including the last. There is no intro clip.

- If two values are given, the first is the length of all the clips except the last, and the second is the length of the last clip. There is no intro clip.

- If three values are given, the first is the length of the intro clip, which must be the first clip listed. The second is the length of all clips except the last, and the third is the length of the last clip.

The intro clip of a song is a clip which plays once when the song is started, but does not repeat if the song is set to loop.

The rest of the lines in the notecard will be the UUIDs of each clip. They must be in the correct order, and if the song has an intro clip, it must be the first clip listed.

The name of the notecard is the name you use to start the song, for example when using the `pmp:play` command.

# Interacting with pmp

The pmp script can be controlled through [JSON-RPC link messages](https://github.com/annapuddles/jsonrpc-sl) from other scripts.

## JSON-RPC API

### `pmp:play (title, loop, volume)`

Play a song.

#### Parameters

- `title` The title of the song to play.
- `loop` Whether to loop the song or not.
- `volume` The volume to play the song at.

#### Example

```lsl
jsonrpc_link_notification(LINK_ROOT, "pmp:play", JSON_OBJECT, ["title", "My Song", "loop", FALSE, "volume", 1.0]);
```

### `pmp:stop ()`

Stop the currently playing song.

#### Example

```lsl
jsonrpc_link_notification(LINK_ROOT, "pmp:stop", JSON_OBJECT, []);
```

### `pmp:pause ()`

Pause the currently playing song.

#### Example

```lsl
jsonrpc_link_notification(LINK_ROOT, "pmp:pause", JSON_OBJECT, []);
```

### `pmp:resume ()`

Resume the currently paused song.

#### Example

```lsl
jsonrpc_link_notification(LINK_ROOT, "pmp:resume", JSON_OBJECT, []);
```

### `pmp:get-volume ()`

Get the current volume setting.

#### Example

```lsl
string request_id;

default
{
    state_entry()
    {
        request_id = jsonrpc_link_request(LINK_ROOT, "pmp:get-volume", JSON_OBJECT, []);
    }

    link_message(integer sender, integer num, string str, key id)
    {
        string jsonrpc_id = llJsonGetValue(str, ["id"]);

        if (jsonrpc_id == request_id)
        {
            llOwnerSay("Current volume: " + llJsonGetValue(str, ["result"]);
        }
    }
}
```

### `pmp:set-volume (volume)`

Set the volume of the currently playing song.

#### Parameters

- `volume` The new volume level.

#### Example

```lsl
jsonrpc_link_notification(LINK_ROOT, "pmp:set-volume", JSON_OBJECT, ["volume", .5]);
```

### `pmp:get-time ()`

Get the current playback time in seconds.

#### Example

```lsl
string request_id;

default
{
    state_entry()
    {
        request_id = jsonrpc_link_request(LINK_ROOT, "pmp:get-time", JSON_OBJECT, []);
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        jsonrpc_id = llJsonGetValue(str, ["id"]);
        
        if (jsonrpc_id == request_id)
        {
            llOwnerSay("Current time: " + llJsonGetValue(str, ["result"]) + " seconds");
        }
    }
}
```

### `pmp:set-time (time)`

Set the current playback time of the current song.

#### Parameters

- `time` The current time in seconds to play the song from.

#### Example

```lsl
jsonrpc_link_notification(LINK_ROOT, "pmp:set-time", JSON_OBJECT, ["time", 30.0]);
```

### `pmp:is-ready ()`

Check if the pmp script is fully initialized.

#### Example

```lsl
string request_id;

default
{
    state_entry()
    {
        request_id = jsonrpc_link_request(LINK_ROOT, "pmp:is-ready", JSON_OBJECT, []);
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        string jsonrpc_id = llJsonGetValue(str, ["id"]);
        
        if (jsonrpc_id == request_id)
        {
            integer is_ready = (integer) llJsonGetValue(str, ["result"]);
            
            if (is_ready)
            {
                llOwnerSay("The pmp script is ready");
            }
            else
            {
                llOwnerSay("THe pmp script is not yet ready");
            }
        }
    }
}
```

### `pmp:current-song ()`

Get the title of the currently playing song.

#### Example

```lsl
string request_id;

default
{
    state_entry()
    {
        request_id = jsonrpc_link_request(LINK_ROOT, "pmp:current-song", JSON_OBJECT, []);
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        string jsonrpc_id = llJsonGetValue(str, ["id"]);
        
        if (jsonrpc_id == request_id)
        {
            llOwnerSay("Current song: " + llJsonGetValue(str, ["result"]));
        }
    }
}
```

### `pmp:get-duration ()`

Get the duration in seconds of the currently playing song.

#### Example

```lsl
string request_id;

default
{
    state_entry()
    {
        request_id = jsonrpc_link_request(LINK_ROOT, "pmp:get-duration", JSON_OBJECT, []);
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        string jsonrpc_id = llJsonGetValue(str, ["id"]);
        
        if (jsonrpc_id == request_id)
        {
            llOwnerSay("Duration: " + llJsonGetValue(str, ["result"]);
        }
    }
}
```

### `pmp:get-progress ()`

Get the progress through the current song as a percentage.

#### Example

```lsl
string request_id;

default
{
    state_entry()
    {
        request_id = jsonrpc_link_request(LINK_ROOT, "pmp:get-progress", JSON_OBJECT, []);
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        string jsonrpc_id = llJsonGetValue(str, ["id"]);
        
        if (jsonrpc_id == request_id)
        {
            llOwnerSay("Song progress: " + llJsonGetValue(str, ["result"]));
        }
    }
}
```

### `pmp:is-paused ()`

Check if playback is currently paused or not.

#### Example

```lsl
string request_id;

default
{
    state_entry()
    {
        request_id = jsonrpc_link_request(LINK_ROOT, "pmp:is-paused", JSON_OBJECT, []);
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        string jsonrpc_id = llJsonGetValue(str, ["id"]);
        
        if (jsonrpc_id == request_id)
        {
            integer is_paused = (integer) llJsonGetValue(str, ["result"]);
            
            if (is_paused)
            {
                llOwnerSay("The song is paused.");
            }
            else
            {
                llOwnerSay("The song is playing.");
            }
        }
    }
}
```

## Helper functions
[script template.lsl](script%20template.lsl) contains helper functions for calling these methods.

### pmp_play

```lsl
pmp_play(integer link, string title, integer loop, float volume)
```

Play a song.

#### Parameters

- `link` The link number of the prim containing the pmp script.
- `title` The title of the song to play.
- `loop` Whether to loop the song or not.
- `volume` The volume to play the song at.

#### Example
```lsl
pmp_play(LINK_ROOT, "My Song", TRUE, 1);
```

### pmp_stop

```lsl
pmp_stop(integer link)
```

Stop the currently playing song.

#### Parameters

- `link` The link number of the prim containing the pmp script.

#### Example

```lsl
pmp_stop(LINK_ROOT);
```

### pmp_pause

```lsl
pmp_pause(integer link)
```

Pause the currently playing song.

#### Parameters

- `link` The link number of the prim containing the pmp script.

#### Example

```lsl
pmp_pause(LINK_ROOT);
```

### pmp_resume

```lsl
pmp_resume(integer link)
```

Resume the currently paused song.

#### Parameters

- `link` The link number of the prim containing the pmp script.

#### Example

```lsl
pmp_resume(LINK_ROOT);
```

### pmp_set_volume

```lsl
pmp_set_volume(integer link, float volume)
```

Set the volume of the currently playing song.

#### Parameters

- `link` The link number of the prim containing the pmp script.

#### Example

```lsl
pmp_set_volume(LINK_ROOT, .5);
```

### pmp_set_time

```lsl
pmp_set_time(integer link, float time)
```

Set the current time in seconds to play the current song from.

#### Parameters

- `link` The link number of the prim containing the pmp script.

#### Example

```lsl
pmp_set_time(LINK_ROOT, 30);
```
