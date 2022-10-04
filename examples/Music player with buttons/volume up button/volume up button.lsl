integer PMP_SET_VOLUME = 9;
integer PMP_GET_VOLUME = 10;
integer PMP_GET_VOLUME_RESPONSE = 11;

default
{
    state_entry()
    {
        llSetText("Vol +", <1, 1, 1>, 1);
    }
    
    touch_start(integer total_number)
    {
        llMessageLinked(LINK_ROOT, PMP_GET_VOLUME, "", NULL_KEY);
    }
    
    link_message(integer sender, integer command, string parameters, key id)
    {
        if (command == PMP_GET_VOLUME_RESPONSE)
        {
            llMessageLinked(LINK_ROOT, PMP_SET_VOLUME, (string) ((float) parameters + 0.1), NULL_KEY);
        }
    }
}

