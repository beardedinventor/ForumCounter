// 250mA dial - controlled with 5V and a FET
dial <- hardware.pin5;
dial.configure(PWM_OUT, 1.0/250.0, 0.0);

// A button the front of the box refreshes the counter
frontSwitch <- hardware.pin1;
switchState <- null;

// Experimentally determined value for min/max write values
// for the 250mA dial
min <- 0.0041;
max <- 0.054;

steps <- 10;

function writeMeter(x) {
    dial.write((max-min) / steps * x + min);
}

frontSwitch.configure(DIGITAL_IN_PULLUP,function() {
    // software debounce
    imp.sleep(0.02);    
    local state = frontSwitch.read();
    if (state == switchState) return;
    switchState = state;
    if (state == 1) {
        writeMeter(0);
        return;
    }
    
    agent.send("refresh", null);
});

agent.on("forumCount", function(count) {
    if (count > 10) count = 10;
    writeMeter(count);
})