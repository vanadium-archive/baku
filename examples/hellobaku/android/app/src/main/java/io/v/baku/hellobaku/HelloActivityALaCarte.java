// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package io.v.baku.hellobaku;

import android.app.Activity;
import android.os.Bundle;

import io.v.baku.toolkit.VAndroidContextMixin;
import io.v.baku.toolkit.VAndroidContextTrait;
import io.v.baku.toolkit.bind.SyncbaseBinding;
import io.v.rx.syncbase.GlobalUserSyncgroup;
import io.v.rx.syncbase.RxDb;
import io.v.rx.syncbase.RxSyncbase;
import rx.Subscription;

public class HelloActivityALaCarte extends Activity {
    private RxSyncbase mSb;
    private Subscription mActivityDataBindings;

    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_hello);

        final VAndroidContextTrait<HelloActivityALaCarte> vActivity =
                VAndroidContextMixin.withDefaults(this, savedInstanceState);

        mSb = new RxSyncbase(vActivity);
        final RxDb db = mSb.rxApp("app").rxDb("db");

        // We want these data bindings to share the lifecycle of the Activity from onCreate to
        // onDestroy, so keep track of their CompositeSubscription and unsubscribe in onDestroy.
        mActivityDataBindings = SyncbaseBinding.builder()
                .activity(vActivity)
                .rxTable(db.rxTable("t"))

                .key("text")
                .bindTo(R.id.textView)
                .bindTo(R.id.editText)

                .getSubscription();

        GlobalUserSyncgroup.builder()
                .activity(vActivity)
                .syncbase(mSb).db(db)
                .prefix("t")
                .sgSuffix("myGlobalUserSyncgroup")
                .build()
                .join();
    }

    @Override
    protected void onDestroy() {
        mActivityDataBindings.unsubscribe();
        mSb.close();
        super.onDestroy();
    }
}
