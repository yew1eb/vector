use crate::{
    config::{DataType, GlobalOptions, SourceConfig, SourceDescription},
    event::{
        metric::{Metric, MetricKind, MetricValue},
        Event,
    },
    shutdown::ShutdownSignal,
    Pipeline,
};
use chrono::Utc;
use futures::{
    compat::Future01CompatExt,
    future::{FutureExt, TryFutureExt},
    stream::{self, StreamExt},
};
use futures01::Sink;
#[cfg(target_os = "linux")]
use heim::cpu::os::linux::CpuTimeExt;
use heim::{units::information::byte, units::time::second, Error};
use serde::{Deserialize, Serialize};
use std::time::Duration;
use tokio::{select, time};

macro_rules! btreemap {
    ( $( $key:expr => $value:expr ),* ) => {{
        let mut result = std::collections::BTreeMap::default();
        $( result.insert($key, $value); )*
            result
    }}
}

#[derive(Clone, Debug, Default, Deserialize, Serialize)]
struct HostMetricsConfig {
    #[serde(default = "scrape_interval_default")]
    scrape_interval_secs: u64,
}

const fn scrape_interval_default() -> u64 {
    15
}

inventory::submit! {
    SourceDescription::new::<HostMetricsConfig>("host_metrics")
}

#[typetag::serde(name = "host_metrics")]
impl SourceConfig for HostMetricsConfig {
    fn build(
        &self,
        _name: &str,
        _globals: &GlobalOptions,
        shutdown: ShutdownSignal,
        out: Pipeline,
    ) -> crate::Result<super::Source> {
        let interval = Duration::from_secs(self.scrape_interval_secs);
        let fut = run(out, shutdown, interval).boxed().compat();
        Ok(Box::new(fut))
    }

    fn output_type(&self) -> DataType {
        DataType::Metric
    }

    fn source_type(&self) -> &'static str {
        "host_metrics"
    }
}

async fn run(mut out: Pipeline, shutdown: ShutdownSignal, duration: Duration) -> Result<(), ()> {
    let mut interval = time::interval(duration).map(|_| ());
    let mut shutdown = shutdown.compat();

    loop {
        select! {
            Some(()) = interval.next() => (),
            _ = &mut shutdown => break,
            else => break,
        };

        let metrics = capture_metrics().await;

        let (sink, _) = out
            .send_all(futures01::stream::iter_ok(metrics))
            .compat()
            .await
            .map_err(|error| error!(message = "Error sending host metrics", %error))?;
        out = sink;
    }

    Ok(())
}

async fn capture_metrics() -> impl Iterator<Item = Event> {
    cpu_metrics()
        .await
        .chain(memory_metrics().await)
        .chain(swap_metrics().await)
        .map(Into::into)
}

async fn cpu_metrics() -> impl Iterator<Item = Metric> {
    match heim::cpu::times().await {
        Ok(times) => {
            times
                .map(Result::unwrap)
                .map(|times| {
                    let timestamp = Some(Utc::now());
                    let name = "host_cpu_seconds_total";
                    stream::iter(
                        vec![
                            Metric {
                                name: name.into(),
                                timestamp,
                                tags: Some(btreemap!("mode".into() => "idle".into())),
                                kind: MetricKind::Absolute,
                                value: MetricValue::Counter {
                                    value: times.idle().get::<second>(),
                                },
                            },
                            #[cfg(target_os = "linux")]
                            Metric {
                                name: name.into(),
                                timestamp,
                                tags: Some(btreemap!("mode".into() => "nice".into())),
                                kind: MetricKind::Absolute,
                                value: MetricValue::Counter {
                                    value: times.nice().get::<second>(),
                                },
                            },
                            Metric {
                                name: name.into(),
                                timestamp,
                                tags: Some(btreemap!("mode".into() => "system".into())),
                                kind: MetricKind::Absolute,
                                value: MetricValue::Counter {
                                    value: times.system().get::<second>(),
                                },
                            },
                            Metric {
                                name: name.into(),
                                timestamp,
                                tags: Some(btreemap!("mode".into() => "user".into())),
                                kind: MetricKind::Absolute,
                                value: MetricValue::Counter {
                                    value: times.user().get::<second>(),
                                },
                            },
                        ]
                        .into_iter(),
                    )
                })
                .flatten()
                .collect::<Vec<_>>()
                .await
        }
        Err(error) => {
            error!(message = "Failed to load CPU times", %error, rate_limit_secs = 60);
            vec![]
        }
    }
    .into_iter()
}

async fn memory_metrics() -> impl Iterator<Item = Metric> {
    match heim::memory::memory().await {
        Ok(memory) => {
            let timestamp = Some(Utc::now());
            vec![
                Metric {
                    name: "host_memory_total_bytes".into(),
                    timestamp,
                    tags: None,
                    kind: MetricKind::Absolute,
                    value: MetricValue::Gauge {
                        value: memory.total().get::<byte>() as f64,
                    },
                },
                Metric {
                    name: "host_memory_free_bytes".into(),
                    timestamp,
                    tags: None,
                    kind: MetricKind::Absolute,
                    value: MetricValue::Gauge {
                        value: memory.free().get::<byte>() as f64,
                    },
                },
                Metric {
                    name: "host_memory_FIXME_bytes".into(), // Doesn't match one of the metric names in the RFC
                    timestamp,
                    tags: None,
                    kind: MetricKind::Absolute,
                    value: MetricValue::Gauge {
                        value: memory.available().get::<byte>() as f64,
                    },
                },
                // Missing: used, buffers, cached, shared, active,
                // inactive on Linux from
                // heim::memory::os::linux::MemoryExt
            ]
        }
        Err(error) => {
            error!(message = "Failed to load memory info", %error, rate_limit_secs = 60);
            vec![]
        }
    }
    .into_iter()
}

async fn swap_metrics() -> impl Iterator<Item = Metric> {
    match heim::memory::swap().await {
        Ok(swap) => {
            let timestamp = Some(Utc::now());
            vec![
                Metric {
                    name: "host_memory_swap_free_bytes".into(),
                    timestamp,
                    tags: None,
                    kind: MetricKind::Absolute,
                    value: MetricValue::Gauge {
                        value: swap.free().get::<byte>() as f64,
                    },
                },
                Metric {
                    name: "host_memory_swap_total_bytes".into(),
                    timestamp,
                    tags: None,
                    kind: MetricKind::Absolute,
                    value: MetricValue::Gauge {
                        value: swap.total().get::<byte>() as f64,
                    },
                },
                Metric {
                    name: "host_memory_swap_used_bytes".into(),
                    timestamp,
                    tags: None,
                    kind: MetricKind::Absolute,
                    value: MetricValue::Gauge {
                        value: swap.used().get::<byte>() as f64,
                    },
                },
            ]
        }
        Err(error) => {
            error!(message = "Failed to load swap info", %error, rate_limit_secs = 60);
            vec![]
        }
    }
    .into_iter()
}
