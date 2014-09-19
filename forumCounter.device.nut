dial <- hardware.pin5;
dial.configure(PWM_OUT, 1.0/100.0, 0.0);

frontSwitch <- hardware.pin1;
switchState <- null;
frontSwitch.configure(DIGITAL_IN_PULLUP,function() {
    // software debounce
    imp.sleep(0.02);    
    local state = hardware.pin1.read();
    if (state == switchState) return;
    switchState = state;
    if (state == 1) return;
    
    agent.send("refresh", null);
});

min <- 0.0041;
max <- 0.054;

steps <- 10;

current <- 0;
direction <- 1;

function writeMeter(x) {
    hardware.pin5.write((max-min) / steps * x + min);
}

agent.on("forumCount", function(count) {
    if (count > 10) count = 10;
    writeMeter(count);
})

