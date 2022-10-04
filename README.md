# Adding pmp to an object

To add the Poodle Music Player (pmp) to an object:

1. Place the "pmp (poodle music player)" script, "pmp config" notecard, and any song notecards on to a prim.

2. Place the "pmp preloader" script on to a *different* prim than the "pmp (poodle music player)" script.

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

The pmp script can be controlled through link messages from other scripts. Link messages use the following format:

```lsl
llMessageLinked(link_number, command_code, parameters, NULL_KEY);
```

Where `link_number` is the link number of the prim containing the pmp script (or a special number like `LINK_SET`), `command_code` is one of the special command codes for pmp (`PMP_PLAY`, `PMP_STOP`, etc.), and `parameters` is a string containing any number of parameters to the command separated by the parameter separator (the default is `|`, but it can be configured in the configuration notecard with the `parameter_separator` setting).
