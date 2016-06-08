// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package io.baku.examples.distro;

import android.content.Context;
import android.util.Log;

import org.joda.time.Duration;

import java.util.concurrent.TimeUnit;

import io.v.android.VAndroidContext;
import io.v.android.v23.V;
import io.v.v23.naming.MountEntry;
import lombok.experimental.UtilityClass;
import rx.Observable;

@UtilityClass
public class Disco {
    private static final String TAG = Disco.class.getSimpleName();
    private static final Duration GLOB_TIMEOUT = Duration.standardSeconds(2);
    private static final long SCAN_PERIOD = 750;

    public static String name(final Context context) {
        return "tmp/baku-disco/" + DeviceId.get(context);
    }

    public static Observable<String> scanOnce(final VAndroidContext<?> context) {
        return RxInputChannel.wrap(V.getNamespace(context.getVContext())
                .glob(context.getVContext().withTimeout(GLOB_TIMEOUT), "tmp/baku-disco/*"))
                .refCount()
                .flatMap(g -> {
                    if (g.getElem() instanceof MountEntry) {
                        return Observable.just(((MountEntry)g.getElem()).getName());
                    } else {
                        Log.e(TAG, "Unsupported glob response " + g);
                        return Observable.empty();
                    }
                })
                .filter(n -> !name(context.getAndroidContext()).equals(n));
    }

    public static Observable<String> scanContinuously(final VAndroidContext<?> context) {
        return Observable.interval(SCAN_PERIOD, TimeUnit.MILLISECONDS)
                .switchMap(x -> scanOnce(context).onErrorResumeNext(t -> {
                    Log.e(TAG, t.getMessage(), t);
                    return Observable.empty();
                }));
    }
}
