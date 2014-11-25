FORUMS_URL <- "http://forums.electricimp.com";
TOKEN_STRING <- null;

// username and password (set through http request to agent)
USER <- null;
PW <- null;

data <- server.load();

// load username / password
if ("pw" in data) {
    PW = data.pw;  
    server.log("Loaded Password")
} else {
	data["pw"] <- null;
	server.save(data);
}

if ("user" in data) {
    USER = data.user;
    server.log("Loaded User")
} else {
	data["user"] <- null;
	server.save(data);
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
        local url = "https://api.electricimp.com/account/login";
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
    local path = req.path.tolower();
	if (path == "/login" || path == "/login/") {
	    if ("pw" in req.query) {
    	    PW = req.query["pw"];
        	server.log("Set Password");
	    }
    	if ("user" in req.query) {
        	USER = req.query["user"];
	        server.log("Set User");
    	}
		data.user = USER;
		data.pw = PW;
		server.save(data);
	}
	resp.send(200, "OK");
});

