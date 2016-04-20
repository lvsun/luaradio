local block = require('radio.core.block')
local types = require('radio.types')
local blocks = require('radio.blocks')

local RDSReceiver = block.factory("RDSReceiver", blocks.CompositeBlock)

function RDSReceiver:instantiate(tau)
    blocks.CompositeBlock.instantiate(self)

    local fm_demod = blocks.FrequencyDiscriminatorBlock(5.0)
    local hilbert = blocks.HilbertTransformBlock(257)
    local mixer_delay = blocks.DelayBlock(193)
    local pilot_filter = blocks.ComplexBandpassFilterBlock(193, {18e3, 20e3})
    local pll_baseband = blocks.PLLBlock(1500.0, 19e3-100, 19e3+100, 3.0)
    local pll_bitclock = blocks.PLLBlock(1500.0, 19e3-100, 19e3+100, 1/16.0)
    local mixer = blocks.MultiplyConjugateBlock()
    local baseband_filter = blocks.LowpassFilterBlock(256, 4e3)
    local baseband_rrc = blocks.RootRaisedCosineFilterBlock(101, 1, 1187.5)
    local phase_corrector = blocks.BinaryPhaseCorrectorBlock(4000)
    local bitclock_complex_to_real = blocks.ComplexToRealBlock()
    local bitclock_delay = blocks.DelayBlock(357)
    local sampler = blocks.SamplerBlock()
    local bit_demod = blocks.ComplexToRealBlock()
    local bit_slicer = blocks.SlicerBlock()
    local bit_decoder = blocks.DifferentialDecoderBlock()
    local framer = blocks.RDSFrameBlock()

    self:connect(fm_demod, hilbert)
    self:connect(hilbert, mixer_delay)
    self:connect(hilbert, pilot_filter)
    self:connect(pilot_filter, pll_baseband)
    self:connect(pilot_filter, pll_bitclock)
    self:connect(mixer_delay, 'out', mixer, 'in1')
    self:connect(pll_baseband, 'out', mixer, 'in2')
    self:connect(mixer, baseband_filter, baseband_rrc, phase_corrector)
    self:connect(pll_bitclock, bitclock_complex_to_real, bitclock_delay)
    self:connect(phase_corrector, 'out', sampler, 'data')
    self:connect(bitclock_delay, 'out', sampler, 'clock')
    self:connect(sampler, bit_demod, bit_slicer, bit_decoder, framer)

    self:add_type_signature({block.Input("in", types.ComplexFloat32Type)}, {block.Output("out", blocks.RDSFrameBlock.RDSFrameType)})
    self:connect(self, "in", fm_demod, "in")
    self:connect(self, "out", framer, "out")
end

return RDSReceiver
