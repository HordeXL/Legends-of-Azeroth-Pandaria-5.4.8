#include "ObjectGuid.h"
#include "CharacterPackets.h"
#include <array>
#include <cstdio>
#include <cstring>
#include <map>

// Normally supplied by worldserver's Main.cpp when linking the game library.
std::map<uint32, std::string> realmNameStore;

int main()
{
    // 5.4.8: little-endian reason followed by the MSB-first Instant bit.
    // Exercise the production serializer and ByteBuffer, not a test double.
    unsigned checked = 0;
    for (uint32 reason : { 0u, 1u, 2u, 3u, 0x12345678u })
        for (bool instant : { false, true })
        {
            WorldPackets::Character::LogoutResponse response;
            response.LogoutResult = reason;
            response.Instant = instant;
            WorldPacket const* packet = response.Write();
            std::array<uint8, 5> const expected = {
                uint8(reason), uint8(reason >> 8), uint8(reason >> 16),
                uint8(reason >> 24), uint8(instant ? 0x80 : 0x00)
            };
            if (packet->GetOpcode() != 0x008F || packet->size() != expected.size() ||
                std::memcmp(packet->contents(), expected.data(), expected.size()) != 0)
            {
                std::fprintf(stderr, "FAIL logout response reason=%u instant=%u\n", reason, instant);
                return 1;
            }
            ++checked;
        }
    std::printf("PASS %u logout response wire-format cases\n", checked);
    return 0;
}
