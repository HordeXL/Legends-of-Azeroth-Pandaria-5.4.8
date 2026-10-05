#include <iostream>
#include <stdexcept>
enum { FORM_NONE, FORM_BEAR, FORM_CAT, FORM_MOONKIN, SPELL_AURA_MOD_SHAPESHIFT };
enum SpellCastResult { SPELL_CAST_OK, SPELL_FAILED_NOT_SHAPESHIFT, SPELL_FAILED_NO_POWER };
struct Event {};
struct Player
{
    int form = FORM_BEAR, removals = 0;
    bool enoughMana = true;
    int GetShapeshiftForm() const { return form; }
    void RemoveAurasByType(int) { form = FORM_NONE; ++removals; }
};
struct CastBuffSpellAction
{
    Player* bot;
    bool Execute(Event)
    {
        // Spell 24858's shipped DBC has SPELL_ATTR0_NOT_SHAPESHIFT.
        if (bot->form != FORM_NONE || !bot->enoughMana) return false;
        bot->form = FORM_MOONKIN;
        return true;
    }
};
struct CastMoonkinFormAction : CastBuffSpellAction { bool Execute(Event); };
#include "moonkin.inc"

struct Spell
{
    SpellCastResult preparationResult = SPELL_CAST_OK, laterResult = SPELL_CAST_OK;
    void prepare(int*) {}
    SpellCastResult GetCastResult() const { return preparationResult; }
    SpellCastResult CheckCast(bool) const { return laterResult; }
};
#define TC_LOG_DEBUG(...) ((void)0)
bool TryCast(Spell* spell)
{
    int targets = 0;
#include "cast_result.inc"
    return true;
}
void Require(bool value, char const* message)
{
    if (!value) throw std::runtime_error(message);
}
int main()
{
    try
    {
        for (int oldForm : {FORM_BEAR, FORM_CAT, FORM_NONE})
        {
            Player bot; bot.form = oldForm;
            CastMoonkinFormAction action; action.bot = &bot;
            Require(action.Execute({}), "Direct Moonkin cast must leave an incompatible form first");
            Require(bot.form == FORM_MOONKIN, "DPS must finish in Moonkin form");
        }
        Player bot; bot.enoughMana = false;
        CastMoonkinFormAction action; action.bot = &bot;
        Require(!action.Execute({}), "Insufficient mana must not report a successful action");
        Require(bot.form == FORM_NONE, "Canceling an old form must not require mana or a learned old spell");
        bot.form = FORM_MOONKIN; bot.removals = 0;
        action.Execute({});
        Require(bot.removals == 0, "An existing Moonkin form must not be canceled");
        Spell spell;
        Require(TryCast(&spell), "Valid cast rejected");
        spell.preparationResult = SPELL_FAILED_NOT_SHAPESHIFT;
        Require(!TryCast(&spell), "Non-strict check must not hide strict preparation rejection");
        spell.preparationResult = SPELL_FAILED_NO_POWER;
        Require(!TryCast(&spell), "Preparation failure must propagate");
        spell.preparationResult = SPELL_CAST_OK; spell.laterResult = SPELL_FAILED_NO_POWER;
        Require(!TryCast(&spell), "Existing post-prepare check must remain effective");
        std::cout << "PASS: Moonkin transitions and strict cast failure propagation\n";
    }
    catch (std::exception const& error)
    {
        std::cerr << error.what() << '\n'; return 1;
    }
}
