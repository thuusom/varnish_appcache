vcl 4.0;
import std;

backend default {
    .host = "host.docker.internal";  # Nginx is running locally on the docker host
    .port = "9080";       # Nginx docker listens on port 9080
}

sub vcl_recv {
    std.log("vcl_recv " + req.url);

    if(req.url == "/unsecure.html"){ #unauthenticated events and uncached
        std.log("vcl_recv " + req.url + ". Unauth and uncached");
        return (pass);
    } else if(req.url == "/unsecure_cached.html"){ #unauthenticated events and cachable
        std.log("vcl_recv " + req.url + ". Unauth and cached");
        return (hash);
    }

    # Requests originating from outside (ei. not restarts)
    if (req.url == "/secure.html" || req.url=="/secure_cached.html") {

        if(req.restarts == 0) {
            std.log("Authentication needed "+req.url);

            #if (!req.http.x-client-certificate) {
                # No token, respond with 401 Unauthorized
                #return (synth(401, "Unauthorized"));
            #}

            # Set a custom header to indicate that an auth check is needed
            set req.http.X-Needs-Auth = "true"; #TODO: must be unset

            # Pass the request for initial processing, skipping the cache for auth
            std.log("vcl_recv "+req.url+" request auth");
            return (pass);
        } else {
            std.log("Authentication granted "+req.url);
            if(req.url == "/secure.html"){ #unauthenticated events and uncached
                std.log("vcl_recv " + req.url + ". Auth and uncached");
                return (pass);
            } else if(req.url == "/secure_cached.html"){ #unauthenticated events and cachable
                std.log("vcl_recv " + req.url + ". Auth and cached");
                return (hash);
            }
        }
    }

    return (pass);
}

sub vcl_hash {
    std.log("vcl_hash " + req.url);
}

sub vcl_backend_fetch {
    std.log("vcl_backend_fetch " +bereq.url);   
    # Perform the auth check if flagged

    if (bereq.http.X-Needs-Auth) {
        # Temporarily change the URL for authentication
        set bereq.http.X-Original-URL = bereq.url;  # Store original URL
        set bereq.url = "/authenticate.html";
    }
}

# Called after receiving response from the backend
sub vcl_backend_response {
    std.log("vcl_backend_response " +bereq.url);
    if (beresp.status == 200) {
        if (bereq.url == "/authenticate.html") {
            std.log("Authenticated, now requesting original url " + bereq.http.X-Original-URL);
        } else {
            std.log("Caching url " + bereq.url);
            set beresp.ttl = 20s;  # Cache for 1 hour
        }
    }
}

# Called before delivering the response to the client
sub vcl_deliver {
    std.log("vcl_deliver " +req.url);

    if (resp.status == 200 && req.restarts == 0 && req.http.X-Needs-Auth) {
        std.log("vcl_deliver " +req.url+ ". Authenticated, restarting with url " + req.url);

        unset req.http.X-Original-URL;  # Clean up
        unset req.http.X-Needs-Auth;    # Mark as authorized

        return (restart);

    } else {
        std.log("vcl_deliver " +req.url+ ". Delivering on url " + req.url);

        # Use 'resp.hits' instead of 'obj.hits' in Varnish 4.x and later
        if (obj.hits > 0) {
            set resp.http.X-Cache = "cached";
        } else {
            set resp.http.X-Cache = "uncached";
        }

        return (deliver);
    }
}