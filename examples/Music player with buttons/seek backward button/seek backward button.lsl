integer PMP_GET_TIME = 14;
integer PMP_GET_TIME_RESPONSE = 15;
integer PMP_SET_TIME = 16;

default
{
    state_entry()
    {
        llSetText("<< Seek", <1, 1, 1>, 1);
    }
    
    touch_start(integer total_number)
    {
        llMessageLinked(LINK_ROOT, PMP_GET_TIME, "", NULL_KEY);
    }
    
    link_message(integer sender, integer command, string parameters, key id)
    {
        if (command == PMP_GET_TIME_RESPONSE)
        {
            llMessageLinked(LINK_ROOT, PMP_SET_TIME, (string) ((float) parameters - 30), NULL_KEY);
        }
    }
}

