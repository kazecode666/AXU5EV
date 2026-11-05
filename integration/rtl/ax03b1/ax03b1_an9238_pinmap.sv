// Logical header adapter only. No PACKAGE_PIN, I/O standard or clock-edge claim.
// AN9238_UG Rev1.0 PDF p9-10; CH1 is A, CH2 is B.
module ax03b1_an9238_pinmap (
    input  wire [40:1] header_i,
    output wire [11:0] raw_a,
    output wire [11:0] raw_b,
    output wire otr_a,
    output wire otr_b
);
    assign raw_a = {header_i[29], header_i[30], header_i[27], header_i[28],
                    header_i[25], header_i[26], header_i[23], header_i[24],
                    header_i[21], header_i[22], header_i[19], header_i[20]};
    assign raw_b = {header_i[15], header_i[14], header_i[13], header_i[12],
                    header_i[11], header_i[10], header_i[9], header_i[8],
                    header_i[7], header_i[6], header_i[5], header_i[4]};
    assign otr_a = header_i[32];
    assign otr_b = header_i[16];
endmodule
