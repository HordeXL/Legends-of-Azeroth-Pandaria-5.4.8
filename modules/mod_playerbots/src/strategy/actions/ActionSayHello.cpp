#include "ActionSayHello.h"

#include "PlayerbotAI.h"
#include "PlayerbotAIConfig.h"
#include "Player.h"
#include "Log.h"

SayHelloAction::SayHelloAction(PlayerbotAI* ai)
    : Action(ai, "say hello")
{
}

bool SayHelloAction::Execute(Event event)
{
    // Greeting is opt-in via AiPlayerbot.EnableGreet
    if (!sPlayerbotAIConfig->enableGreet)
        return false;

    if (sPlayerbotAIConfig->enableBroadcasts && sPlayerbotAIConfig->randomBotTalk)
    {
        // Prefer a random greet text from ai_playerbot_texts when available.
        if (botAI->Talk("greet"))
            return true;
    }

    botAI->GetBot()->Say("Hello !", Language::LANG_UNIVERSAL);
    return true;
}