package metadata

components: sources: [Name=string]: {
  type: "source"

  classes: {
    function: "collect" | "receive" | "test"
  }

  _features: {
    checkpoint: bool
    multiline: bool
    tls: false | {
      can_enable: true
      can_verify_certificate: false
      can_verify_hostname: false
      enabled_default: false
    }
  }

  output: {
    log?: {
      fields: {
        _host: {
          description: "The local hostname, equivalent to the `gethostname` command."
          required: true
          type: string: examples: ["host.mydomain.com"]
        }

        timestamp: {
          description: "The exact time the event was ingested into Vector.",
          required: true
          type: timestamp: {}
        }
      }
    }
  }

  options: {
    if _features.checkpoint {
      _data_dir: {
        description: "The directory used to persist file checkpoint positions. By default, the [global `data_dir` option][docs.global-options#data_dir] is used. Please make sure the Vector project has write permissions to this dir."
        required: false
        type: string: {
          default: null
          examples: ["/var/lib/vector"]
        }
      }
    }

    if _features.multiline {
      multiline: {
        description: "Multiline parsing configuration. If not specified, multiline parsing is disabled."
        required: false
        type: object: options: {
          condition_pattern: {
            description: "Condition regex pattern to look for. Exact behavior is configured via `mode`."
            required: true
            sort: 3
            type: string: examples: ["^[\\s]+", "\\\\$", "^(INFO|ERROR) ", ";$"]
          },
          mode: {
            description: "Mode of operation, specifies how the `condition_pattern` is interpreted."
            required: true
            sort: 2
            type: string: enum: {
              continue_through: "All consecutive lines matching this pattern are included in the group. The first line (the line that matched the start pattern) does not need to match the `ContinueThrough` pattern. This is useful in cases such as a Java stack trace, where some indicator in the line (such as leading whitespace) indicates that it is an extension of the preceding line.",
              continue_past: "All consecutive lines matching this pattern, plus one additional line, are included in the group. This is useful in cases where a log message ends with a continuation marker, such as a backslash, indicating that the following line is part of the same message.",
              halt_before: "All consecutive lines not matching this pattern are included in the group. This is useful where a log line contains a marker indicating that it begins a new message.",
              halt_with: "All consecutive lines, up to and including the first line matching this pattern, are included in the group. This is useful where a log line ends with a termination marker, such as a semicolon."
            }
          },
          start_pattern: {
            description: "Start regex pattern to look for as a beginning of the message."
            required: true
            sort: 1
            type: string: examples: ["^[^\\s]", "\\\\$", "^(INFO|ERROR) ", "[^;]$"]
          },
          timeout_ms: {
            description: "The maximum time to wait for the continuation. Once this timeout is reached, the buffered message is guaranteed to be flushed, even if incomplete."
            required: true
            sort: 4
            type: uint: {
              examples: [1_000, 600_000]
              unit: "milliseconds"
            }
          }
        }
      }
    }

    if _features.tls {
      tls: {
        description: "Configures the TLS options for connections from this source."
        required: false
        type: object: options: {
          if _features.tls.can_enable {
            enabled: {
              description: "Require TLS for incoming connections. If this is set, an identity certificate is also required."
              required: false
              type: bool: default: _features.tls.enabled_default
            }
          }

          ca_file: {
            description: "Absolute path to an additional CA certificate file, in DER or PEM format (X.509), or an in-line CA certificate in PEM format."
            required: false
            type: string: {
              default: null
              examples: ["/path/to/certificate_authority.crt"]
            }
          }
          crt_file: {
            description: "Absolute path to a certificate file used to identify this server, in DER or PEM format (X.509) or PKCS#12, or an in-line certificate in PEM format. If this is set, and is not a PKCS#12 archive, `key_file` must also be set. This is required if `enabled` is set to `true`."
            required: false
            type: string: {
              default: null
              examples: ["/path/to/host_certificate.crt"]
            }
          }
          key_file: {
            description: "Absolute path to a private key file used to identify this server, in DER or PEM format (PKCS#8), or an in-line private key in PEM format."
            required: false
            type: string: {
              default: null
              examples: ["/path/to/host_certificate.key"]
            }
          }
          key_pass: {
            description: "Pass phrase used to unlock the encrypted key file. This has no effect unless `key_file` is set."
            required: false
            type: string: {
              default: null
              examples: ["${KEY_PASS_ENV_VAR}", "PassWord1"]
            }
          }

          if _features.tls.enabled_default {
            verify_certificate: {
              description: "If `true`, Vector will require a TLS certificate from the connecting host and terminate the connection if the certificate is not valid. If `false` (the default), Vector will not request a certificate from the client."
              required: false
              type: bool: default: false
            }
          }

          if _features.tls.can_verify_hostname {
            verify_hostname: {
              description: "If `true` (the default), Vector will validate the configured remote host name against the remote host's TLS certificate. Do NOT set this to `false` unless you understand the risks of not verifying the remote host name."
              required: false
              type: bool: default: true
            }
          }
        }
      }
    }
  }
}
