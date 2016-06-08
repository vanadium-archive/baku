// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package io.baku.examples.distro;

import android.app.Service;
import android.content.ContentResolver;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.IBinder;
import android.provider.ContactsContract;
import android.support.annotation.Nullable;
import android.util.Log;

import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.SettableFuture;
import com.jaredrummler.android.device.DeviceName;

import io.v.android.v23.V;
import io.v.v23.context.VContext;
import io.v.v23.rpc.Server;
import io.v.v23.rpc.ServerCall;
import io.v.v23.security.BlessingPattern;
import io.v.v23.security.Blessings;
import io.v.v23.security.VPrincipal;
import io.v.v23.security.VSecurity;
import io.v.v23.vdl.ServerRecvStream;
import io.v.v23.verror.VException;
import io.v.v23.vom.VomUtil;

public class DistroAndroidService extends Service {
    private static final String TAG = DistroAndroidService.class.getSimpleName();

    public static final String
            BLESSINGS_EXTRA = "Blessings";

    private VContext vContext;

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        vContext = V.init(this);

        final VPrincipal principal = V.getPrincipal(vContext);

        final Blessings blessings;
        try {
            blessings = (Blessings) VomUtil.decodeFromString(
                    intent.getStringExtra(BLESSINGS_EXTRA), Blessings.class);

            principal.blessingStore().setDefaultBlessings(blessings);
            principal.blessingStore().set(blessings, new BlessingPattern("..."));
            VSecurity.addToRoots(principal, blessings);
        } catch (final VException e) {
            // TODO(rosswang): handle this better
            Log.e(TAG, "Unable to assume blessings", e);
        }

        final DistroServer handlers = new DistroServer() {
            @Override
            public ListenableFuture<String> getDescription(final VContext context,
                                                           final ServerCall call) {
                final SettableFuture<String> description = SettableFuture.create();

                DeviceName.with(DistroAndroidService.this).request((i, e) -> {
                    final String owner;

                    final ContentResolver cr = getContentResolver();
                    try (final Cursor c = cr.query(Uri.withAppendedPath(
                            ContactsContract.Profile.CONTENT_URI,
                            ContactsContract.Contacts.Data.CONTENT_DIRECTORY),
                            null, null, null, null)) {

                        if (c.getCount() > 0) {
                            c.moveToFirst();
                            owner = c.getString(c.getColumnIndex(
                                    ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME)) +
                                    "'s ";
                        } else {
                            owner = "";
                        }
                    }

                    final String device = e == null ? i.getName() : DeviceName.getDeviceName();
                    description.set(owner + device);
                });

                return description;
            }

            @Override
            public ListenableFuture<Void> cast(final VContext context, final ServerCall call,
                                               final ServerRecvStream<State> stream) {
                Log.i(TAG, "BAD WOLF");
                return null;
            }
        };

        VContext listenContextCandidate;
        try {
            listenContextCandidate = V.withListenSpec(vContext,
                    V.getListenSpec(vContext).withProxy("proxy"));
        } catch (final VException e) {
            listenContextCandidate = vContext;
            Log.e(TAG, "Unable to listen on proxy", e);
        }

        final VContext listenContext = listenContextCandidate;

        final Server s;
        try {
            s = V.getServer(V.withNewServer(listenContext, Disco.name(this), handlers,
                    VSecurity.newAllowEveryoneAuthorizer()));
        } catch (final VException e) {
            throw new RuntimeException(e);
        }

        return START_REDELIVER_INTENT;
    }

    @Override
    public void onDestroy() {
        vContext.cancel();
    }
}
