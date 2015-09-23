import vibe.d;
import std.string;
import std.regex;
import std.file;
import std.algorithm;
import bot.core;

/* Maximums need to be imposed:
    username - 9 chars
    channels - 50 chars
    message - 512 chars
*/

void eventLoop(Bot bot, Config config)
{
    bot.normalize();
    bool quit = false;

    Task reader;
    Task writer;
    Task worker;

    auto conn = connectTCP(bot.server, bot.port);

    reader = runTask({
        while (!quit && conn.connected) {
            auto message = (cast(string)conn.readLine(size_t.max, "\n"))
                .strip
                .escape;

            logInfo(message);

            if (!quit)
                worker.send(message);
        }
    });

    writer = runTask({
        while (!quit && conn.connected) {
            receive((string message) {
                logInfo("=> " ~ message);
                conn.write(message ~ "\n");
            });
        }
    });

    worker = runTask({
        writer.send("NICK %s".format(bot.nickname));
        writer.send("USER %s 0 * :%s".format(bot.username, bot.realname));
        writer.send("JOIN %s".format("##xampp"));

        while (!quit && conn.connected) {
            receive((string message) {
                string response = bot.getResponse(message);
                if (response.length)
                    writer.send(response);
            });
        }
    });

    writer.join();
    reader.join();
    worker.join();
    conn.close;
}

string escape(string str)
{
    string message;
    foreach (ch; str)
    {
        string character;
        switch(ch)
        {
            default:
                character ~= ch;
                break;
            case '%':
                character = "%%";
                break;
        }
        message ~= character;
    }

    return message;
}

Captures!string parseMessage(string message)
{
    auto ctr = ctRegex!(r"
            (?::
              (?P<prefix>
                (?P<servername>[\w](?:[\w-]*[\w])*(?:\.[\w][\w-]*[\w]*)*)
                |
                (?:
                  (?P<nickname>[a-z\[\]\\`_\^\{\|\}][\w\[\]\\`_\^\{\|\}-]*)
                  (?:
                    (?:!(?P<user>[^\s@]*)){0,1}@
                    (?P<host>
                      (?P<hostaddr>
                        (?P<ip4addr>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})
                        |
                        (?P<ip6addr>
                          (?:[a-f\d]{1,4}(?::[A-Fa-f\d]{1,4}){7})
                          |
                          (?:0:0:0:0:0:(?:0|FFFF)):
                          (?:\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})
                        )
                      )
                      |
                      (?P<hostname>[\w](?:[\w-]*[\w])*(?:\.[\w][\w-]*[\w]*)*)
                      |
                      (?P<hostcloak>[\S]*)
                    )
                  ){0,1}
                )
              )
              \s
            ){0,1}
            (?P<command>
              (?:\d{1,3})
              |
              (?:[a-z]*)
            )
            (?P<params>
              (?P<middle>
                (?:
                  \s
                  (?:[^\s:](?::|[^\s:])*)
                )*
              )
              (?:
                \s:
                (?P<trailing>
                  (?::|\s|[^\s:])*
                )
              ){0,1}
            )
        ", "ix");

    return matchFirst(message, ctr);
}

Captures!string parseParams(string params)
{
    auto ctr = ctRegex!(r"^
            (?P<target>
              (?P<nickname>[a-z\[\]\\`_\^\{\|\}][\w\[\]\\`_\^\{\|\}-]*)
              |
              (?P<servername>[\w](?:[\w-]*[\w])*(?:\.[\w][\w-]*[\w]*)*) 
            )
            |
            (?P<channel>
              [^\w^\s][\S]*
            )
        ", "ix");

    return matchFirst(params.strip, ctr);
}

void main()
{
    string configFile = readText("config.json");
    Json configJson = configFile.parseJson();
    
    Config config = deserializeJson!Config(configJson);
    Bot[] bots = deserializeJson!(Bot[])(configJson["profiles"]);
    
    foreach(ref bot; bots) {
        auto task = function (Bot bot, Config config) => {
            try eventLoop(bot, config);
            catch (Throwable error) {
                logError("Error message: %s", error.msg);
                logDiagnostic("Full error: %s", error);
            } finally exitEventLoop(true);
        };

        runTask(task(bot, config));
    }
    
    runEventLoop();
}

class Config {
}

struct Response {
    string command;
    string[] params;
    string trailing;
}

class Bot {
    string server;
    ushort port;
    string nickname;
    string prefix;

    @optional {
        string username;
        string realname;
        string[] channels;
        bool autojoin = false;
    }

    @ignore {
        Captures!string message;
        Captures!string params;
    }
    
    void normalize()
    {
        if (!username)
            username = nickname;

        if (!realname)
            realname = nickname;
    }

    string getResponse(string rawMessage)
    {
        message = parseMessage(rawMessage);
        params = parseParams(message["params"]);

        Response res;
        
        if (buildResponse(res))
            return "%s %-(%s %) %s".format(res.command, res.params, res.trailing);
        else
            return "";
    }

    private bool buildResponse(ref Response res)
    {  
        if (message["command"] == "PING")
            return handlePing(res);

        if (message["command"] == "PRIVMSG" && params["channel"])
            return handleChannel(res);

        if (message["command"] == "PRIVMSG" && params["nickname"] == nickname)
            return handlePrivate(res);

        return false;
    }

    private bool handlePing(ref Response res)
    {
        res.command = "PONG";
        res.params ~= message["params"].strip; 

        return true;
    }

    private bool handleChannel(ref Response res)
    {
        res.command = "PRIVMSG";
        res.params ~= params["channel"];
        immutable input = message["trailing"];

        if (input.startsWith(prefix))
            return handleCommand(res);

        if (input.startsWith(nickname))
            return handleBeckon(res);

        if (!find(input, nickname).empty)
            return handleReference(res);

        return false;
    }

    private bool handlePrivate(ref Response res)
    {
        return false;
    }

    private bool handleCommand(ref Response res)
    {
        res.trailing = ":Sorry, I don't understand commands yet.";
        return true;
    }   

    private bool handleBeckon(ref Response res)
    {
        res.trailing = ":Thanks for talking to me. I'll me more intelligent soon.";
        return true;
    }

    private bool handleReference(ref Response res)
    {
        res.trailing = ":Hey, don't leave me out of the conversation.";
        return true;
    }
}