// =================================================================
// Module: sm2tc  (sign-magnitude -> two's-complement converter)
// Description: mult3x3.v and mult4x2.v both produce a registered
//              SIGN-MAGNITUDE result: bit[WIDTH-1] = sign,
//              bit[WIDTH-2:0] = magnitude.
//
//              Every later stage in the channel (the next multiplier
//              stage, accumulator_1ms) treats its "signed" inputs as
//              standard two's-complement, per normal Verilog `signed`
//              semantics. Feeding a sign-magnitude value straight into
//              a two's-complement port gives WRONG results for any
//              negative sample, so this tiny combinational converter
//              sits between every multiplier stage and whatever
//              consumes its output.
// =================================================================
module sm2tc #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0]        sm,  // sign-magnitude in  (sm[WIDTH-1]=sign)
    output wire signed [WIDTH-1:0] tc   // two's-complement out
);

    assign tc = sm[WIDTH-1] ? -{1'b0, sm[WIDTH-2:0]} : {1'b0, sm[WIDTH-2:0]};

endmodule
