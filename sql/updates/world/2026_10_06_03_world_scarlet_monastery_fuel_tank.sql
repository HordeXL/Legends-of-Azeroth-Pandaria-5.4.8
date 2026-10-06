-- Fuel Tank's AI sets SPELLCLICK, but Player::CanSeeSpellClickOn also needs
-- the database binding. The tank casts its area explosion; the clicker gets
-- original-caster credit. The AI consumes the barrel without casting twice.
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`)
VALUES (59706, 114952, 0, 0)
ON DUPLICATE KEY UPDATE `cast_flags` = VALUES(`cast_flags`), `user_type` = VALUES(`user_type`);

-- OnSpellClick removes Fuel Barrel immediately. Check the clicked creature
-- (ConditionTarget 1) so subsequent clicks cannot queue another explosion.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 18 AND `SourceGroup` = 59706 AND `SourceEntry` = 114952;
INSERT INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
     `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`,
     `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
    (18, 59706, 114952, 0, 0, 1, 1, 114875, 0, 0, 0, 0, 0, '',
     'Fuel Tank: require the unconsumed Fuel Barrel aura on the clicked tank');
