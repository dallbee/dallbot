#!/usr/bin/rdmd

import std.regex;
import std.stdio;
import vibe.data.json;
import std.file; 

/*
void main()
{
    auto test = ":dallbee!~dallbee@corey.ch PRIVMSG ##cse-club :dallbot, hi";
    auto reg = ctRegex!(r"
        (?:(?P<protocol>\w*)\s){0,1}
        :(?P<source>[\S]*)
        (?:\s(?P<type>[\S]*)){0,1}
        (?:\s(?P<destination>[\S]*)){0,1}
        (?:\s(?P<channel>[^:][\S]*)){0,1}
        (?:\s:(?P<message>.*)){0,1}", "ix");
    auto m = match(test, reg);
    Captures!string cap = m.captures;

    writeln(
        "Protocol: " ~ cap["protocol"] ~ "\n" ~
        "Source: " ~ cap["source"] ~ "\n" ~
        "Type: " ~ cap["type"] ~ "\n" ~
        "Destination: " ~ cap["destination"] ~ "\n" ~
        "Channel: " ~ cap["channel"] ~ "\n" ~
        "Message: " ~ cap["message"]
    );

    writeln(cap["message"][0..6]);
}
*/



/*
class Settings {



    ushort serverPort = 10000;
    string databaseName = "datamancer";
    string databaseAddress = "127.0.0.1";
    string logFile = "tmp/log.txt";
    string secureKey = "ac7bdcaac51b0badd87cae9c2abd9fdb";
    string sessionCookie = "session_id";
    string serverString = "Not Available";
    bool useGzip = false;

    void parseSettings(Json json)
    {
        if (auto pv = "serverPort" in json)
            serverPort = cast(short)pv.get!long;
        if (auto pv = "databaseName" in json)
            databaseName = pv.get!string;
        if (auto pv = "databaseAddress" in json)
            databaseAddress = pv.get!string;
        if (auto pv = "logFile" in json)
           logFile = pv.get!string;
        if (auto pv = "secureKey" in json)
            secureKey = pv.get!string;
        if (auto pv = "sessionCookie" in json)
            sessionCookie = pv.get!string;
        if (auto pv = "serverString" in json)
            serverString = pv.get!string;
        if (auto pv = "useGzip" in json)
            useGzip = pv.get!bool;
        else
            throw new Exception("secureKey must be present in settings.json for proper operation");
    }
}*/