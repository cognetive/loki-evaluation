"""
This simple script builds a url of thanos webpage for specific graphs. It saves up time creating them manually.
"""
import urllib.parse
import subprocess

groups = [
    {
        "range_input": "3h",
        "end_time": "2021-08-24 08:55:00",
        "expr_list": [
            # Memory & CPU for the write path
            # ingesters
            "container_memory_working_set_bytes{pod=~'loki-loki-distributed-ingester-.*',namespace='loki',container='',}",
            "rate(container_cpu_usage_seconds_total{pod=~'loki-loki-distributed-ingester-.*',namespace='loki',container='',}[1m])",

            # distributors
            "container_memory_working_set_bytes{pod=~'loki-loki-distributed-distributor-.*',namespace='loki',container='',}",
            "rate(container_cpu_usage_seconds_total{pod=~'loki-loki-distributed-distributor-.*',namespace='loki',container='',}[1m])",

            # uploaders
            "container_memory_working_set_bytes{pod=~'uploadtoloki.2019-12-01.*',namespace='loki',container='',}",
            "rate(container_cpu_usage_seconds_total{pod=~'uploadtoloki.2019-12-01.*',namespace='loki',container='',}[1m])",

            # Loki metrics
            "loki_distributor_bytes_received_total",
            "loki_distributor_lines_received_total",

            "loki_ingester_chunks_created_total{job='loki-loki-distributed-ingester'}",

            "loki_ingester_chunk_stored_bytes_total{job='loki-loki-distributed-ingester'}",
            "loki_ingester_chunk_size_bytes_sum{job='loki-loki-distributed-ingester'}",

            "loki_ingester_chunk_entries_sum{job='loki-loki-distributed-ingester'}",
            "loki_ingester_samples_per_chunk_sum{job='loki-loki-distributed-ingester'}",

            "loki_ingester_memory_chunks{job='loki-loki-distributed-ingester'}",
        ],
    },
    {
        "range_input": "1h",
        "end_time": "2021-08-24 12:00:00",
        "expr_list": [
            # Memory & CPU for the read path
            # queriers
            "container_memory_working_set_bytes{pod=~'loki-loki-distributed-querier-.',namespace='loki',container='',}",
            "rate(container_cpu_usage_seconds_total{pod=~'loki-loki-distributed-querier-.*',namespace='loki',container='',}[1m])",

            # query-fronteds
            "container_memory_working_set_bytes{pod=~'loki-loki-distributed-query-frontend-.*',namespace='loki',container='',}",
            "rate(container_cpu_usage_seconds_total{pod=~'loki-loki-distributed-query-frontend-.*',namespace='loki',container='',}[1m])",

            # downloaders
            "container_memory_working_set_bytes{pod=~'downloadfromloki.2019-12-01.*',namespace='loki',container='',}",
            "rate(container_cpu_usage_seconds_total{pod=~'downloadfromloki.2019-12-01.*',namespace='loki',container='',}[1m])",
        ],
    },
]

cmd = 'oc get routes -n openshift-monitoring thanos-querier -o jsonpath="{.spec.host}"'
thanos_querier_route = subprocess.check_output(cmd, shell=True).decode("utf-8")
base_url = f"https://{thanos_querier_route}/new/graph?"


def main():
    kv_dict = {}
    i = 0

    for g in groups:
        for expr in g["expr_list"]:
            kv_dict[f"g{i}.expr"] = expr
            kv_dict[f"g{i}.range_input"] = g["range_input"]
            kv_dict[f"g{i}.tab"] = "0"
            kv_dict[f"g{i}.stacked"] = "1"
            kv_dict[f"g{i}.max_source_resolution"] = "0s"
            kv_dict[f"g{i}.deduplicate"] = "1"
            kv_dict[f"g{i}.partial_response"] = "0"
            kv_dict[f"g{i}.store_matches"] = ""
            kv_dict[f"g{i}.end_input"] = g["end_time"]
            kv_dict[f"g{i}.moment_input"] = g["end_time"]
            i += 1

    params = "&".join(f"{k}={urllib.parse.quote(v)}" for k, v in kv_dict.items())
    final_url = f"{base_url}{params}"
    print(final_url)


if __name__ == '__main__':
    main()
