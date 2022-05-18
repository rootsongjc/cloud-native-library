---
weight: 40
title: 实验16：使用 Lua 脚本扩展 Envoy
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将编写一个 Lua 脚本，为响应头添加一个头，并使用一个文件中定义的全局脚本。

我们将创建一个 Envoy 配置和一个 Lua 脚本，在响应句柄上添加一个头。由于我们不会使用请求路径，所以我们不需要定义 `envoy_on_request` 函数。响应函数看起来像这样。

```lua
function envoy_on_response(response_handle)
  response_handle:headers():add("hello", "world")
end
```

我们在从 `headers()` 函数返回的 `header` 对象上调用 `add(<header-name>, <header-value>)` 函数。

让我们在 Envoy 配置中内联定义这个脚本。为了简化配置，我们将使用 `direct_response`，而不是集群。

```yaml
static_resources:
  listeners:
  - name: main
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          route_config:
            name: some_route
            virtual_hosts:
            - name: some_service
              domains:
              - "*"
              routes:
              - match:
                  prefix: "/"
                direct_response:
                  status: 200
                  body:
                    inline_string: "200"
          http_filters:
          - name: envoy.filters.http.lua
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
              inline_code: |
                function envoy_on_response(response_handle)
                  response_handle:headers():add("hello", "world")
                end
          - name: envoy.filters.http.router
```

将上述 YAML 保存为 `8-lab-1-lua-script.yaml` 并运行它。

```sh
func-e run -c 8-Lab-1-lua-script.yaml &
```

为了测试这个功能，我们可以向 `localhost:10000` 发送一个请求，并检查响应头。

```sh
$ curl -v localhost:10000
...
> GET / HTTP/1.1
> Host: localhost:10000
> User-Agent: curl/7.64.0
> Accept: */*
>
< HTTP/1.1 200 OK
< content-length: 3
< content-type: text/plain
< hello: world
< date: Tue, 23 Nov 2021 21:37:01 GMT
< server: envoy
<
200
```

输出应该包括我们在其他标准头文件中添加的 `hello: world` header。

让我们来看看一个更复杂的情况。对于传入的请求，我们要检查它们是否有一个叫做 `my-request-id` 的头，如果这个头不存在，那么我们要为所有 GET 请求添加一个 `my-request-id` 头。

因为我们想在 `envoy_on_response` 函数中检查方法和一个头，我们将使用动态元数据在 `envoy_on_request` 函数中存储这些值。然后，在响应函数中，我们可以读取元数据，检查头是否被设置，方法是否为 GET，并添加 `my-request-id` 头。

下面是代码的样子。

```lua
function envoy_on_request(request_handle)
  local headers = request_handle:headers()
  local metadata = request_handle:streamInfo():dynamicMetadata()
  metadata:set("envoy.filters.http.lua", "requestInfo", {
      requestId = headers:get("my-request-id"),
      method = headers:get(":method"),
    })
end
function envoy_on_response(response_handle)
  local requestInfoObj = response_handle:streamInfo():dynamicMetadata():get("envoy.filters.http.lua")["requestInfo"]

  local requestId = requestInfoObj.requestId
  local method = requestInfoObj.method
  if (requestId == nil or requestId == '') and (method == 'GET') then
    response_handle:logInfo("Adding request ID header")
    response_handle:headers():add("my-request-id", "some_id_here")
  end
end
```

注意，目前我们使用 `some_id_here` 作为 `my-request-id的`值，以后我们会创建一个函数，为我们生成一个 ID。下面是完整的 Envoy 配置的样子。

```yaml
static_resources:
  listeners:
  - name: main
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          route_config:
            name: some_route
            virtual_hosts:
            - name: some_service
              domains:
              - "*"
              routes:
              - match:
                  prefix: "/"
                direct_response:
                  status: 200
                  body:
                    inline_string: "200"
          http_filters:
          - name: envoy.filters.http.lua
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
              inline_code: |
                function envoy_on_request(request_handle)
                  local headers = request_handle:headers()
                  local metadata = request_handle:streamInfo():dynamicMetadata()
                  metadata:set("envoy.filters.http.lua", "requestInfo", {
                      requestId = headers:get("my-request-id"),
                      method = headers:get(":method"),
                    })
                end
                function envoy_on_response(response_handle)
                  local requestInfoObj = response_handle:streamInfo():dynamicMetadata():get("envoy.filters.http.lua")["requestInfo"]

                  local requestId = requestInfoObj.requestId
                  local method = requestInfoObj.method
                  if (requestId == nil or requestId == '') and (method == 'GET') then
                    response_handle:logInfo("Adding request ID header")
                    response_handle:headers():add("my-request-id", "some_id_here")
                  end
                end
          - name: envoy.filters.http.router
```

将上述 YAML 保存为 `8-lab-1-lua-script-1.yaml` 并运行它。

```sh
func-e run -c 8-Lab-1-lua-script-1.yaml &
```

让我们试一试几种情况。首先，我们将发送一个没有设置 `my-request-id` 头的 GET 请求。

```sh
$ curl -v localhost:10000
...
[2021-11-23 22:59:35.932][2258][info][lua] [source/extensions/filters/http/lua/lua_filter.cc:795] script log: Adding request ID header
< HTTP/1.1 200 OK
< content-length: 3
< content-type: text/plain
< my-request-id: some_id_here
< date: Tue, 23 Nov 2021 22:59:35 GMT
< server: envoy
<
* Connection #0 to host localhost left intact
200
```

我们知道 Lua 代码运行了，因为我们看到了日志条目和 `my-request-id` 头的设置。

让我们试着发送一个 POST 请求。

```sh
$ curl -X POST -v localhost:10000
...
> POST / HTTP/1.1
> Host: localhost:10000
> User-Agent: curl/7.64.0
> Accept: */*
>
< HTTP/1.1 200 OK
< content-length: 3
< content-type: text/plain
< date: Mon, 29 Nov 2021 23:49:58 GMT
< server: envoy
```

注意到头信息中没有包括 `my-request-id` 头信息。最后，让我们也尝试发送一个 GET 请求，但也提供 `my-request-id` 头。在这种情况下，`my-request-id` 头信息也不应该被包含在响应中。

```sh
$ curl -v -H "my-request-id: something" localhost:10000
...
> GET / HTTP/1.1
> Host: localhost:10000
> User-Agent: curl/7.64.0
> Accept: */*
> my-request-id: something
>
< HTTP/1.1 200 OK
< content-length: 3
< content-type: text/plain
< date: Mon, 29 Nov 2021 23:51:57 GMT
< server: envoy
<
* Connection #0 to host localhost left intact
```

作为最后的练习，我们将创建一个单独的`.lua` 脚本，生成一个简单的随机字符串，可以用于请求 ID。我们将加载该脚本，然后在响应函数中调用它来获得请求 ID。

让我们创建一个 `library.lua` 文件，内容如下。

```lua
LIBRARY = {}

function LIBRARY.RandomString()
  local result = ""
  for i = 1, 24 do
    result = result .. string.char(math.random(97, 122))
  end
  return result
end

return LIBRARY
```

我们正在声明一个名为 `LIBRARY的`表和一个名为 `RandomString的`函数。

将上述 Lua 脚本保存为一个名为 `library.lua的`文件，并将其放在你的 Envoy 进程将要运行的同一个文件夹中。

> Luajit 运行时在进程的工作目录和 `/usr/local/share/lua/5.1` 文件夹中寻找 Lua 模块。

我们在 Envoy 配置中的现有代码将基本保持不变。我们只需要加载 `library.lua` 和调用 `RandomString` 函数。

这是更新后 Envoy 配置。

```yaml
static_resources:
  listeners:
  - name: main
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          route_config:
            name: some_route
            virtual_hosts:
            - name: some_service
              domains:
              - "*"
              routes:
              - match:
                  prefix: "/"
                direct_response:
                  status: 200
                  body:
                    inline_string: "200"
          http_filters:
          - name: envoy.filters.http.lua
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
              inline_code: |
                local library = require("library")
                function envoy_on_request(request_handle)
                  local headers = request_handle:headers()
                  local metadata = request_handle:streamInfo():dynamicMetadata()
                  metadata:set("envoy.filters.http.lua", "requestInfo", {
                      requestId = headers:get("my-request-id"),
                      method = headers:get(":method"),
                    })
                end
                function envoy_on_response(response_handle)
                  local requestInfoObj = response_handle:streamInfo():dynamicMetadata():get("envoy.filters.http.lua")["requestInfo"]

                  local requestId = requestInfoObj.requestId
                  local method = requestInfoObj.method
                  if (requestId == nil or requestId == '') and (method == 'GET') then
                    response_handle:logInfo("Adding request ID header")
                    response_handle:headers():add("my-request-id", library.RandomString())
                  end
                end
          - name: envoy.filters.http.router
```

将上述 YAML 保存为 `8-lab-1-lua-script-2.yaml`，然后用 `func-e` 运行它。

为了试用它，让我们向 `localhost:10000` 发送一个请求。

```sh
$ curl -v localhost:10000
...
[2021-11-23 23:14:18.206][2526][info][lua] [source/extensions/filters/http/lua/lua_filter.cc:795] script log: Adding request ID header
< HTTP/1.1 200 OK
< content-length: 3
< content-type: text/plain
< my-request-id: usptcritlocbzsezhjmroule
< date: Tue, 23 Nov 2021 23:14:18 GMT
< server: envoy
<
* Connection #0 to host localhost left intact
200
```

输出将包括 `my-request-id` 和我们生成的、从 `library.lua` 文件调用的随机字符串。

