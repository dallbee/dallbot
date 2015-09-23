module bot.core;

import vibe.d;
import std.conv;
import core.sys.posix.unistd;
import core.sys.posix.pwd;

string getUser()
{
    // TODO: Check for failure
    auto pw = getpwuid(getuid());
    return pw.pw_name.to!string;
}