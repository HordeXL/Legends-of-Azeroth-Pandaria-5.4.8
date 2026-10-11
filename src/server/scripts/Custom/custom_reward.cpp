#include "Chat.h"
#include "Config.h"

class Played_Time_Reward : public PlayerScript
{
public:
    Played_Time_Reward() : PlayerScript("Played_Time_Reward") { }
    uint32 timeInterval = 0;

    void OnUpdate(Player* player, uint32 diff)
    {
        timeInterval += diff;
        if (timeInterval >= player->ptr_Interval)
        {
            timeInterval -= player->ptr_Interval;
            if (player->IsInWorld() && sWorld->getBoolConfig(CONFIG_BONUS_TIME_REWARD))
            {
                ChatHandler(player->GetSession()).PSendSysMessage("\xe6\xb8\xb8\xe6\x88\x8f\xe6\x97\xb6\xe9\x95\xbf\xe5\xa5\x96\xe5\x8a\xb1\xe3\x80\x82");

                LoginDatabasePreparedStatement* stmt = LoginDatabase.GetPreparedStatement(LOGIN_UPD_BATTLEPAY_VP_COINS);
                stmt->setUInt32(0, sConfigMgr->GetIntDefault("PlayedTimeReward.vp", 0));
                stmt->setUInt32(1, player->GetSession()->GetAccountId());
                LoginDatabase.Query(stmt);                
            }
        }
    }
};

void AddSC_custom_reward()
{
	new Played_Time_Reward();
}
