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

<p><img src="https://www.circonus.com/wp-content/uploads/2015/03/sol-icon-itOps.png" alt="graph logo" title="graph" align="right" height="60" /></p>

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

<p><img src="https://grafana.com/blog/assets/img/blog/timeshift/grafana_release_icon.png" alt="grafana logo" title="grafana" align="right" height="60" /></p>

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
