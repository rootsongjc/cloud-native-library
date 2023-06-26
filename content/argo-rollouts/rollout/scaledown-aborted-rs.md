---
weight: 7
title: "Rollout 失败时缩小新的 ReplicaSet"
linkTitle: "缩小失败的 Rollout"
date: '2023-06-21T16:00:00+08:00'
type: book
---

在回滚更新时，我们可能会为所有策略缩小新的副本集。用户可以通过将 `abortScaleDownDelaySeconds` 设置为 0 来选择永久保留新的副本集，或者将该值调整为更大或更小的值。

下表总结了在 Rollout 策略和 `abortScaleDownDelaySeconds` 的组合下的行为。请注意，`abortScaleDownDelaySeconds` 不适用于 argo-rollouts v1.0。 `abortScaleDownDelaySeconds = nil` 是默认值，这意味着在 v1.1 中，对于所有 Rollout 策略，默认情况下在 Rollout 后 30 秒内缩小新的副本集。

| 策略                                | v1.0 行为      | abortScaleDownDelaySeconds | v1.1 行为                     |
| ----------------------------------- | -------------- | -------------------------- | ---------------------------- |
| 蓝绿部署                            | 不缩小         | nil                        | 回滚后 30 秒内缩小           |
| 蓝绿部署                            | 不缩小         | 0                          | 不缩小                       |
| 蓝绿部署                            | 不缩小         | N                          | 回滚后 N 秒内缩小            |
| 基本金丝雀                          | 回滚到稳定状态 | N/A                        | 回滚到稳定状态               |
| 带流量路由的金丝雀                  | 立即缩小       | nil                        | 回滚后 30 秒内缩小           |
| 带流量路由的金丝雀                  | 立即缩小       | 0                          | 不缩小                       |
| 带流量路由的金丝雀                  | 立即缩小       | N                          | 回滚后 N 秒内缩小            |
| 带流量路由的金丝雀 + setCanaryScale | 不缩小 (bug)   | *                          | 应该像带流量路由的金丝雀一样 |
