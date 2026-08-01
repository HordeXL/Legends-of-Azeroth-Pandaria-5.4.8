-- Build 18414 spell 73159 directly uses SPELL_EFFECT_PLAY_MOVIE with movie
-- id 16. The core's native Spell::EffectPlayMovie handler already performs
-- the required SendMovieStart call. Remove only the obsolete 3.3.5 script
-- binding that expects SPELL_EFFECT_SCRIPT_EFFECT.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 73159
  AND `ScriptName` = 'spell_the_lich_king_play_movie';
