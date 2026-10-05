# Account appearance collection (5.4.8)

Talk to a transmogrifier, choose an equipped slot, and browse the collected
appearances. The wardrobe uses gossip pages of 18 appearances; it does not
require a client patch or pretend to provide the retail collection window.
Identical display IDs are shown once per slot, after compatibility filtering.

The NPC wardrobe uses English text and the client's standard gossip icons.
No embedded texture tags or oversized icons are sent, avoiding missing-texture
green squares. Item links keep their normal quality colors. The main menu
marks empty slots and transmogrified equipment. Each collection page shows
its slot and page number; clicking that heading refreshes the page.
Saved appearances are marked `[Current]`; pending choices are marked `[Preview]`.
Clicking an appearance updates the character's visible equipment temporarily.
Navigate Back to choose other slots, then use **Accept all changes** to commit
all choices, or **Cancel all changes** to restore committed equipment. Restoring
original appearances also previews first and requires Accept. An unchanged
appearance does not bind or charge. Saved outfits retain their explicit apply
confirmation; applying one cancels pending previews. Accept previews before
saving an outfit. This is the existing NPC window, with no addon/client changes.

Equipment appearances are learned automatically when real players receive or
equip items. Acquisition itself unlocks the appearance, including unbound
items; this is intentionally more permissive than a binding-based collection.
Selling, trading, disenchanting or deleting the source does not remove its
appearance. Other characters on the same account share the unlock immediately.
Socketless playerbots do not populate collections.
New appearances notify the receiving player in system chat with a clickable
item link: "[Item] has been added to your appearance collection." Repeated items and
previously collected visual appearances do not announce again, including on
another character on the account. Login/inventory imports are silent.

On first use after server startup, existing equipment, inventory, bank, Void
Storage and saved active transmog appearances across the account are imported.
Login also scans the actual loaded inventory to include unsaved items. Items
already deleted before this feature, without a surviving transmog record,
cannot be recovered. Mail, auctions and guild-bank contents are learned only
after the player receives them into personal inventory.

The collection supports all item qualities. Existing slot, armor/weapon,
class/race and other compatibility settings still apply. Nonvisual items such
as rings and trinkets are not collected. Applying appearances and saving sets
are free, with no gold or tokens required, even with old price configuration.
The native transmog handler is also free. Applying binds the equipped target and removes its refund
and trade eligibility. The source item is not needed. Presets also check
account ownership of their appearances.

## Installation

Apply `sql/updates/characters/2026_09_21_00_characters_transmog_collection.sql`
to the character database and
`sql/updates/world/2026_09_21_04_world_transmog_collection.sql` to the world
database before starting the new binary. Both migrations are repeatable.
The world migration adds the gossip collection to otherwise unscripted
transmogrifiers and preserves creatures with another assigned script.

Build and install worldserver, then restart the service. The persistent table
is `account_transmog_appearances`, keyed by account ID and source item entry.
Do not clear it when removing items or characters.

## Validation

`python3 contrib/transmog_collection/run_tests.py` compiles the production
collection, application and menu functions against an in-memory database and
item world. It checks import filtering, duplicate learning, sold sources,
restart persistence, account sharing/isolation, bot exclusion, rejected
applications without charges, successful charges and binding, pagination,
duplicate visuals, invalid slots and missing equipment.

The worldserver build checks real core integration. Live acceptance still
requires learning a drop, deleting it, relogging on another character on the
same account, applying it at the NPC and checking the visible result after
another relog. Automated tests do not run a WoW client or simulate MariaDB
worker failures.

## Server-only character preview

1. Press **C** yourself to open the character window.
2. Open the transmogrifier and choose **Head**, **Shoulders**, or another slot.
3. Click appearances to try them on; use **Back** to work on other slots.
4. Choose **Accept all changes** to save, or **Cancel all changes** to revert.

The server only changes visible player fields during preview. Item modifiers,
binding/refund/trade flags and saved transmog data change only on Accept.
Autosave reads committed appearances for the character-selection cache.
The preview is also visible to other players in the world. Head/cloak visibility
settings still apply. The server cannot open the C window itself.

All pending slots are canceled on equipment/permanent-appearance changes,
combat, death, leaving NPC interaction range, map changes, logout, or five
minutes after the last appearance choice. Closing the NPC window with X does
not send a server notification in this client; use Cancel for an immediate
revert, or walk away. No addon, chat-link preview or client patch is used.

Regression coverage includes multiple pending slots, no pre-Accept changes,
Cancel, original-appearance restore, full-outfit validation, equipment swaps,
interaction loss, timeout, and keeping previews out of the character cache.
The real client's model rendering still needs an in-game check after deployment.
