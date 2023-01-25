#! /bin/bash

# Author: Fabrizio Catalucci
# License: MIT.
# Source: https://github.com/fabricat/bash_prometheus_metrics/tree/5669fb4887d4c5152bef6531e52fb0d7d3e223eb

# You need 2 global variables to use this lib
#   - metrics_prefix (string, optional, default: don't use prefix)
#     If present, will be added to all metric names
#     Example: metrics_prefix="my_exporter_prefix"
#
#   - metrics_array (array, optional, default: empty array)
#     Added metrics will be appended to this initial array
#     Example: metrics_array=("my_metric1 1.31" "my_metric2 90.0")

# exporter_add_metric example:
#   exporter_add_metric remote_fetched gauge "Number of remote backups successfully fetched via scp" 1.0 "remote_host:$remote_host;"
#
# exporter_add_metric input options:
#   - $1
#     Metric name, string
#     Example "some_metric_name"
#
#   - $2
#     Metric type, "gauge" or "counter"
#     Example "gauge"
#
#   - $3
#     Metric description, string
#     Example "Number of numbers of something"
#
#   - $4
#     Metric value, int or float
#     Example "1.488"
#
#   - $5 (optional)
#     Metric labels struct, string pairs with ":" separator within pair and ";" separator between pairs
#     Example "label_one_name:label_one_value;label_two_name:label_two_value"
#     Important: you cannot use any whitespace in label keys nor values!
#
#   - $6 (optional)
#     Additional metric value, identical to $4
#			Important: if provided, must be followed by labels struct parameter (see $7)
#
#   - $7 (optional)
#     Additional labels struct, identical to $5
#
#   Note: $6 and $7 can be repeated several times, with different labels.
#
function exporter_add_metric() {
	if [ -z "${metrics_array+x}" ]; then
	  metrics_array=()
	fi
	if [ -z "${metrics_prefix}" ]; then 
		local metric_name="${1}"
	else
		local metric_name="${metrics_prefix}_${1}"
	fi
	local metric_type=$2
	local metric_description=$3
	
	if [ -n "$metric_description" ]; then
		metrics_array+=("# HELP $metric_name $metric_description")
	fi
	# silently skip unrecognized $metric_type
	if [ "$metric_type" == "gauge" -o "$metric_type" == "counter" ]; then
		metrics_array+=("# TYPE $metric_name $metric_type")
	fi
	shift 3
	while (( "$#" )); do
		local metric_labels=()
		local metric_value=$1
		shift
		if (( "$#" )); then
			local metric_labels_struct=$1
			shift
			for label_string in ${metric_labels_struct//;/ }
			do
				local label_key="${label_string/:*/}"
				local label_value="${label_string/*:/}"
				local label_line="${label_key}=\"${label_value}\""
				metric_labels+=($label_line)
			done
			local metric_labels_raw_line="${metric_labels[@]}"
			local metric_labels_line="${metric_labels_raw_line// /,}"
			metrics_array+=("$metric_name{$metric_labels_line} $metric_value")
		else
			metrics_array+=("$metric_name $metric_value")
		fi
	done
}

function exporter_show_metrics() {
	printf "%s\n" "${metrics_array[@]}"
}
