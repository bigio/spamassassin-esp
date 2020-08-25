#!/bin/sh

# <@LICENSE>
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# </@LICENSE>

# Author:  Giovanni Bechis <gbechis@apache.org>

do_help=0
do_reload=0
while getopts "ho:r" opt; do
    case $opt in
        h) do_help=1 ;;
        o) output=$OPTARG ;;
	r) do_reload=1 ;;
        *) do_help=1
           exit 1
    esac
done

if [ "$output" = "" ]; then
  do_help=1
fi

if [ "$do_help" -eq 1 ]; then
    echo "usage: $0 -o outputfile"
    exit
fi

MD5OLD=$(md5sum $output 2>&1)
if [ ! -f $output ]; then
  curl -s -S https://www.invaluement.com/spdata/sendgrid-id-dnsbl.txt -o $output
else
  curl -s -S -z $output https://www.invaluement.com/spdata/sendgrid-id-dnsbl.txt -o $output
fi
MD5NEW=$(md5sum $output 2>&1)

if [ "$do_reload" -eq 1 ]; then
  if [ "$MD5OLD" != "$MD5NEW" ]; then
    pkill -HUP spamd
  fi
fi
