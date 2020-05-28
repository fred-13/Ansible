#!/bin/bash

for node_name in node_exporter_1 node_exporter_2;
  do
	virsh snapshot-revert --domain ${node_name} --snapshotname $(virsh snapshot-list --domain ${node_name} --name) --running;
	echo "Revert and started ${node_name}";
  done
