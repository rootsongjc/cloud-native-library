---
title: 利用 TSB 服务账号
description: 本文将重点介绍如何创建和使用 TSB 服务账号，以及如何利用 `tctl` 实用工具作为处理程序。
weight: 9
---

TSB 服务账号可以在平台内部用于管理集群入网 [tctl install cluster-service-account](../../setup/self-managed/onboarding-clusters#secrets) 和 [GitOps](../../howto/gitops) 功能，也可以在外部用于第三方系统执行各种 TSB 功能的配置，利用 TSB API 接口。本文将重点介绍如何创建和使用 TSB 服务账号，以及如何利用 `tctl` 实用工具作为处理程序。

## 使用 `tctl` 实用工具处理 TSB 服务账号

对于服务账号，你所需的大多数交互已经在 [tctl experimental service-account](../../reference/cli/reference/experimental#tctl-experimental-service-account) 命令中可用：

```bash
$ tctl x sa -h
Commands to manage TSB service accounts

Usage:
  tctl experimental service-account [command]

Aliases:
  service-account, sa

Available Commands:
  get         Get one or multiple service accounts
  create      Creates a new service account
  delete      Deletes a service account
  gen-key     Generate a new key pair for the given service account
  revoke-key  Revoke a given key pair for the given service account
  token       Generate a new token that can be used to authenticate to TSB
```

使用 `tctl experimental service-account create` 创建一个 TSB 服务账号。当创建服务账号时，会返回私钥，但 TSB 不会存储它们。客户端需要自行安全存储。要了解更多信息，请参阅 [YAML API 参考指南](../../refs/tsb/v2/team#serviceaccount)：

```bash
$ tctl experimental service-account create pipeline-sa1 > pipeline-sa1-jwk-private-key.jwk
$ cat pipeline-sa1-jwk-private-key.jwk
{
  "alg": "RS256",
  "d": "DXxlZZcNodMTZv0XIYXglgNilwyL4gxnmu6e1zZetmtbm0oHKUx4CTlnWt_nBAinlxTzirEXClBNoDPqCh27Jg-WwbBeW01l2RPoSO7g4eM9Sz1r2KCy5o7NgptAq-_uZLy609gWDPgk8EjFT1QWMtGVXICi5StR9D0RbKazFVpgekIBPAlKoMDqwMUVM5nldIXyI6iwy4C19ZAdf0cW2HHw8rKBEMQ-bqXuD7RVkMWp18wPrnxbMpR8Xw1n4F_Wj7DqAepYezk8Vp1-uuUEnIP3rtMYbFVL1wn-nupQSAyIQIQsqvwSsGU-RD00YuPQ6hbeRTb201Ev-DvFYA1XUQ",
  "dp": "lZdU20cP-G8q9dCEbFAYt15pVfzAfjy82cRlfGLjcYJFiTRyc-J8zj4VjDJSDg5CQfufQ_q_0duQi40HQH-8ihK1mPe-OZlvDc7syxbVlWIiwD4w1if-YuNWEvfyWOfa6nHsZY3utW5_SL4nvw2E-9iv_HJIJ3MkLEhZDysGvZE",
  "dq": "v--gNJHrSbUMgZEuy3jfjmrgHjBM3ee6141zL3KmfeWrEK6OW8TYrVV0HBzk7Whj7ehxQmLGHVH-MykyrlKGggGtnQ1OgUpTPBhKE8j5QaXmAuO7pY1oDcOWQmqg8qu1X0X61-LmMQ42he8gGSBvcL3jWxpDSGuGeYwPJeJ9FZc",
  "e": "AQAB",
  "kid": "zuAiwPFQu2eI3GAGddaS1UHG08A01BA4XStF2C45uiA",
  "kty": "RSA",
  "n": "s5ENuvPJ9C2gMsnqFUXosXYY4k8AcnCjfUFQgUJc1FBpM15EnrgwkArZNsgHscH7ngnqIvwIf7SvM10CSkKj7dWZ6oabmdY-IFaeKIZ96EoFicNpRgkhJQREunLNtwHjvZZ_j86Vbnt4YGn6Y09y42HlEAT2NjUBiZI9C_gUmWl7smW-gZBGa4U6PsAOpi0H6Ct5dKpYJUO0qj1JLqC739nG2Exr4QEQGkFo-UaBBTTq1miHXfs1ptytYqfd64xTg0PIX0-9CfjtKrXS3hWEAWHHcChl9eHp89RU7a3bjWHbVJJVjYwcht6kFR_GX6oScGGnM4vQSR2ifh034vSA3w",
  "p": "y4ynCbHHJW984_nC4UKCSF3kFjqAWG4E7K4_qJ7b5sXN7aQsWgBi6Jt6c9Paf4X3HUPDs9rbQ8ab4PJNP4r3JNc90wpvSR0b_w3E_bOtfQhbLbG5T17eO2laEpJCYWK71EVuZ2ykvuf6rkgTi4T27c9KdgJHMKQGNH7TwQFJKUU",
  "q": "4dZZugK6vTlt_i2ySEuvRTAErLAVK7UWIuLQN9ee

O8viX_vgoNe1L1rEN1Lb-OjdV4j5hyGMqkJ3kbCm0awDmxaR4nXVZ-GKC_mvilpfuyoYK4rm9iod_ZSuLytqr9LPnvtalaYeToNT9U7KqbzVsFY0nKTF6_ujRfqD8g282dM",
  "qi": "anAZOAEZNUHf9HjqVeZiMExSZf7_OhHDceyKQ3KKI7CZSHaSj-aRtXqfAzArwpi3jDkiVQK79pt5zYKg0K47Z-X2PJ_W1tqqzAQX3Fqkdvs1c3L3Fy3w_C59N_B_QiA5e-y9J5qM1Qk12jnhlCn0DnlolwadfrkciUIS4ZdHMcs"
}
```

当通过 TSB 服务账号创建步骤获取 JWK 私钥时，使用 `tctl experimental service-account token --key-path` 生成会话身份验证的访问令牌，并指定其持续时间：

```bash
$ tctl experimental service-account token pipeline-sa1 --key-path pipeline-sa1-jwk-private-key.jwk --expiration 1h30m0s
eyJhbGciOiJSUzI1NiIsImtpZCI6Inp1QWl3UEZRdTJlSTNHQUdkZGFTMVVIRzA4QTAxQkE0WFN0FjDdpUEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjE2NTcwNTIyNTksImlhdCI6MTY1NzA1MDQ1OSwic3ViIjoibXktc2EjenVBaXdQRlF1MmVJM0dBR2RkYVM1VUhHMDhBMDFCQTRYU3RGMkM0NXVpQSIsInRzYi50ZXRyYXRlLmlvL3VzZSI6InRjdGwifQ.PRN5noVwB5RT0kFL75XjBe8pO3l90QvqpeUrR-Cw_Wt3-I4jTEWOVZXwkg6BJp0sL3cdq4wBPOCjQ8FXKrd527bIujh8f0E0Cj0obhbbSGUmAFwJO2UrvovjfXr1Ra35KHsFY6HCnTjKRxFVZ_czdYAc4s3YbOYRhiz74v1O6U9nX5jgTLl_vg9dxDUxiYYeUn1gR9_Jf0APkM48JSiZa4Bz0Ly6oGKm_GkUY003xPl4PSMFhR-4i1rYrcFH2YYP_6uUieToTrCSNchPk8S6Mh3rnkMiKTazrUnAuO5Anc3C6UlbDw9-ax18dvyKKi47wdRcjeDNPxjCSX27Qe-ryA
```

然后将该令牌配置到所需的 [tctl 用户配置文件](../../setup/tctl-connect#set-tctls-user) 中。你也可以一次完成所有操作：

```
tctl config users set pipeline-sa1 --token $(tctl x sa token pipeline-sa1 --key-path pipeline-sa1-jwk-private-key.jwk --expiration 1h30m0s)
```

有关如何使用 `tctl` 连接到 TSB 的详细信息，请参阅 [使用 tctl 连接到 TSB](../../setup/tctl-connect#set-tctls-user)。