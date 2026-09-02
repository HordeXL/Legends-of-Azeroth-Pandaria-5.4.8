/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU GPL v2 license, you may redistribute it
 * and/or modify it under version 2 of the License, or (at your option), any later version.
 */

#include "Action.h"

#include "Playerbots.h"
#include "Timer.h"

uint32 NextAction::size(NextAction** actions)
{
    if (!actions)
        return 0;

    uint32 size = 0;
    for (size = 0; actions[size];)
        ++size;

    return size;
}

NextAction** NextAction::clone(NextAction** actions)
{
    if (!actions)
        return nullptr;

    uint32 size = NextAction::size(actions);

    NextAction** res = new NextAction*[size + 1];
    for (uint32 i = 0; i < size; i++)
        res[i] = new NextAction(*actions[i]);

    res[size] = nullptr;

    return res;
}

NextAction** NextAction::merge(NextAction** left, NextAction** right)
{
    uint32 leftSize = NextAction::size(left);
    uint32 rightSize = NextAction::size(right);

    NextAction** res = new NextAction*[leftSize + rightSize + 1];

    for (uint32 i = 0; i < leftSize; i++)
        res[i] = new NextAction(*left[i]);

    for (uint32 i = 0; i < rightSize; i++)
        res[leftSize + i] = new NextAction(*right[i]);

    res[leftSize + rightSize] = nullptr;

    NextAction::destroy(left);
    NextAction::destroy(right);

    return res;
}

NextAction** NextAction::array(uint32 nil, ...)
{
    va_list vl;
    va_start(vl, nil);

    uint32 size = 0;
    NextAction* cur = nullptr;
    do
    {
        cur = va_arg(vl, NextAction*);
        ++size;
    } while (cur);

    va_end(vl);

    NextAction** res = new NextAction*[size];
    va_start(vl, nil);
    for (uint32 i = 0; i < size; i++)
        res[i] = va_arg(vl, NextAction*);
    va_end(vl);

    return res;
}

void NextAction::destroy(NextAction** actions)
{
    if (!actions)
        return;

    for (uint32 i = 0; actions[i]; i++)
        delete actions[i];

    delete[] actions;
}

Value<Unit*>* Action::GetTargetValue() { return context->GetValue<Unit*>(GetTargetName()); }

Unit* Action::GetTarget()
{
    Value<Unit*>* targetValue = GetTargetValue();
    if (!targetValue)
    {
        if (!missingTargetValueLogged)
        {
            missingTargetValueLogged = true;
            std::string const targetName = GetTargetName();
            TC_LOG_ERROR("server",
                "Playerbot action requested an unsupported target value; action skipped bot=%s guid=%u class=%u specialization=%u action=%s target-value=%s map=%u position=(%.3f, %.3f, %.3f, %.3f)",
                bot ? bot->GetName().c_str() : "<none>",
                bot ? bot->GetGUID().GetCounter() : 0u,
                bot ? uint32(bot->GetClass()) : 0u,
                bot ? uint32(bot->GetSpecialization()) : 0u,
                getName().c_str(), targetName.c_str(),
                bot ? bot->GetMapId() : 0u,
                bot ? bot->GetPositionX() : 0.0f,
                bot ? bot->GetPositionY() : 0.0f,
                bot ? bot->GetPositionZ() : 0.0f,
                bot ? bot->GetOrientation() : 0.0f);
        }

        return nullptr;
    }

    return targetValue->Get();
}

ActionBasket::ActionBasket(ActionNode* action, float relevance, bool skipPrerequisites, Event event)
    : action(action), relevance(relevance), skipPrerequisites(skipPrerequisites), event(event), created(getMSTime())
{
}

bool ActionBasket::isExpired(uint32 msecs) { return getMSTime() - created >= msecs; }
