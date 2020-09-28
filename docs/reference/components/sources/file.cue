package metadata

import (
  "strings"
)

components: sources: file: {
  title: "File"
  description: strings.ToTitle(classes.function) + " data by tailing one more files."

  _features: {
    checkpoint: true
    multiline: true
    tls: false
  }

  classes: {
    commonly_used: true
    deployment_roles: ["daemon", "sidecar"]
    function: "collect"
    service_providers: []
  }

  statuses: {
    delivery: "best_effort"
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
    file: {
      description: "The absolute path of the file the log originated from."
      required: true
      type: string: examples: ["/var/log/nginx.log"]
    }
    host: fields._host,
    message: {
      description: "The raw line from the file."
      required: true
      type: string: examples: ["Hello world"]
    }
  }

  options: {
    exclude: {
      description: "Array of file patterns to exclude. [Globbing](#globbing) is supported.*Takes precedence over the [`include` option](#include).*"
      required: false
      type: "[string]": {
        default: null
        examples: [["/var/log/nginx/*.[0-9]*.log"]]
      }
    }
    file_key: {
      description: "The key name added to each event with the full path of the file."
      required: false
      type: string: {
        default: "file"
        examples: ["file"]
      }
    }
    fingerprinting: {
      description: "Configuration for how the file source should identify files."
      required:      false
      type: object: options: {
        strategy: {
          description: "The strategy used to uniquely identify files. This is important for [checkpointing](#checkpointing) when file rotation is used."
          required: false
          type: string: {
            default: "checksum"
            enum: {
              checksum: "Read `fingerprint_bytes` bytes from the head of the file to uniquely identify files via a checksum."
              device_and_inode: "Uses the [device and inode][urls.inode] to unique identify files."
            }
            examples: ["checksum", "device_and_inode"]
          }
        }
        fingerprint_bytes: {
          description: "The number of bytes read off the head of the file to generate a unique fingerprint."
          relevant_when: "`strategy` = \"checksum\""
          required: false
          type: uint: {
            default: 256
            unit: "bytes"
          }
        }
        ignored_header_bytes: {
          description: "The number of bytes to skip ahead (or ignore) when generating a unique fingerprint. This is helpful if all files share a common header."
          relevant_when: "`strategy` = \"checksum\""
          required: false
          type: uint: {
            default: 0
            unit: "bytes"
          }
        }
      }
    }
    glob_minimum_cooldown: {
      description: "Delay between file discovery calls. This controls the interval at which Vector searches for files."
      required: false
      type: uint: {
        default: 1_000
        unit: "milliseconds"
      }
    }
    host_key: {
      description: "The key name added to each event representing the current host. This can also be globally set via the [global `host_key` option][docs.reference.global-options#host_key]."
      required: false
      type: string: default: "host"
    }
    ignore_older: {
      description: "Ignore files with a data modification date that does not exceed this age."
      required: false
      type: uint: {
        default: null
        examples: [60 * 10]
        unit: "seconds"
      }
    }
    include: {
      description: "Array of file patterns to include. [Globbing](#globbing) is supported."
      required: true
      type: "[string]": examples: [["/var/log/nginx/*.log"]]
    }
    max_line_bytes: {
      description: "The maximum number of a bytes a line can contain before being discarded. This protects against malformed lines or tailing incorrect files."
      required:      false
      type: uint: {
        default: 102_400
        unit: "bytes"
      }
    }
    max_read_bytes: {
      description: "An approximate limit on the amount of data read from a single file at a given time."
      required: false
      type: uint: {
        default: null,
        examples: [2048]
        unit: "bytes"
      }
    }
    oldest_first: {
      description: "Instead of balancing read capacity fairly across all watched files, prioritize draining the oldest files before moving on to read data from younger files."
      required: false
      type: bool: default: false
    }
    remove_after: {
      description: "Timeout from reaching `eof` after which file will be removed from filesystem, unless new data is written in the meantime. If not specified, files will not be removed."
      required: false
      type: uint: {
        default: null
        examples: [0, 5, 60]
        unit: "seconds"
      }
    }
    start_at_beginning: {
      description: "For files with a stored checkpoint at startup, setting this option to `true` will tell Vector to read from the beginning of the file instead of the stored checkpoint. "
      required: false
      type: bool: default: false
    }
  }

  how_it_works: [
    {
      title: "Environment Variables"
      body:  """
             Environment variables are supported through all of Vector's
             configuration. Simply add ${MY_ENV_VAR} in your Vector
             configuration file and the variable will be replaced before being
             evaluated.

             Learn more in the [configuration manua](/docs/manual/setup/configuration).
             """
    }
  ]
}
