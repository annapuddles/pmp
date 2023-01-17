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

The name of the notecard is the name you use to start the song, for example when using the `PMP_PLAY` command:

```lsl
llMessageLinked(LINK_ROOT, PMP_PLAY, "Song name", NULL_KEY);
```

# Interacting with pmp

The pmp script can be controlled through JSON-RPC link messages from other scripts.

## pmp:play (title, loop, volume)

Play a song.

### Parameters

- `title` The title of the song to play.
- `loop` Whether to loop the song or not.
- `volume` The volume to play the song at.

### Example
```lsl
string params = llList2Json(JSON_OBJECT, [
    "title", "My Song",
    "loop", 1,
    "volume", "50"
];

string message = llList2Json(JSON_OBJECT, [
    "method", "pmp:play",
    "params", params
]);

llMessageLinked(LINK_ROOT, 0, message, NULL_KEY);
```

## pmp:stop ()

Stop the currently playing song.

### Example

```lsl
string message = llList2Json(JSON_OBJECT, ["method", "pmp:stop"]);

llMessageLinked(LINK_ROOT, 0, message, NULL_KEY);
```
