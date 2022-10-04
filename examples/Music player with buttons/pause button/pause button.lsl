integer PMP_PAUSE = 20;
integer PMP_RESUME = 21;
integer PMP_PAUSED = 22;
integer PMP_PAUSED_RESPONSE = 23;

default
{
    state_entry()
    {
        llSetText("Pause", <1, 1, 1>, 1);
    }

    touch_start(integer total_number)
    {
        llMessageLinked(LINK_ROOT, PMP_PAUSED, "", NULL_KEY);
    }
    
    link_message(integer sender, integer command, string parameters, key id)
    {
        if (command == PMP_PAUSED_RESPONSE)
        {
            if (parameters == "1")
            {
                llMessageLinked(LINK_ROOT, PMP_RESUME, "", NULL_KEY);
            }
            else
            {
                llMessageLinked(LINK_ROOT, PMP_PAUSE, "", NULL_KEY);
            }
        }
    }
}

