FORUMS_URL <- "http://forums.electricimp.com";
TOKEN_STRING <- null;

// set to your username
USER <- "beardedinventor";

data <- server.load();
PW <- null;

// load password if applicable
if ("pw" in data) {
    PW = data.pw;  
    server.log("Loaded Password")
}

// gets posts
function getNewPosts(url, tokenString, cb) {
    local newComments = 0;
    local activeThreads = 0;
    
    local headers = { Cookie = tokenString };
    
    http.get(url, headers).sendasync(function(resp) {
        local totalNew = 0;
        if (resp.statuscode == 200) {
            local html = resp.body;
            local ex = regexp(@"<strong>\s*\d+\s*[nN]ew\s*</strong>");
            local r = ex.capture(html);
            while (r) {
                local count = strip(html.slice(r[0].begin+8, r[0].end-12)).tointeger();
                
                newComments += count;
                activeThreads++
                
                r = ex.capture(html, r[0].end);
            }
        }
        cb({ threads = activeThreads, comments= newComments });
    });
}

// sets user token
function login() {
    if (USER != null && PW != null) {
        local url = "https://ide.electricimp.com/account/login";
        local headers = { "Content-Type": "application/json" };
        local body = http.jsonencode({email=USER, password=PW});
        local resp = http.post(url, headers, body).sendsync(); 
    
        if ("set-cookie" in resp.headers) {
            return resp.headers["set-cookie"];
        }
    }
    return null;
}

function update(nullData = null) {
    local tokenString = login();
    if (tokenString != null) {
        getNewPosts(FORUMS_URL, tokenString, function(data) {
            server.log(format("%i comments in %i threads", data.comments, data.threads));
            device.send("forumCount", data.threads);
        });
    } else {
        server.log("Error - could not login");
    }
    
}

function pollForums() {
    imp.wakeup(60, pollForums);    // get new results every minute
    update();
} pollForums();

device.on("refresh", update);

http.onrequest(function(req, resp) {
    if ("pw" in req.query) {
        PW = req.query["pw"];
        server.log("Set Password");
        
        // save password
        local data = server.load();
        data["pw"] <- PW;
        server.save(data);
    }
    resp.send(200, "OK");
});

