options indenting = 4
options no_unused_block_arguments = false
options no_unused_function_arguments = false

module opl3 shared private

require audio public

require dasbind


let OPL3_CHIP_SIZE = 20960

struct public Opl3Chip
    dummy : uint8[OPL3_CHIP_SIZE]

[extern(stdcall, name="OPL3_Reset", library="OPL3")]
def public OPL3_Reset(var chip : Opl3Chip; rate : uint)
    pass

[extern(stdcall, name="OPL3_WriteReg", library="OPL3")]
def public OPL3_WriteReg(var chip : Opl3Chip; reg : uint16; v : uint8)
    pass

[extern(stdcall, name="OPL3_WriteRegBuffered", library="OPL3")]
def public OPL3_WriteRegBuffered(var chip : Opl3Chip; reg : uint16; v : uint8)
    pass

[extern(stdcall, name="OPL3_Generate", library="OPL3")]
def public OPL3_Generate(var chip : Opl3Chip; buf : int16?)
    pass

[extern(stdcall, name="OPL3_GenerateResampled", library="OPL3")]
def public OPL3_GenerateResampled(var chip : Opl3Chip; buf : int16?)
    pass

[extern(stdcall, name="OPL3_GenerateStream", library="OPL3")]
def public OPL3_GenerateStream(var chip : Opl3Chip; sndptr : int16?; numsamples : uint)
    pass

[extern(stdcall, name="OPL3_Generate4Ch", library="OPL3")]
def public OPL3_Generate4Ch(var chip : Opl3Chip; buf4 : int16?)
    pass

[extern(stdcall, name="OPL3_Generate4ChResampled", library="OPL3")]
def public OPL3_Generate4ChResampled(var chip : Opl3Chip; buf4 : int16?)
    pass

[extern(stdcall, name="OPL3_Generate4ChStream", library="OPL3")]
def public OPL3_Generate4ChStream(var chip : Opl3Chip; sndptr1 : int16?; sndptr2 : int16?; numsamples : uint)
    pass

def public OPL3_WriteReg(var chip : Opl3Chip; reg : uint; v : uint8)
    OPL3_WriteReg(chip, uint16(reg), v)

def public OPL3_GenerateStreamMono(var chip : Opl3Chip; var samples : array<uint16>)
    let numsamples = length(samples)
    var temp : array<uint16>
    temp |> resize_no_init(numsamples * 2)
    unsafe
        OPL3_GenerateStream(chip, reinterpret<int16?> addr(temp[0]), uint(numsamples))
    for i in range(numsamples)
        samples[i] = temp[i * 2]
    delete temp

def public OPL3_GenerateStream(var chip : Opl3Chip; var samples : array<uint16>)
    let numsamples = length(samples)
    unsafe
        OPL3_GenerateStream(chip, reinterpret<int16?> addr(samples[0]), uint(numsamples / 2))
