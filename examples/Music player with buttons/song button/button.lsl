integer BUTTON_PRESSED = 12345;

default
{
    state_entry()
    {
        llSetText(llGetObjectName(), <1, 1, 1>, 1);
    }
    
    touch_start(integer total_number)
    {
        llMessageLinked(LINK_ROOT, BUTTON_PRESSED, llGetObjectName(), NULL_KEY);
    }
}

