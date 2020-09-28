package metadata

import (
  "strings"
)

components: sources: http: {
  title: "HTTP"
  description: strings.ToTitle(classes.function) + " data through the HTTP protocol"

  _features: {
    checkpoint: false
    multiline: false
    tls: {
      can_enable: false
      can_verify_certificate: true
      can_verify_hostname: true
      enabled_default: false
    }
  }

  classes: {
    commonly_used: false
    deployment_roles: ["service", "sidecar"]
    function: "receive"
    service_providers: []
  }

  requirements: [
    """
    This component exposes a configured port. You must ensure your network
    allows inbound access to this port if you want to accept requests from
    remote sources.
    """
  ]

  statuses: {
    delivery: "at_least_once"
    development: "beta"
  }

  support: {
    platforms: {
      "aarch64-unknown-linux-gnu": true
      "aarch64-unknown-linux-musl": true
      "x86_64-pc-windows-msv": true
      "x86_64-unknown-linux-gnu": true
      "x86_64-unknown-linux-musl": true
    }
  }

  output: log: fields: {
    message: {
      description: "The raw line line from the incoming payload."
      relevant_when: "`encoding` == \"text\""
      required: true
      type: string: {}
    }
  }

  options: {
    address: {
      description: "The address to listen for connections on"
      required: true
      type: string: examples: ["0.0.0.0:80", "localhost:80"]
    }
    encoding: {
      description: "The expected encoding of received data. Note that for `json` and `ndjson` encodings, the fields of the JSON objects are output as separate fields."
      required: false
      type: string: {
        default: "text"
        enum: {
          text: "Newline-delimited text, with each line forming a message."
          ndjson: "Newline-delimited JSON objects, where each line must contain a JSON object."
          json: "Array of JSON objects, which must be a JSON array containing JSON objects."
        }
      }
    }
    headers: {
      description: "A list of HTTP headers to include in the log event. These will override any values included in the JSON payload with conflicting names. An empty string will be inserted into the log event if the corresponding HTTP header was missing."
      required: false
      type: "[string]": {
        default: null
        examples: [["User-Agent", "X-My-Custom-Header"]]
      }
    }
  }
}
