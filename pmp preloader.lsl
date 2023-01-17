default
{
    link_message(integer sender, integer num, string str, key id)
    {
        if (llJsonGetValue(str, ["method"]) == "pmp:preload")
        {
            key sound = (key) llJsonGetValue(str, ["params", "sound"]);
            
            if (sound != NULL_KEY)
            {
                llPreloadSound(sound);
            }
        }
    }
}
