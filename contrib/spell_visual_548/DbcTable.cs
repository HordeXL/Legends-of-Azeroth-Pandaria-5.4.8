using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

// Read-only audit helper for the fixed-width WDBC/WDB2 extracts used by this core.
public sealed class VisualAuditDbc
{
    public readonly Dictionary<uint, uint[]> Rows = new Dictionary<uint, uint[]>();
    public readonly int Fields;
    private readonly byte[] data;
    private readonly int strings;
    public VisualAuditDbc(string path)
    {
        data = File.ReadAllBytes(path);
        if (data.Length < 20)
            throw new InvalidDataException("Missing table header: " + path);
        string signature = Encoding.ASCII.GetString(data, 0, 4);
        int header = 20;
        if (signature == "WDB2")
        {
            if (data.Length < 48 || BitConverter.ToUInt32(data, 24) <= 12880)
                throw new InvalidDataException("Unsupported WDB2 version: " + path);
            header = 48;
            uint min = BitConverter.ToUInt32(data, 32), max = BitConverter.ToUInt32(data, 36);
            if (max != 0) header = checked(header + (int)(max - min + 1) * 6);
            if (BitConverter.ToUInt32(data, 44) != 0)
                throw new InvalidDataException("WDB2 copy table not supported: " + path);
        }
        else if (signature != "WDBC")
            throw new InvalidDataException("Expected WDBC/WDB2: " + path);
        int count = checked((int)BitConverter.ToUInt32(data, 4));
        int size = checked((int)BitConverter.ToUInt32(data, 12));
        Fields = size / 4; // EffectName packs its four byte fields into one word.
        strings = checked(header + count * size);
        if (size % 4 != 0 || (long)strings + BitConverter.ToUInt32(data, 16) > data.Length)
            throw new InvalidDataException("Unexpected DBC record layout: " + path);
        for (int i = 0; i < count; ++i)
        {
            uint[] row = new uint[Fields];
            Buffer.BlockCopy(data, header + i * size, row, 0, size);
            Rows.Add(row[0], row);
        }
    }
    public string Text(uint offset)
    {
        int start = checked(strings + (int)offset), end = start;
        if (start < strings || start >= data.Length)
            throw new InvalidDataException("Invalid DBC string offset");
        while (end < data.Length && data[end] != 0) ++end;
        return Encoding.UTF8.GetString(data, start, end - start);
    }
}
