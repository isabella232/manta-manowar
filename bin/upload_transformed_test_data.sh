#!/usr/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright (c) 2014, Joyent, Inc.
#

###############################################################################
# This script will transform and upload test data.
#
# Before running, make sure you've initialized your environment to run
# m* commands (mls, mmkdir, etc).
###############################################################################

: ${MANTA_URL?"MANTA_URL isn't set"}

TMP_FILE=/tmp/manowar_test_data

for file in `find data/logs -type f`; do
    ROOT_DIR=/$MANTA_USER/stor/graphs
    DIR=$ROOT_DIR/data/$(dirname $file | perl -ne 's/data\/logs\///g; print;')
    MANTA_OBJECT=$DIR/60.data
    echo $MANTA_OBJECT

    zcat $file | bunyan --strict -o json-0 -c 'this.audit === true' | \
        ./bin/stream-metrics.js -p 60 -t time -f latency \
            -f statusCode:latency \
        >$TMP_FILE

    #.../graphs shouldn't have CORS headers since it will contain
    # more than just graph data.
    mmkdir $ROOT_DIR

    #Everything else should have the CORS headers.
    mmkdir -H 'Access-Control-Allow-Origin: *' -p $DIR
    mput -H 'Access-Control-Allow-Origin: *' -f $TMP_FILE $MANTA_OBJECT
done

rm -rf $TMP_FILE
