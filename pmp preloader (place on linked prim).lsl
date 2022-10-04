integer PMP_PRELOAD = 4;

default
{
    link_message(integer sender, integer command, string parameters, key id)
    {
        if (command == PMP_PRELOAD && id != NULL_KEY)
        {
            llPlaySound(id, 0.0);
        }
    }
}
