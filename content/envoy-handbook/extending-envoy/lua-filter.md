---
weight: 20
title: Lua 过滤器
date: '2022-05-18T00:00:00+08:00'
type: book
---

Envoy 具有一个内置的 HTTP Lua 过滤器，允许在请求和响应流中运行 Lua 脚本。Lua 是一种可嵌入的脚本语言，主要在嵌入式系统和游戏中流行。Envoy 使用 [LuaJIT](https://luajit.org/)（Lua 的即时编译器）作为运行时。LuaJIT 支持的最高 Lua 脚本版本是 5.1，其中一些功能来自 5.2。

在运行时，Envoy 为每个工作线程创建一个 Lua 环境。正因为如此，没有真正意义上的全局数据。任何在加载时创建和填充的全局数据都可以从每个独立的工作线程中看到。

Lua 脚本是以同步风格的 coroutines 运行的，即使它们可能执行复杂的异步任务。这使得它更容易编写。Envoy 通过一组 API 执行所有的网络 / 异步处理。当一个异步任务被调用时，Envoy 会暂停脚本的执行，等到异步操作完成就会恢复。

我们不应该从脚本中执行任何阻塞性操作，因为这会影响 Envoy 的性能。我们应该只使用 Envoy 的 API 来进行所有的 IO 操作。

我们可以使用 Lua 脚本修改和 / 或检查请求和响应头、正文和 Trailer。我们还可以对上游主机进行出站异步 HTTP 调用，或者执行直接响应，跳过任何进一步的过滤器迭代。例如，在 Lua 脚本中，我们可以进行上游的 HTTP 调用并直接响应，而不继续执行其他过滤器。

## 如何配置 Lua 过滤器

Lua 脚本可以使用 `inline_code` 字段进行内联定义，或者使用过滤器上的 `source_codes` 字段引用本地文件。

```yaml
name: envoy.filters.http.lua
typed_config:
  "@type": type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
  inline_code: |
    -- Called on the request path.
    function envoy_on_request(request_handle)
      -- Do something.
    end
    -- Called on the response path.
    function envoy_on_response(response_handle)
      -- Do something.
    end
  source_codes:
    myscript.lua:
      filename: /scripts/myscript.lua
```

Envoy 将上述脚本视为全局脚本，对每一个 HTTP 请求都会执行它。在每个脚本中可以定义两个全局函数。

```lua
function envoy_on_request(request_handle)
end
```

和

```lua
function envoy_on_response(response_handle)
end
```

`envoy_on_request` 函数在请求路径上被调用，而 `envoy_on_response` 脚本则在响应路径上被调用。每个函数都接收一个句柄，该句柄有不同的定义方法。脚本可以包含响应或请求函数，也可以包含两者。

我们也有一个选项，可以在虚拟主机、路由或加权集群级别上按路由禁用或改写脚本。

使用 `typed_per_filter_config` 字段来禁用或引用主机、路由或加权集群层面上的现有 Lua 脚本。例如，下面是如何使用 `typed_per_filter_config` 来引用一个现有的脚本（例如：`some-script.lua`）。

```yaml
typed_per_filter_config:
  envoy.filters.http.lua。
    "@type": type.googleapis.com/envoy.extensions. filters.http.lua.v3.LuaPerRoute
    name: some-script.lua
```

同样地，我们可以这样定义 `source_code` 和 `inline_string` 字段，而不是指定 `name` 字段。

```yaml
typed_per_filter_config:
  envoy.filters.http.lua:
    "@type": type.googleapis.com/envoy.extensions.filters.http.lua.v3.LuaPerRoute
    source_code:
      inline_string: |
        function envoy_on_response(response_handle)
          -- Do something on response.
        end
```

## 流处理 API

我们在前面提到，`request_handle` 和 `response_handle` 流句柄会被传递给全局 request 和 response 函数。

在流句柄上可用的方法包括 `headers`、`body`、`metadata`、各种日志方法（如 `logTrace`、`logInfo`、`logDebug`...）、`httpCall`、`connection`等等。你可以在 [Lua 过滤器源码](https://github.com/envoyproxy/envoy/blob/d79a3ab49f1aa522d0a465385425e3e00c8db147/source/extensions/filters/http/lua/lua_filter.h#L151)中找到完整的方法列表。

除了流对象外，API 还支持以下对象：

- [Header 对象](https://github.com/envoyproxy/envoy/blob/55fc06b43082064cf7551d8dbc08a0e30e2c2f40/source/extensions/filters/http/lua/wrappers.h#L46)（由 `headers()` 方法返回）
- 缓冲区对象（由 `body()` 方法返回）。
- [动态元数据对象](https://github.com/envoyproxy/envoy/blob/55fc06b43082064cf7551d8dbc08a0e30e2c2f40/source/extensions/filters/http/lua/wrappers.h#L151)（由 `metadata()` 方法返回）
- [Stream 信息对象](https://github.com/envoyproxy/envoy/blob/55fc06b43082064cf7551d8dbc08a0e30e2c2f40/source/extensions/filters/http/lua/wrappers.h#L199)（由 `streamInfo()` 方法返回）
- 连接对象（通过 `connection()` 方法返回）
- [SSL 连接信息对象](https://github.com/envoyproxy/envoy/blob/0fae6970ddaf93f024908ba304bbd2b34e997a51/source/extensions/filters/common/lua/wrappers.h#L124)（由连接对象的 `ssl()` 方法返回）

你会在那里看到如何使用 Lua 实验中的一些对象和方法。