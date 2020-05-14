<p><img src="https://cdn.worldvectorlogo.com/logos/prometheus.svg" alt="prometheus logo" title="prometheus" align="right" height="60" /></p>

# Ansible Role: prometheus-server

## Description

Deploy [Prometheus](https://github.com/prometheus/prometheus) monitoring system using ansible.

### Upgradability notice

When upgrading from <= 2.4.0 version of this role to >= 2.4.1 please turn off your prometheus instance. More in [2.4.1 release notes](https://github.com/cloudalchemy/ansible-prometheus/releases/tag/2.4.1)

## Requirements

- Ansible >= 2.7 (It might work on previous versions, but we cannot guarantee it)
- jmespath on deployer machine. If you are using Ansible from a Python virtualenv, install *jmespath* to the same virtualenv via pip.
- gnu-tar on Mac deployer host (`brew install gnu-tar`)

## Role Variables

All variables which can be overridden are stored in [defaults/main.yml](defaults/main.yml) file as well as in table below.

| Name           | Default Value | Description                        |
| -------------- | ------------- | -----------------------------------|
| `prometheus_version` | 2.18.0 | Prometheus package version. Also accepts `latest` as parameter. Only prometheus 2.x is supported |
| `prometheus_skip_install` | false | Prometheus installation tasks gets skipped when set to true. |
| `prometheus_binary_local_dir` | "" | Allows to use local packages instead of ones distributed on github. As parameter it takes a directory where `prometheus` AND `promtool` binaries are stored on host on which ansible is ran. This overrides `prometheus_version` parameter |
| `prometheus_config_dir` | /etc/prometheus | Path to directory with prometheus configuration |
| `prometheus_db_dir` | /var/lib/prometheus | Path to directory with prometheus database |
| `prometheus_web_listen_address` | "0.0.0.0:9090" | Address on which prometheus will be listening |
| `prometheus_web_external_url` | "" | External address on which prometheus is available. Useful when behind reverse proxy. Ex. `http://example.org/prometheus` |
| `prometheus_storage_retention` | "30d" | Data retention period |
| `prometheus_storage_retention_size` | "0" | Data retention period by size |
| `prometheus_config_flags_extra` | {} | Additional configuration flags passed to prometheus binary at startup |
| `prometheus_alertmanager_config` | [] | Configuration responsible for pointing where alertmanagers are. This should be specified as list in yaml format. It is compatible with official [<alertmanager_config>](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#alertmanager_config) |
| `prometheus_alert_relabel_configs` | [] | Alert relabeling rules. This should be specified as list in yaml format. It is compatible with the official [<alert_relabel_configs>](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#alert_relabel_configs) |
| `prometheus_global` | { scrape_interval: 60s, scrape_timeout: 15s, evaluation_interval: 15s } | Prometheus global config. Compatible with [official configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#configuration-file) |
| `prometheus_remote_write` | [] | Remote write. Compatible with [official configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#<remote_write>) |
| `prometheus_remote_read` | [] | Remote read. Compatible with [official configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#<remote_read>) |
| `prometheus_external_labels` | environment: "{{ ansible_fqdn \| default(ansible_host) \| default(inventory_hostname) }}" | Provide map of additional labels which will be added to any time series or alerts when communicating with external systems |
| `prometheus_targets` | {} | Targets which will be scraped. Better example is provided in our [demo site](https://github.com/cloudalchemy/demo-site/blob/2a8a56fc10ce613d8b08dc8623230dace6704f9a/group_vars/all/vars#L8) |
| `prometheus_scrape_configs` | [defaults/main.yml#L58](https://github.com/cloudalchemy/ansible-prometheus/blob/ff7830d06ba57be1177f2b6fca33a4dd2d97dc20/defaults/main.yml#L47) | Prometheus scrape jobs provided in same format as in [official docs](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config) |
| `prometheus_config_file` | "prometheus.yml.j2" | Variable used to provide custom prometheus configuration file in form of ansible template |
| `prometheus_alert_rules` | [defaults/main.yml#L81](https://github.com/cloudalchemy/ansible-prometheus/blob/73d6df05a775ee5b736ac8f28d5605f2a975d50a/defaults/main.yml#L85) | Full list of alerting rules which will be copied to `{{ prometheus_config_dir }}/rules/ansible_managed.rules`. Alerting rules can be also provided by other files located in `{{ prometheus_config_dir }}/rules/` which have `*.rules` extension |
| `prometheus_alert_rules_files` | [defaults/main.yml#L78](https://github.com/cloudalchemy/ansible-prometheus/blob/73d6df05a775ee5b736ac8f28d5605f2a975d50a/defaults/main.yml#L78) | List of folders where ansible will look for files containing alerting rules which will be copied to `{{ prometheus_config_dir }}/rules/`. Files must have `*.rules` extension |
| `prometheus_static_targets_files` | [defaults/main.yml#L78](https://github.com/cloudalchemy/ansible-prometheus/blob/73d6df05a775ee5b736ac8f28d5605f2a975d50a/defaults/main.yml#L81) | List of folders where ansible will look for files containing custom static target configuration files which will be copied to `{{ prometheus_config_dir }}/file_sd/`. |


### Relation between `prometheus_scrape_configs` and `prometheus_targets`

#### Short version

`prometheus_targets` is just a map used to create multiple files located in "{{ prometheus_config_dir }}/file_sd" directory. Where file names are composed from top-level keys in that map with `.yml` suffix. Those files store [file_sd scrape targets data](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#file_sd_config) and they need to be read in `prometheus_scrape_configs`.

#### Long version

A part of *prometheus.yml* configuration file which describes what is scraped by prometheus is stored in `prometheus_scrape_configs`. For this variable same configuration options as described in [prometheus docs](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#<scrape_config>) are used.

Meanwhile `prometheus_targets` is our way of adopting [prometheus scrape type `file_sd`](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#<file_sd_config>). It defines a map of files with their content. A top-level keys are base names of files which need to have their own scrape job in `prometheus_scrape_configs` and values are a content of those files.

All this mean that you CAN use custom `prometheus_scrape_configs` with `prometheus_targets` set to `{}`. However when you set anything in `prometheus_targets` it needs to be mapped to `prometheus_scrape_configs`. If it isn't you'll get an error in preflight checks.

#### Example

Lets look at our default configuration, which shows all features. By default we have this `prometheus_targets`:
```
prometheus_targets:
  node:  # This is a base file name. File is located in "{{ prometheus_config_dir }}/file_sd/<<BASENAME>>.yml"
    - targets:              #
        - localhost:9100    # All this is a targets section in file_sd format
      labels:               #
        env: test           #
```
Such config will result in creating one file named `node.yml` in `{{ prometheus_config_dir }}/file_sd` directory.

Next this file needs to be loaded into scrape config. Here is modified version of our default `prometheus_scrape_configs`:
```
prometheus_scrape_configs:
  - job_name: "prometheus"    # Custom scrape job, here using `static_config`
    metrics_path: "/metrics"
    static_configs:
      - targets:
          - "localhost:9090"
  - job_name: "example-node-file-servicediscovery"
    file_sd_configs:
      - files:
          - "{{ prometheus_config_dir }}/file_sd/node.yml" # This line loads file created from `prometheus_targets`
```

## Example

### Playbook

```yaml
---
- hosts: prometheus-server
  roles:
  - roles/prometheus-server
```

### Defining alerting rules files

Alerting rules are defined in `prometheus_alert_rules` variable. Format is almost identical to one defined in[ Prometheus 2.0 documentation](https://prometheus.io/docs/prometheus/latest/configuration/template_examples/).
Due to similarities in templating engines, every templates should be wrapped in `{% raw %}` and `{% endraw %}` statements. Example is provided in [defaults/main.yml](defaults/main.yml) file.

-----------------------------------------------------------------------------------------------------------------------------------------------------------

<p><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/1/1d/Human-dialog-warning.svg/2000px-Human-dialog-warning.svg.png" alt="alert logo" title="alert" align="right" height="60" /></p>

# Ansible Role: alertmanager

## Description

Deploy and manage Prometheus [alertmanager](https://github.com/prometheus/alertmanager) service using ansible.

## Requirements

- Ansible >= 2.7 (It might work on previous versions, but we cannot guarantee it)

It would be nice to have prometheus installed somewhere

## Role Variables

All variables which can be overridden are stored in [defaults/main.yml](defaults/main.yml) file as well as in table below.

| Name           | Default Value | Description                        |
| -------------- | ------------- | -----------------------------------|
| `alertmanager_version` | 0.20.0 | Alertmanager package version. Also accepts `latest` as parameter. |
| `alertmanager_binaries_local_dir` | "" | Allows to use local packages instead of ones distributed on github. As parameter it takes a directory where `alertmanager` AND `amtool` binaries are stored on host on which ansible is ran. This overrides `alertmanager_version` parameter |
| `alertmanager_web_listen_address` | 0.0.0.0:9093 | Address on which alertmanager will be listening |
| `alertmanager_web_external_url` | http://localhost:9093/ | External address on which alertmanager is available. Useful when behind reverse proxy. Ex. example.org/alertmanager |
| `alertmanager_config_dir` | /etc/alertmanager | Path to directory with alertmanager configuration |
| `alertmanager_db_dir` | /var/lib/alertmanager | Path to directory with alertmanager database |
| `alertmanager_config_file` | alertmanager.yml.j2 | Variable used to provide custom alertmanager configuration file in form of ansible template |
| `alertmanager_config_flags_extra` | {} | Additional configuration flags passed to prometheus binary at startup |
| `alertmanager_template_files` | ['alertmanager/templates/*.tmpl'] | List of folders where ansible will look for template files which will be copied to `{{ alertmanager_config_dir }}/templates/`. Files must have `*.tmpl` extension |
| `alertmanager_resolve_timeout` | 3m | Time after which an alert is declared resolved |
| `alertmanager_smtp` | {} | SMTP (email) configuration |
| `alertmanager_http_config` | {} | Http config for using custom webhooks |
| `alertmanager_slack_api_url` | "" | Slack webhook url |
| `alertmanager_pagerduty_url` | "" | Pagerduty webhook url |
| `alertmanager_opsgenie_api_key` | "" | Opsgenie webhook key |
| `alertmanager_opsgenie_api_url` | "" | Opsgenie webhook url |
| `alertmanager_hipchat_api_url` | "" | Hipchat webhook url |
| `alertmanager_hipchat_auth_token` | "" | Hipchat authentication token |
| `alertmanager_wechat_url` | "" | Enterprise WeChat webhook url |
| `alertmanager_wechat_secret` | "" | Enterprise WeChat secret token |
| `alertmanager_wechat_corp_id` | "" | Enterprise WeChat corporation id |
| `alertmanager_cluster` | {listen-address: ""} | HA cluster network configuration. Disabled by default. More information in [alertmanager readme](https://github.com/prometheus/alertmanager#high-availability) |
| `alertmanager_receivers` | [] | A list of notification receivers. Configuration same as in [official docs](https://prometheus.io/docs/alerting/configuration/#<receiver>) |
| `alertmanager_inhibit_rules` | [] | List of inhibition rules. Same as in [official docs](https://prometheus.io/docs/alerting/configuration/#inhibit_rule) |
| `alertmanager_route` | {} | Alert routing. More in [official docs](https://prometheus.io/docs/alerting/configuration/#<route>) |

## Example

### Playbook

```yaml
---
- hosts: prometheus-server
  roles:
  - roles/alertmanager
```

-----------------------------------------------------------------------------------------------------------------------------------------------------------

<p><img src="https://cdn.worldvectorlogo.com/logos/prometheus.svg" alt="graph logo" title="graph" align="right" height="60" /></p>

# Ansible Role: node exporter

## Description

Deploy prometheus [node exporter](https://github.com/prometheus/node_exporter) using ansible.

## Requirements

- Ansible >= 2.7 (It might work on previous versions, but we cannot guarantee it)
- gnu-tar on Mac deployer host (`brew install gnu-tar`)

## Role Variables

All variables which can be overridden are stored in [defaults/main.yml](defaults/main.yml) file as well as in table below.

| Name           | Default Value | Description                        |
| -------------- | ------------- | -----------------------------------|
| `node_exporter_version` | 0.18.1 | Node exporter package version. Also accepts latest as parameter. |
| `node_exporter_binary_local_dir` | "" | Allows to use local packages instead of ones distributed on github. As parameter it takes a directory where `node_exporter` binary is stored on host on which ansible is ran. This overrides `node_exporter_version` parameter |
| `node_exporter_web_listen_address` | "0.0.0.0:9100" | Address on which node exporter will listen |
| `node_exporter_enabled_collectors` | [ systemd, textfile ] | List of additionally enabled collectors. It adds collectors to [those enabled by default](https://github.com/prometheus/node_exporter#enabled-by-default) |
| `node_exporter_disabled_collectors` | [] | List of disabled collectors. By default node_exporter disables collectors listed [here](https://github.com/prometheus/node_exporter#disabled-by-default). |
| `node_exporter_textfile_dir` | "/var/lib/node_exporter" | Directory used by the [Textfile Collector](https://github.com/prometheus/node_exporter#textfile-collector). To get permissions to write metrics in this directory, users must be in `node-exp` system group.

## Example

### Playbook

Use it in a playbook as follows:
```yaml
---
- hosts: node-exporters
  roles:
  - roles/node-exporter

```

-----------------------------------------------------------------------------------------------------------------------------------------------------------

<p><img src="https://github.com/grafana/grafana/blob/master/public/img/grafana_icon.svg" alt="grafana logo" title="grafana" align="right" height="60" /></p>

# Ansible Role: grafana

Provision and manage [grafana](https://github.com/grafana/grafana) - platform for analytics and monitoring

## Requirements

- Ansible >= 2.7 (It might work on previous versions, but we cannot guarantee it)
- libselinux-python on deployer host (only when deployer machine has SELinux)
- grafana >= 5.1 (for older grafana versions use this role in version 0.10.1 or earlier)
- jmespath on deployer machine. If you are using Ansible from a Python virtualenv, install *jmespath* to the same virtualenv via pip.

## Role Variables

All variables which can be overridden are stored in [defaults/main.yml](defaults/main.yml) file as well as in table below.

| Name           | Default Value | Description                        |
| -------------- | ------------- | -----------------------------------|
| `grafana_use_provisioning` | true | Use Grafana provisioning capability when possible (**grafana_version=latest will assume >= 5.0**). |
| `grafana_provisioning_synced` | false | Ensure no previously provisioned dashboards are kept if not referenced anymore. |
| `grafana_system_user` | grafana | Grafana server system user |
| `grafana_system_group` | grafana | Grafana server system group |
| `grafana_version` | latest | Grafana package version |
| `grafana_yum_repo_template` | etc/yum.repos.d/grafana.repo.j2 | Yum template to use |
| `grafana_instance` | {{ ansible_fqdn \| default(ansible_host) \| default(inventory_hostname) }} | Grafana instance name |
| `grafana_logs_dir` | /var/log/grafana | Path to logs directory |
| `grafana_data_dir` | /var/lib/grafana | Path to database directory |
| `grafana_address` | 0.0.0.0 | Address on which grafana listens |
| `grafana_port` | 3000 | port on which grafana listens |
| `grafana_cap_net_bind_service` | false | Enables the use of ports below 1024 without root privileges by leveraging the 'capabilities' of the linux kernel. read: http://man7.org/linux/man-pages/man7/capabilities.7.html |
| `grafana_url` | "http://{{ grafana_address }}:{{ grafana_port }}" | Full URL used to access Grafana from a web browser |
| `grafana_api_url` | "{{ grafana_url }}" | URL used for API calls in provisioning if different from public URL. See [this issue](https://github.com/cloudalchemy/ansible-grafana/issues/70). |
| `grafana_domain` | "{{ ansible_fqdn \| default(ansible_host) \| default('localhost') }}" | setting is only used in as a part of the `root_url` option. Useful when using GitHub or Google OAuth |
| `grafana_server` | { protocol: http, enforce_domain: false, socket: "", cert_key: "", cert_file: "", enable_gzip: false, static_root_path: public, router_logging: false } | [server](http://docs.grafana.org/installation/configuration/#server) configuration section |
| `grafana_security` | { admin_user: admin, admin_password: "" } | [security](http://docs.grafana.org/installation/configuration/#security) configuration section |
| `grafana_database` | { type: sqlite3 } | [database](http://docs.grafana.org/installation/configuration/#database) configuration section |
| `grafana_welcome_email_on_sign_up` | false | Send welcome email after signing up |
| `grafana_users` | { allow_sign_up: false, auto_assign_org_role: Viewer, default_theme: dark } | [users](http://docs.grafana.org/installation/configuration/#users) configuration section |
| `grafana_auth` | {} | [authorization](http://docs.grafana.org/installation/configuration/#auth) configuration section |
| `grafana_ldap` | {} | [ldap](http://docs.grafana.org/installation/ldap/) configuration section. group_mappings are expanded, see defaults for example |
| `grafana_session` | {} | [session](http://docs.grafana.org/installation/configuration/#session) management configuration section |
| `grafana_analytics` | {} | Google [analytics](http://docs.grafana.org/installation/configuration/#analytics) configuration section |
| `grafana_smtp` | {} | [smtp](http://docs.grafana.org/installation/configuration/#smtp) configuration section |
| `grafana_alerting` | {} | [alerting](http://docs.grafana.org/installation/configuration/#alerting) configuration section |
| `grafana_log` | {} | [log](http://docs.grafana.org/installation/configuration/#log) configuration section |
| `grafana_metrics` | {} | [metrics](http://docs.grafana.org/installation/configuration/#metrics) configuration section |
| `grafana_tracing` | {} | [tracing](http://docs.grafana.org/installation/configuration/#tracing) configuration section |
| `grafana_snapshots` | {} | [snapshots](http://docs.grafana.org/installation/configuration/#snapshots) configuration section |
| `grafana_image_storage` | {} | [image storage](http://docs.grafana.org/installation/configuration/#external-image-storage) configuration section |
| `grafana_dashboards` | [] | List of dashboards which should be imported |
| `grafana_dashboards_dir` | "dashboards" | Path to a local directory containing dashboards files in `json` format |
| `grafana_datasources` | [] | List of datasources which should be configured |
| `grafana_environment` | {} | Optional Environment param for Grafana installation, useful ie for setting http_proxy |
| `grafana_plugins` | [] |  List of Grafana plugins which should be installed |

Datasource example:

```yaml
grafana_datasources:
  - name: prometheus
    type: prometheus
    access: proxy
    url: 'http://{{ prometheus_web_listen_address }}'
    basicAuth: false
```

Dashboard example:

```yaml
grafana_dashboards:
  - dashboard_id: 111
    revision_id: 1
    datasource: prometheus
```
Use a custom Grafana Yum repo template example:

- Put your template next to your playbook under `templates` folder

- Use a different path than the default one, because ansible , when using relative path, use the first template found and look under the role directory at first then the playbook directory.

- The template expansion will be put under  `/etc/yum.repos.d/` , and will have as a name, the `basename` of the template path without the .j2

  Example:

  ```yaml
  grafana_yum_repo_template: my_yum_repos/grafana.repo.j2

  # [playbook_dir]/templates/my_yum_repos/grafana.repo.j2
  # will be put under
  # /etc/yum.repos.d/grafana.repo
  # on the remote host
  ```

## Supported CPU Architectures

Historically packages were taken from different channels according to CPU architecture. Specifically, armv6/armv7 and aarch64/arm64 packages were via [unofficial packages distributed by fg2it](https://github.com/fg2it/grafana-on-raspberry). Now that Grafana publishes official ARM builds, all packages are taken from the official [Debian/Ubuntu](http://docs.grafana.org/installation/debian/#installing-on-debian-ubuntu) or [RPM](http://docs.grafana.org/installation/rpm/) packages.

## Example

### Playbook

Fill in the admin password field with your choice, the Grafana web page won't ask to change it at the first login.

```yaml
---
- hosts: grafana-server
  roles:
  - roles/grafana

```

-----------------------------------------------------------------------------------------------------------------------------------------------------------


ansible-influxdb
=========

Install InfluxDB on a host

Role Variables
--------------

### `vars`
influxdb_url: URL of source package for InfluxDB. Set in `vars`


### `defaults`

| Variable  | Default | Description |
| ---  | --- | --- |
|influxdb_version| 1.8.0| |
|influxdb_index_version| tsi1| |
|influxdb_meta_dir| /var/lib/influxdb/meta| |
|influxdb_meta_retention_autocreate| true| |
|influxdb_meta_logging_enabled| true| |
|influxdb_admin_user| admin|
|influxdb_data_dir| /var/lib/influxdb/data | The directory where the TSM storage engine stores TSM files.|
|influxdb_data_wal_dir| /var/lib/influxdb/wal | The directory where the TSM storage engine stores WAL files.|
|influxdb_data_wal_fsync_delay| 0s | Values in the range of 0-100ms are recommended for non-SSD disks.|
|influxdb_data_index_version| inmem | The type of shard index to use for new shards.  The default is an in-memory index that is recreated at startup.  A value of "tsi1" will use a disk based index that supports higher cardinality datasets.|
|influxdb_data_trace_logging_enabled| false | Trace logging provides more verbose output around the tsm engine. Turning this on can provide more useful output for debugging tsm engine issues.|
|influxdb_data_query_log_enabled| true | The type of shard index to use for new shards.  The default is an in-memory index that is recreated at startup.  A value of "tsi1" will use a disk based index that supports higher Whether queries should be logged before execution. Very useful for troubleshooting, but will log any sensitive data contained within a query.|
|influxdb_data_validate_keys| false | Validates incoming writes to ensure keys only have valid unicode characters.  This setting will incur a small overhead because every key must be checked.|
|influxdb_data_cache_max_memory_size| 1g | CacheMaxMemorySize is the maximum size a shard's cache can reach before it starts rejecting writes.  Valid size suffixes are k, m, or g (case insensitive, 1024 = 1k).  Values without a size suffix are in bytes.|
|influxdb_data_cache_snapshot_memory_size| 25m | CacheSnapshotMemorySize is the size at which the engine will snapshot the cache and write it to a TSM file, freeing up memory Valid size suffixes are k, m, or g (case insensitive, 1024 = 1k).  Values without a size suffix are in bytes.|
|influxdb_data_cache_snapshot_write_cold_duration| 10m | CacheSnapshotWriteColdDuration is the length of time at which the engine will snapshot the cache and write it to a new TSM file if the shard hasn't received writes or deletes|
|influxdb_data_compact_full_write_cold_duration| 4h | CompactFullWriteColdDuration is the duration at which the engine will compact all TSM files in a shard if it hasn't received a write or delete|
|influxdb_data_max_concurrent_compactions| 0 | The maximum number of concurrent full and level compactions that can run at one time.  A value of 0 results in 50% of runtime.GOMAXPROCS(0) used at runtime.  Any number greater than 0 limits compactions to that value.  This setting does not apply to cache snapshotting.|
|influxdb_data_compact_throughput| 48m | CompactThroughput is the rate limit in bytes per second that we will allow TSM compactions to write to disk. Note that short bursts are allowed to happen at a possibly larger value, set by CompactThroughputBurst|
|influxdb_data_compact_throughput_burst| 48m | CompactThroughputBurst is the rate limit in bytes per second that we will allow TSM compactions to write to disk.|
|influxdb_data_tsm_use_madv_willneed| false | If true, then the mmap advise value MADV_WILLNEED will be provided to the kernel with respect to TSM files. This setting has been found to be problematic on some kernels, and defaults to off.  It might help users who have slow disks in some cases.|
|influxdb_data_max_series_per_database| 1000000 | The maximum series allowed per database before writes are dropped.  This limit can prevent high cardinality issues at the database level.  This limit can be disabled by setting it to 0.|
|influxdb_data_max_values_per_tag| 100000 | The maximum number of tag values per tag that are allowed before writes are dropped.  This limit can prevent high cardinality tag values from being written to a measurement.  This limit can be disabled by setting it to 0.|
|influxdb_data_max_index_log_file_size| 1m | The threshold, in bytes, when an index write-ahead log file will compact into an index file. Lower sizes will cause log files to be compacted more quickly and result in lower heap usage at the expense of write throughput.  Higher sizes will be compacted less frequently, store more series in-memory, and provide higher write throughput.  Valid size suffixes are k, m, or g (case insensitive, 1024 = 1k).  Values without a size suffix are in bytes.|
|influxdb_data_series_id_set_cache_size| 100 | The size of the internal cache used in the TSI index to store previously calculated series results. Cached results will be returned quickly from the cache rather than needing to be recalculated when a subsequent query with a matching tag key/value predicate is executed. Setting this value to 0 will disable the cache, which may lead to query performance issues.  This value should only be increased if it is known that the set of regularly used tag key/value predicates across all measurements for a database is larger than 100. An increase in cache size may lead to an increase in heap usage.|
|influxdb_coordinator_write_timeout| 10s | The default time a write request will wait until a "timeout" error is returned to the caller.|
|influxdb_coordinator_max_concurrent_queries| 0 | The maximum number of concurrent queries allowed to be executing at one time.  If a query is executed and exceeds this limit, an error is returned to the caller.  This limit can be disabled by setting it to 0.|
|influxdb_coordinator_query_timeout| 0s | The maximum time a query will is allowed to execute before being killed by the system.  This limit can help prevent run away queries.  Setting the value to 0 disables the limit.|
|influxdb_coordinator_log_queries_after| 0s | The time threshold when a query will be logged as a slow query.  This limit can be set to help discover slow or resource intensive queries.  Setting the value to 0 disables the slow query logging.|
|influxdb_coordinator_max_select_point| 0 | The maximum number of points a SELECT can process.  A value of 0 will make the maximum point count unlimited.  This will only be checked every second so queries will not be aborted immediately when hitting the limit.|
|influxdb_coordinator_max_select_series| 0 | The maximum number of series a SELECT can run.  A value of 0 will make the maximum series count unlimited.|
|influxdb_coordinator_max_select_buckets| 0 | The maximum number of group by time bucket a SELECT can create.  A value of zero will max the maximum number of buckets unlimited.|
|influxdb_retention_enabled| true | Determines whether retention policy enforcement enabled.|
|influxdb_retention_check_interval| 30m | The interval of time when retention policy enforcement checks run.|
|influxdb_shard_precreation_enabled| true | Determines whether shard pre-creation service is enabled.|
|influxdb_shard_precreation_check_interval| 10m | The interval of time when the check to pre-create new shards runs.|
|influxdb_shard_precreation_advance_period| 30m | The default period ahead of the endtime of a shard group that its successor group is created.|
|influxdb_monitor_store_enabled| true | Whether to record statistics internally.|
|influxdb_monitor_store_database| _internal | The destination database for recorded statistics|
|influxdb_monitor_store_interval| 10s | The interval at which to record statistics|
|influxdb_http_enabled| true | Determines whether HTTP endpoint is enabled.|
|influxdb_http_flux_enabled| false | Determines whether the Flux query endpoint is enabled.|
|influxdb_http_flux_log_enabled| false | Determines whether the Flux query logging is enabled.|
|influxdb_http_bind_address| ":8086" | The bind address used by the HTTP service.|
|influxdb_http_auth_enabled| false | Determines whether user authentication is enabled over HTTP/HTTPS.|
|influxdb_admin_user_name| admin| |
|admin_user_password| "{{ influxdb_admin_user_password }}"| |
|influxdb_http_realm| InfluxDB | The default realm sent back when issuing a basic auth challenge.|
|influxdb_http_log_enabled| true | Determines whether HTTP request logging is enabled.|
|influxdb_http_suppress_write_log| false | Determines whether the HTTP write request logs should be suppressed when the log is enabled.|
|influxdb_http_access_log_path| "" | When HTTP request logging is enabled, this option specifies the path where log entries should be written. If unspecified, the default is to write to stderr, which intermingles HTTP logs with internal InfluxDB logging.  If influxd is unable to access the specified path, it will log an error and fall back to writing the request log to stderr.|
|influxdb_http_access_log_status_filters| [] | Filters which requests should be logged. Each filter is of the pattern NNN, NNX, or NXX where N is a number and X is a wildcard for any number. To filter all 5xx responses, use the string 5xx.  If multiple filters are used, then only one has to match. The default is to have no filters which will cause every request to be printed.|
|influxdb_http_write_tracing| false | Determines whether detailed write logging is enabled.|
|influxdb_http_pprof_enabled| true | Determines whether the pprof endpoint is enabled.  This endpoint is used for troubleshooting and monitoring.|
|influxdb_http_pprof_auth_enabled| influxdb_http_pprof_enabled | Enables authentication on pprof endpoints. Users will need admin permissions to access the pprof endpoints when this setting is enabled. This setting has no effect if either auth-enabled or pprof-enabled are set to false.|
|influxdb_http_debug_pprof_enabled| false | Enables a pprof endpoint that binds to localhost:6060 immediately on startup.  This is only needed to debug startup issues.|
|influxdb_http_ping_auth_enabled| influxdb_http_pprof_enabled  | Enables authentication on the /ping, /metrics, and deprecated /status endpoints. This setting has no effect if auth-enabled is set to false.|
|influxdb_http_https_enabled| false | Determines whether HTTPS is enabled.|
|influxdb_http_https_certificate| /etc/ssl/influxdb.pem | The SSL certificate to use when HTTPS is enabled.|
|influxdb_http_https_private_key| "" | Use a separate private key location.|
|influxdb_http_shared_secret| "" | The JWT auth shared secret to validate requests using JSON web tokens.|
|influxdb_http_max_row_limit| 0 | The default chunk size for result sets that should be chunked.|
|influxdb_http_max_connection_limit| 0 | The maximum number of HTTP connections that may be open at once.  New connections that would exceed this limit are dropped.  Setting this value to 0 disables the limit.|
|influxdb_http_unix_socket_enabled| false | Enable http service over unix domain socket|
|influxdb_http_bind_socket| /var/run/influxdb.sock | The path of the unix domain socket.|
|influxdb_http_max_body_size| 25000000 | The maximum size of a client request body, in bytes. Setting this value to 0 disables the limit.|
|influxdb_http_max_concurrent_write_limit| 0 | The maximum number of writes processed concurrently.  Setting this to 0 disables the limit.|
|influxdb_http_max_enqueued_write_limit| 0 | The maximum number of writes queued for processing.  Setting this to 0 disables the limit.|
|influxdb_http_enqueued_write_timeout| 0 | The maximum duration for a write to wait in the queue to be processed.  Setting this to 0 or setting max-concurrent-write-limit to 0 disables the limit.|
|influxdb_logging_format| auto | Determines which log encoder to use for logs. Available options are auto, logfmt, and json. auto will use a more a more user-friendly output format if the output terminal is a TTY, but the format is not as easily machine-readable. When the output is a non-TTY, auto will use logfmt.|
|influxdb_logging_level| info | Determines which level of logs will be emitted. The available levels are error, warn, info, and debug. Logs that are equal to or above the specified level will be emitted.|
|influxdb_logging_suppress_logo| false | Suppresses the logo output that is printed when the program is started.  The logo is always suppressed if STDOUT is not a TTY.|
|influxdb_subscriber_enabled| true | Determines whether the subscriber service is enabled.|
|influxdb_subscriber_http_timeout| 30s | The default timeout for HTTP writes to subscribers.|
|influxdb_subscriber_insecure_skip_verify| false | Allows insecure HTTPS connections to subscribers.  This is useful when testing with self-signed certificates.|
|influxdb_subscriber_ca_certs| "" | The path to the PEM encoded CA certs file. If the empty string, the default system certs will be used|
|influxdb_subscriber_write_concurrency| 40 | The number of writer goroutines processing the write channel.|
|influxdb_subscriber_write_buffer_size| 1000 | The number of in-flight writes buffered in the write channel.|
|influxdb_graphite_enabled| false | Determines whether the graphite endpoint is enabled.|
|influxdb_graphite_database| graphite| |
|influxdb_graphite_retention_policy| ""| |
|influxdb_graphite_bind_address| ":2003"| |
|influxdb_graphite_protocol| tcp| |
|influxdb_graphite_consistency_level| one| |
|influxdb_graphite_batch_size| 5000 | Flush if this many points get buffered|
|influxdb_graphite_batch_pending| 10 | number of batches that may be pending in memory|
|influxdb_graphite_batch_timeout| 1s | Flush at least this often even if we haven't hit buffer limit|
|influxdb_graphite_tags|  "region=us-east" "zone=1c" | UDP Read buffer size, 0 means OS default. UDP listener will fail if set above OS max.  influxdb_graphite_udp_read_buffer| 0 This string joins multiple matching 'measurement' values providing more control over the final measurement name.  luxdb_graphite_separator| "." Default tags that will be added to all metrics.  These can be overridden at the template level or by tags extracted from metric|
|influxdb_graphite_templates| "*.app env.service.resource.measurement" "server.*" | Each template line requires a template pattern.  It can have an optional filter before the template and separated by spaces.  It can also have optional extra tags following the template.  Multiple tags should be separated by commas and no spaces similar to the line protocol format.  There can be only one default template.|
|influxdb_collectd_enabled| false| |
|influxdb_collectd_bind_address| ":25826"| |
|influxdb_collectd_database| collectd| |
|influxdb_collectd_retention_policy| ""| |
|influxdb_collectd_typesdb| /usr/local/share/collectd| |
|influxdb_collectd_security_level| none| |
|influxdb_collectd_auth_file| /etc/collectd/auth_file| |
|influxdb_collectd_batch_size| 5000 | Flush if this many points get buffered|
|influxdb_collectd_batch_pending| 10 | Number of batches that may be pending in memory|
|influxdb_collectd_batch_timeout| 10s | Flush at least this often even if we haven't hit buffer limit|
|influxdb_collectd_read_buffer| 0 | UDP Read buffer size, 0 means OS default. UDP listener will fail if set above OS max.|
|influxdb_collectd_parse_multivalue_plugin| split | "split" is the default behavior for backward compatibility with previous versions of influxdb.|
|influxdb_opentsdb_enabled| false| |
|influxdb_opentsdb_bind_address| ":4242"| |
|influxdb_opentsdb_database| opentsdb| |
|influxdb_opentsdb_retention_policy| ""| |
|influxdb_opentsdb_consistency_level| one| |
|influxdb_opentsdb_tls_enabled| false| |
|influxdb_opentsdb_certificate| /etc/ssl/influxdb.pem| |
|influxdb_opentsdb_log_point_errors| true| |
|influxdb_opentsdb_batch_size| 1000 | Flush if this many points get buffered|
|influxdb_opentsdb_batch_pending| 5 | Number of batches that may be pending in memory|
|influxdb_opentsdb_batch_timeout| 1s | Flush at least this often even if we haven't hit buffer limit|
|influxdb_udp_enabled| false ||
|influxdb_udp_bind_address| ":8089" ||
|influxdb_udp_database| udp ||
|influxdb_udp_retention_policy| "" ||
|influxdb_udp_precision| "" | InfluxDB precision for timestamps on received points ("" or "n", "u", "ms", "s", "m", "h")|
|influxdb_udp_batch_size| 5000 | Flush if this many points get buffered|
|influxdb_udp_batch_pending| 10 | Number of batches that may be pending in memory|
|influxdb_udp_batch_timeout| 1s | Will flush at least this often even if we haven't hit buffer limit|
|influxdb_udp_read_buffer| 0 | UDP Read buffer size, 0 means OS default. UDP listener will fail if set above OS max.|
|influxdb_continuous_queries_enabled| true | Determines whether the continuous query service is enabled.|
|influxdb_continuous_queries_log_enabled| true | Controls whether queries are logged when executed by the CQ service.|
|influxdb_continuous_queries_query_stats_enabled| false | Controls whether queries are logged to the self-monitoring data store.|
|influxdb_continuous_queries_run_interval| 1s | interval for how often continuous queries will be checked if they need to run |
|influxdb_tls_ciphers | TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305 TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 | Determines the available set of cipher suites. See https://golang.org/pkg/crypto/tls/#pkg-constants for a list of available ciphers, which depends on the version of Go (use the query SHOW DIAGNOSTICS to see the version of Go used to build InfluxDB). If not specified, uses the default settings from Go's crypto/tls package.|
|influxdb_tls_min_version| tls1.2 | Minimum version of the tls protocol that will be negotiated. If not specified, uses the default settings from Go's crypto/tls package.|
|influxdb_tls_max_version| tls1.2 | Maximum version of the tls protocol that will be negotiated. If not specified, uses the default settings from Go's crypto/tls package.|

Dependencies
------------

No external dependencies

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables
passed in as parameters) is always nice for users too:

```yaml
---
- hosts: all
  roles:
  - role: influxdb
```

-----------------------------------------------------------------------------------------------------------------------------------------------------------
