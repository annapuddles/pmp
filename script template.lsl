/* pmp link message codes */
integer PMP_STOP = 0;
integer PMP_PLAY = 1;
integer PMP_CURRENT_SONG = 2;
integer PMP_CURRENT_SONG_RESPONSE = 3;
integer PMP_PRELOAD = 4;
integer PMP_STARTUP_COMPLETE = 5;
integer PMP_READY = 6;
integer PMP_READY_RESPONSE = 7;
integer PMP_SONG_ENDED = 8;
integer PMP_SET_VOLUME = 9;
integer PMP_GET_VOLUME = 10;
integer PMP_GET_VOLUME_RESPONSE = 11;
integer PMP_GET_DURATION = 12;
integer PMP_GET_DURATION_RESPONSE = 13;
integer PMP_GET_TIME = 14;
integer PMP_GET_TIME_RESPONSE = 15;
integer PMP_SET_TIME = 16;
integer PMP_GET_PROGRESS = 17;
integer PMP_GET_PROGRESS_RESPONSE = 18;
integer PMP_SONG_STARTED = 19;
integer PMP_PAUSE = 20;
integer PMP_RESUME = 21;
integer PMP_PAUSED = 22;
integer PMP_PAUSED_RESPONSE = 23;

/* pmp helper functions */
pmp_play(integer link, string name, integer loop, float volume)
{
    llMessageLinked(link, PMP_PLAY, name + "|" + (string) loop + "|" + (string) volume, NULL_KEY);
}

pmp_stop(integer link)
{
    llMessageLinked(link, PMP_STOP, "", NULL_KEY);
}
 
pmp_pause(integer link)
{
    llMessageLinked(link, PMP_PAUSE, "", NULL_KEY);
}

pmp_resume(integer link)
{
    llMessageLinked(link, PMP_RESUME, "", NULL_KEY);
}
 
pmp_set_volume(integer link, float volume)
{
    llMessageLinked(link, PMP_SET_VOLUME, (string) volume, NULL_KEY);
}

pmp_set_time(integer link, float time)
{
    llMessageLinked(link, PMP_SET_TIME, (string) time, NULL_KEY);
}
