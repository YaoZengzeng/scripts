#!/bin/sh

# traffic shifting
for i in {1..100}; do curl -s http://10.0.2.15:32721/api/catalog \
	-H "Host: webapp.istioinaction.io"  \
	| grep -i imageUrl; done | wc -l
