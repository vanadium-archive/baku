// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package io.baku.examples.distro;

import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.MoreExecutors;

import io.v.v23.context.VContext;

public class Connection {
    private final DistroClient client;

    public Connection(final String name) {
        client = DistroClientFactory.getDistroClient(name);
    }

    private ListenableFuture<String> opInProgress;

    public ListenableFuture<String> pollDescription(final VContext vContext) {
        if (opInProgress == null) {
            opInProgress = client.getDescription(vContext);
            opInProgress.addListener(() -> opInProgress = null, MoreExecutors.directExecutor());
            return opInProgress;
        } else {
            return null;
        }
    }
}