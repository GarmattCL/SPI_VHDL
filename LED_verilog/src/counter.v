module led (
    input btn1,          // Eingangs-Taster
    output reg led       // Ausgang-LED
);

    reg btn1_prev;       // Register für den vorherigen Zustand des Tasters

    always @(posedge btn1 or negedge btn1) begin
        if (btn1 == 1'b0 && btn1_prev == 1'b1) begin
            led <= ~led;    // Toggle LED bei fallender Flanke des Taster
        end
        btn1_prev <= btn1;  // Update des vorherigen Tasterzustands
    end
endmodule