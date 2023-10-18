---
title: 创建应用程序和 API
weight: 11
---

在本部分中，你将创建一个名为 `bookinfo` 的应用程序并向其附加一个 API。API 将根据 OpenAPI 规范进行配置。

TSB 中的应用程序是服务的逻辑分组，这些服务公开了应用程序的不同功能和用例。它们属于租户，可用于观察服务的行为并配置如何使用这些服务及其 API。应用程序公开一组 API 对象，这些对象定义可用内容和使用条件。

![创建应用程序](../../assets/concepts/applications-services-api.svg)

## 先决条件

在继续阅读本指南之前，请确保你已完成以下步骤：

- 熟悉 TSB 概念
- 安装 TSB 演示环境
- 部署 Istio Bookinfo 示例应用程序
-  创建租户
-  创建工作区
-  配置权限
- 设置 Ingress 网关
- 检查服务拓扑和指标
- 配置流量转移
- 配置安全控制

## 创建应用程序

创建 `application.yaml` 文件：

```yaml
apiVersion: application.tsb.tetrate.io/v2
kind: Application
metadata:
  organization: tetrate
  tenant: tetrate
  name: bookinfo
spec:
  displayName: Bookinfo
  description: Bookinfo application
  workspace: organizations/tetrate/tenants/tetrate/workspaces/bookinfo-ws
  gatewayGroup: organizations/tetrate/tenants/tetrate/workspaces/bookinfo-ws/gatewaygroups/bookinfo-gw
```

使用 `tctl` 应用配置：

```bash
tctl apply -f application.yaml
```

上述步骤将创建 `bookinfo` 应用程序并将其链接到指定的工作区和网关组。

你可以通过以下方式验证应用程序的状态：

```bash
tctl x status application bookinfo --tenant tetrate -o yaml
```

## 附加 OpenAPI 规范

接下来，你将附加 OpenAPI 规范来配置应用程序的 Ingress Gateway。创建 `bookinfo-api.yaml` 文件：

<details>
<summary>bookinfo-api.yaml</summary>

```yaml
apiversion: application.tsb.tetrate.io/v2
kind: API
metadata:
  organization: tetrate
  tenant: tetrate
  application: bookinfo
  name: bookinfo
spec:
  displayName: Bookinfo API
  description: Bookinfo API
  workloadSelector:
    namespace: bookinfo
    labels:
      app: tsb-gateway-bookinfo
  openapi: |
    openapi: 3.0.0
    info:
      description: This is the API of the Istio BookInfo sample application.
      version: 1.0.0
      title: BookInfo API
      termsOfService: https://istio.io/
      license:
        name: Apache 2.0
        url: http://www.apache.org/licenses/LICENSE-2.0.html
      x-tsb-service: productpage.bookinfo
    servers:
      - url: http://bookinfo.tetrate.com/api/v1
    tags:
      - name: product
        description: Information about a product (in this case a book)
      - name: review
        description: Review information for a product
      - name: rating
        description: Rating information for a product
    externalDocs:
      description: Learn more about the Istio BookInfo application
      url: https://istio.io/docs/samples/bookinfo.html
    paths:
      /products:
        get:
          tags:
            - product
          summary: List all products
          description: List all products available in the application with a minimum amount of
            information.
          operationId: getProducts
          responses:
            "200":
              description: successful operation
              content:
                application/json:
                  schema:
                    type: array
                    items:
                      $ref: "#/components/schemas/Product"
      "/products/{id}":
        get:
          tags:
            - product
          summary: Get individual product
          description: Get detailed information about an individual product with the given id.
          operationId: getProduct
          parameters:
            - name: id
              in: path
              description: Product id
              required: true
              schema:
                type: integer
                format: int32
          responses:
            "200":
              description: successful operation
              content:
                application/json:
                  schema:
                    $ref: "#/components/schemas/ProductDetails"
            "400":
              description: Invalid product id
      "/products/{id}/reviews":
        get:
          tags:
            - review
          summary: Get reviews for a product
          description: Get reviews for a product, including review text and possibly ratings
            information.
          operationId: getProductReviews
          parameters:
            - name: id
              in: path
              description: Product id
              required: true
              schema:
                type: integer
                format: int32
          responses:
            "200":
              description: successful operation
              content:
                application/json:
                  schema:
                    $ref: "#/components/schemas/ProductReviews"
            "400":
              description: Invalid product id
      "/products/{id}/ratings":
        get:
          tags:
            - rating
          summary: Get ratings for a product
          description: Get ratings for a product, including stars and their color.
          operationId: getProductRatings
          parameters:
            - name: id
              in: path
              description: Product id
              required: true
              schema:
                type: integer
                format: int32
          responses:
            "200":
              description: successful operation
              content:
                application/json:
                  schema:
                    $ref: "#/components/schemas/ProductRatings"
            "400":
              description: Invalid product id
    components:
      schemas:
        Product:
          type: object
          description: Basic information about a product
          properties:
            id:
              type: integer
              format: int32
              description: Product id
            title:
              type: string
              description: Title of the book
            descriptionHtml:
              type: string
              description: Description of the book - may contain HTML tags
          required:
            - id
            - title
            - descriptionHtml
        ProductDetails:
          type: object
          description: Detailed information about a product
          properties:
            id:
              type: integer
              format: int32
              description: Product id
            publisher:
              type: string
              description: Publisher of the book
            language:
              type: string
              description: Language of the book
            author:
              type: string
              description: Author of the book
            ISBN-10:
              type: string
              description: ISBN-10 of the book
            ISBN-13:
              type: string
              description: ISBN-13 of the book
            year:
              type: integer
              format: int32
              description: Year the book was first published in
            type:
              type: string
              enum:
                - paperback
                - hardcover
              description: Type of the book
            pages:
              type: integer
              format: int32
              description: Number of pages of the book
          required:
            - id
            - publisher
            - language
            - author
            - ISBN-10
            - ISBN-13
            - year
            - type
            - pages
        ProductReviews:
          type: object
          description: Object containing reviews for a product
          properties:
            id:
              type: integer
              format: int32
              description: Product id
            reviews:
              type: array
              description: List of reviews
              items:
                $ref: "#/components/schemas/Review"
          required:
            - id
            - reviews
        Review:
          type: object
          description: Review of a product
          properties:
            reviewer:
              type: string
              description: Name of the reviewer
            text:
              type: string
              description: Review text
            rating:
              $ref: "#/components/schemas/Rating"
          required:
            - reviewer
            - text
        Rating:
          type: object
          description: Rating of a product
          properties:
            stars:
              type: integer
              format: int32
              minimum: 1
              maximum: 5
              description: Number of stars
            color:
              type: string
              enum:
                - red
                - black
              description: Color in which stars should be displayed
          required:
            - stars
            - color
        ProductRatings:
          type: object
          description: Object containing ratings of a product
          properties:
            id:
              type: integer
              format: int32
              description: Product id
            ratings:
              type: object
              description: A hashmap where keys are reviewer names, values are number of stars
              additionalProperties:
                type: string
          required:
            - id
            - ratings
```
</details>

使用 `tctl` 应用配置：

```bash
tctl apply -f bookinfo-api.yaml
```

Ingress Gateway 配置将根据 OpenAPI 规范生成。它将根据 OpenAPI 规范公开定义的端点。

验证已创建资源的状态：

```bash
tctl x status api bookinfo --application bookinfo --tenant tetrate -o yaml
```

## 测试

你可以通过 Ingress Gateway 向 API 公开的端点之一发出 HTTP 请求来测试配置。将 `<gateway-ip>` 替换为应用程序入口网关的实际 IP 地址或主机名。

```bash
export GATEWAY_IP=$(kubectl -n bookinfo get service tsb-gateway-bookinfo -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")
curl -v http://bookinfo.tetrate.com/api/v1/products \
     --connect-to "bookinfo.tetrate.com:80:$GATEWAY_IP"
```

这将通过 Ingress Gateway 向 Bookinfo 应用程序服务发送 HTTP 请求，允许你访问 API 公开的端点。

请记住将 `<gateway-ip>` 替换为 Ingress Gateway 的适当 IP 地址或主机名。
