package demo.authz

default allow = false

# username and password database
user_passwords = {
    "alice": "password",
    "bob": "password"
}

allow = response {
    # check if password from header is same as in database for the specific user
    basic_auth.password == user_passwords[basic_auth.user_name]
    response := {
      "allowed": true,
      "headers": {"x-user": basic_auth.user_name}
    }
}

basic_auth := {"user_name": user_name, "password": password} {
    v := input.attributes.request.http.headers.authorization
    startswith(v, "Basic ")
    s := substring(v, count("Basic "), -1)
    [user_name, password] := split(base64url.decode(s), ":")
}
