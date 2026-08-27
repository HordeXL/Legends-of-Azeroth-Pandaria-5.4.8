/*
* This file is part of the Pandaria 5.4.8 Project. See THANKS file for Copyright information
*
* This program is free software; you can redistribute it and/or modify it
* under the terms of the GNU General Public License as published by the
* Free Software Foundation; either version 2 of the License, or (at your
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
* more details.
*
* You should have received a copy of the GNU General Public License along
* with this program. If not, see <http://www.gnu.org/licenses/>.
*/

/* ScriptData
SDName: Westfall
SD%Complete: 0
SDComment:
SDCategory: Westfall
EndScriptData */

/* ContentData
EndContentData */

// Wake Harvest Golem 79436
class spell_westfall_wake_harvest_golem : public SpellScript
{
    PrepareSpellScript(spell_westfall_wake_harvest_golem);

    void HandleHit(SpellEffIndex effIndex)
    {
        if (Player* caster = GetCaster()->ToPlayer())
            caster->KilledMonsterCredit(GetSpellInfo()->Effects[EFFECT_1].MiscValue);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_westfall_wake_harvest_golem::HandleHit, EFFECT_0, SPELL_EFFECT_SCRIPT_EFFECT);
    }
};

// Quest 26228 - Livin' the Life
// The credit spell removes the player from Lou's house vehicle. Without this
// script the event can finish while leaving the player attached to the house.
class spell_westfall_quest_credit_jangolode_event : public SpellScript
{
    PrepareSpellScript(spell_westfall_quest_credit_jangolode_event);

    void HandleScriptEffect(SpellEffIndex /*effIndex*/)
    {
        if (Unit* target = GetHitUnit())
            target->ExitVehicle();
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_westfall_quest_credit_jangolode_event::HandleScriptEffect, EFFECT_1, SPELL_EFFECT_SCRIPT_EFFECT);
    }
};

void AddSC_westfall()
{
    new spell_script<spell_westfall_wake_harvest_golem>("spell_westfall_wake_harvest_golem");
    new spell_script<spell_westfall_quest_credit_jangolode_event>("spell_westfall_quest_credit_jangolode_event");
}
