package metadata

components: close({
  #LogFields: [Name=string]: {
    description: string
    name: Name,
    relevant_when?: string
    required: bool
    type: {
      "string"?: {
        examples?: [string, ...string]
      }
      "timestamp"?: {
        examples: ["2020-11-01T21:15:47.443232Z"]
      }
    }
  }

  #MetricTags: [Name=string]: {
    description: string
    name: Name
  }

  #Options: [Name=string]: {
    description: string
    name: Name
    relevant_when?: string
    required: bool
    sort?: int8
    type: {
      "[string]"?: {
        if !required {
          default: [...string] | null
        }
        examples?: [...[...string]]
        templateable?: bool
      }
      "bool"?: {
        if !required {
          default: bool | null
        }
      }
      "object"?: {
        options: #Options | {}
      }
      "string"?: {
        if !required {
          default: string | null
        }
        enum?: [Name=_]: string
        examples?: [...string]
        templateable?: bool
      }
      "uint"?: {
        if !required {
          default: uint | null
        }
        examples?: [...uint],
        unit: "bytes" | "milliseconds" | "seconds"
      }
    }
  }

  #Components: [Name=string]: {
    description: string
    name: Name
    title: string
    type: "sink" | "source" | "transform"

    classes: {
      commonly_used: bool
      deployment_roles: ["daemon" | "service" | "sidecar", ...]
      function: string
      service_providers: [...string]
    }

    _features: [string]: bool

    requirements: [...string]

    statuses: {
      delivery: "at_least_once" | "best_effort"
      development: "beta" | "prod_ready"
    }

    support: {
      platforms: {
        "aarch64-unknown-linux-gnu": bool
        "aarch64-unknown-linux-musl": bool
        "x86_64-pc-windows-msv": bool
        "x86_64-unknown-linux-gnu": bool
        "x86_64-unknown-linux-musl": bool
      }
    }

    output: {
      log?: {
        fields: components.#LogFields
      }
      metric?: {
        tags: components.#MetricTags
      }
    }

    options: #Options & {
      "type": {
        description: "The component type. This is a required field for all components and tells Vector which component to use."
        required: true
        sort: -2
        "type": string: enum:
          "(Name)": "The type of this component."
      }
    }

    how_it_works: [...{
      title: string
      body: string
    }]
  }

  sources: #Components
  transforms: #Components
  sinks: #Components
})
