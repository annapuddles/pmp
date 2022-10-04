integer PMP_STOP = 0;
integer PMP_PLAY = 1;
integer PMP_CURRENT_SONG = 2;
integer PMP_CURRENT_SONG_RESPONSE = 3;
integer PMP_PRELOAD = 4;
integer PMP_STARTUP_COMPLETE = 5;
integer PMP_READY = 6;
integer PMP_READY_RESPONSE = 7;
integer PMP_SONG_ENDED = 8;

integer BUTTON_PRESSED = 12345;

string song;

default
{
    link_message(integer sender, integer command, string parameters, key id)
    {
        if (command == BUTTON_PRESSED)
        {
            song = parameters;
            llMessageLinked(LINK_THIS, PMP_CURRENT_SONG, "", NULL_KEY);
        }
        else if (command == PMP_CURRENT_SONG_RESPONSE)
        {
            if (parameters == song)
            {
                llMessageLinked(LINK_THIS, PMP_STOP, "", NULL_KEY);
            }
            else
            {
                llMessageLinked(LINK_THIS, PMP_PLAY, song, NULL_KEY);
            }
        }
    }
}

