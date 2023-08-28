---
title: Create Applications and APIs
description: Create an Application in TSB and expose services based on API definitions
weight: 11
---

In this section, you will create an [Application](../refs/tsb/application/v2/application) named `bookinfo` and attach an API to it. The API will be configured based on an [OpenAPI spec](https://www.openapis.org/).

Applications in TSB are logical groupings of services that expose different features and use cases for the application. They belong to a [Tenant](../refs/tsb/v2/tenant) and can be used to observe the behavior of services and configure how those services and their APIs can be consumed. Applications expose a set of [API](../refs/tsb/application/v2/api) objects that define what is available and the conditions for consumption.

![](../../assets/howto/applications-services-api.png)

### Prerequisites

Before you proceed with this guide, ensure you have completed the following steps:

- Familiarize yourself with [TSB concepts](../concepts/toc)
- Install the [TSB demo](../setup/self_managed/demo-installation) environment
- Deploy the [Istio Bookinfo](./deploy_sample_app) sample app
- Create a [Tenant](./tenant)
- Create a [Workspace](./workspace)
- Configure [Permissions](./permissions)
- Set up an [Ingress Gateway](./ingress_gateway)
- Check [service topology and metrics](./observability)
- Configure [Traffic Shifting](./traffic_shifting)
- Configure [Security Controls](./security)

### Creating the Application

Create the `application.yaml` file:

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

Apply the configuration using `tctl`:

```bash{promptUser: alice}
tctl apply -f application.yaml
```

The above steps will create the `bookinfo` Application and link it to the specified workspace and gateway group.

You can verify the application's status with:

```bash{promptUser: alice}
tctl x status application bookinfo --tenant tetrate -o yaml
```

### Attaching an OpenAPI Spec

Next, you'll attach an OpenAPI spec to configure the application's Ingress Gateway. Create the `bookinfo-api.yaml` file:

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

Apply the configuration using `tctl`:

```bash{promptUser: alice}
tctl apply -f bookinfo-api.yaml
```

The Ingress Gateway configuration will be generated based on the OpenAPI spec. It will expose the defined endpoints as per the OpenAPI spec.

To verify the status of the created resources:

```bash{promptUser: alice}
tctl x status api bookinfo --application bookinfo --tenant tetrate -o yaml
```

### Testing

You can test the configuration by making an HTTP request to one of the endpoints exposed by the API through the Ingress Gateway. Replace `<gateway-ip>` with the actual IP address or hostname of the Application Ingress Gateway.

```bash{promptUser: alice}
export GATEWAY_IP=$(kubectl -n bookinfo get service tsb-gateway-bookinfo -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")
curl -v http://bookinfo.tetrate.com/api/v1/products \
     --connect-to "bookinfo.tetrate.com:80:$GATEWAY_IP"
```

This will send an HTTP request to the Bookinfo application service through the Ingress Gateway, allowing you to access the endpoints exposed by the API.

Remember to replace `<gateway-ip>` with the appropriate IP address or hostname of your Ingress Gateway.
