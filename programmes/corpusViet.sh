#!/usr/bin/env bash

ENTREETEXTES="../dumps-text/langViet_*.txt"
SORTIECORPUS="../pals/corpus_Viet.txt"

iconv -f UTF-8 -t UTF-8 -c $ENTREETEXTES > $SORTIECORPUS
