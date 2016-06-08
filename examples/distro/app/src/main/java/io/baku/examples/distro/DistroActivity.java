// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.baku.examples.distro;

import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v4.app.FragmentActivity;
import android.util.Log;
import android.widget.Toast;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;

import org.chromium.base.PathUtils;
import org.joda.time.Duration;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterView;
import io.v.android.VAndroidContext;
import io.v.android.VAndroidContexts;
import io.v.android.security.BlessingsManager;
import io.v.v23.security.Blessings;
import io.v.v23.verror.VException;
import io.v.v23.vom.VomUtil;
import java8.util.Maps;
import rx.Subscription;

/**
 * Activity representing the example 'app', a.k.a. the initiator/originator/master.
 */
public class DistroActivity extends FragmentActivity implements GoogleApiClient.OnConnectionFailedListener {
    private static final String TAG = DistroActivity.class.getSimpleName();
    private static final Duration PING_TIMEOUT = Duration.standardSeconds(2);
    private static final long POLL_INTERVAL = 750;

    private VAndroidContext context;
    private FlutterView flutterView;
    private final Map<String, ConnectionMonitor> clients = new HashMap<>();
    private ScheduledExecutorService poller;
    private Subscription subscription;

    @Override
    public void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        FlutterMain.ensureInitializationComplete(getApplicationContext(), null);
        setContentView(R.layout.flutter_layout);

        flutterView = (FlutterView) findViewById(R.id.flutter_view);
        File appBundle = new File(PathUtils.getDataDirectory(this),
                FlutterMain.APP_BUNDLE);
        flutterView.runFromBundle(appBundle.getPath(), null);

        poller = new ScheduledThreadPoolExecutor(1);

        context = VAndroidContexts.withDefaults(this, savedInstanceState);

        Futures.addCallback(BlessingsManager
                        .getBlessings(context.getVContext(), this, "blessings", true),
                new FutureCallback<Blessings>() {
                    @Override
                    public void onSuccess(final Blessings blessings) {
                        onBlessingsAvailable(blessings);
                    }

                    @Override
                    public void onFailure(final Throwable t) {
                        Log.e(TAG, "Unable to attain blessings", t);
                    }
                });
    }

    @Override
    public void onConnectionFailed(final @NonNull ConnectionResult connectionResult) {
        Toast.makeText(this, connectionResult.getErrorMessage(), Toast.LENGTH_LONG).show();
    }

    private void onBlessingsAvailable(final Blessings blessings) {
        final Intent castIntent = new Intent(DistroActivity.this,
                DistroAndroidService.class);
        try {
            castIntent.putExtra(DistroAndroidService.BLESSINGS_EXTRA,
                    VomUtil.encodeToString(blessings, Blessings.class));
        } catch (final VException e) {
            Log.e(TAG, "Unable to encode blessings", e);
        }
        startService(castIntent);

        subscription = startScanning();
    }

    @Override
    protected void onDestroy() {
        if (subscription != null) {
            subscription.unsubscribe();
        }

        poller.shutdown();
        clients.clear();

        if (flutterView != null) {
            flutterView.destroy();
        }

        context.close();

        super.onDestroy();
    }

    @Override
    protected void onPause() {
        super.onPause();
        flutterView.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        flutterView.onResume();
    }

    @Override
    protected void onNewIntent(Intent intent) {
        // Reload the Flutter Dart code when the activity receives an intent
        // from the "flutter refresh" command.
        // This feature should only be enabled during development.  Use the
        // debuggable flag as an indicator that we are in development mode.
        if ((getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            if (Intent.ACTION_RUN.equals(intent.getAction())) {
                flutterView.runFromBundle(intent.getDataString(),
                        intent.getStringExtra("snapshot"));
            }
        }
    }

    private boolean isActive() {
        return subscription != null && !subscription.isUnsubscribed();
    }

    private class ConnectionMonitor implements FutureCallback<String> {
        final String name;
        final DistroClient client;

        private ListenableFuture<String> poll;

        public ConnectionMonitor(final String name) {
            this.name = name;
            client = DistroClientFactory.getDistroClient(name);

            poll();
        }

        public void poll() {
            poll = client.getDescription(context.getVContext().withTimeout(PING_TIMEOUT));
            Futures.addCallback(poll, this);
        }

        @Override
        public void onSuccess(final String description) {
            if (isActive()) {
                final JSONObject message = new JSONObject();
                try {
                    message.put("name", name);
                    message.put("description", description);
                } catch (final JSONException wtf) {
                    throw new RuntimeException(wtf);
                }
                flutterView.sendToFlutter("deviceOnline", message.toString());

                poller.schedule(this::poll, POLL_INTERVAL, TimeUnit.MILLISECONDS);
            }
        }

        @Override
        public void onFailure(final Throwable t) {
            if (isActive()) {
                flutterView.sendToFlutter("deviceOffline", name);

                clients.remove(name);
            }
        }
    }

    private Subscription startScanning() {
        return Disco.scanContinuously(context)
                .subscribe(name -> Maps.computeIfAbsent(clients, name, ConnectionMonitor::new),
                        t -> context.getErrorReporter().onError(R.string.err_scan, t));
    }
}
